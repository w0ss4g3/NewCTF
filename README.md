# NewCTF
Enhanced CTF Gamemode for UnrealTournament. It adds the following features compared to the default CTF gamemode:

* Custom spawn system
* Announcer for flag events (Taken/Dropped/Returned/Captured), plus a few other events
* Advantage system to allow flags in play at the end of a match to be resolved, within a limited amount of time
* Option to not play overtime and instead have draws
* Option to increase respawn delay during overtime, to force the game to end
* Option to remove the light-glow around flag-carriers
* Adjustable flag timeout when dropped

## Installation

1. Copy NewCTF_v17.u and NewCTFInterface.u into System folder
2. Set Gamemode to NewCTF_v17.NewCTF (replacing Botpack.CTFGame)

## Client Settings

The settings for clients/players can be found in NewCTF.ini in your System folder, the contents of which will be similar to this:
```ini
[ClientSettings]
AnnouncerVolume=1.5
CTFAnnouncerClass=NewCTF_v17.DefaultAnnouncer
Debug=False
_Version=1
```

### AnnouncerVolume
Controls the volume of announcements. Valid settings range from `0.0` to `6.0`.

### CTFAnnouncerClass
Which announcements to use. NewCTF comes with two announcers: NewCTF_v17.DefaultAnnouncer and NewCTF_v17.NewCTFAnnouncer.

Announcers can have custom sounds for the following CTF events:
* FlagDropped - When a flag was dropped by a player
* FlagReturned - When a player returned a flag
* FlagTaken - When a player took a flag off its FlagBase
* FlagScored - When a player captured the enemy flag
* GotFlag - When you picked up the flag yourself
* Overtime - When the game goes into Overtime
* Advantage - When the game goes into Advantage
* Draw - When the game finishes as a draw

Note that all announcements play in addition to the games internal sounds

#### NewCTF_v17.DefaultAnnouncer
Only provides custom sounds for Overtime, Advantage, and Draw, which would not have sounds otherwise.

#### NewCTF_v17.NewCTFAnnouncer
Provides sounds for all events.

#### Interface
If you want to create your own Announcer package for NewCTF, create a new package containing a class that extends `INewCTFAnnouncer` from the [NewCTFInterface](https://github.com/Deaod/NewCTFInterface) package. Then set `CTFAnnouncerClass` to the name of your new package followed by a dot, followed by the name of the class.

### Debug
Setting this to true causes NewCTF to log all incoming announcement notifications.

### \_Version
This is an version number for your settings, used to automatically upgrade your settings with new versions of NewCTF.

## Server Settings
The settings for servers can be found in UnrealTournament.ini in your System folder, the contents of which will be similar to this:

```ini
[NewCTF_v17.NewCTF]
SpawnSystemThreshold=4
SpawnEnemyBlockRange=650.0
SpawnEnemyVisionBlockRange=2000.0
SpawnFriendlyBlockRange=150.0
SpawnFriendlyVisionBlockRange=150.0
SpawnFlagBlockRange=750.0
SpawnMinCycleDistance=1
bSpawnExtrapolateMovement=True
bSpawnSecondaryEnabled=True
SpawnSecondaryMaxDistance=2000.0
SpawnSecondaryOwnTeamWeight=0.2
SpawnSecondaryCarrierWeight=2.0
bAllowOvertime=False
RespawnDelay=1.0
OvertimeRespawnDelay=1.0
OvertimeRespawnDelayCoefficient=120.0
OvertimeRespawnDelayStartTime=300
AdvantageDuration=120
AdvantageMaxScoreDiff=-1
MercyScore=0
bFlagGlow=True
FlagTimeout=25.0
FlagAdvantageTimeout=25.0
FlagOvertimeTimeout=25.0
```

### Spawn*
These settings will be explained in the [Spawn System](#spawn-system) section.

### bAllowOvertime
Whether to allow a match to go into overtime, or to end the game in a draw.  
Can also be set through the URL using `?bAllowOvertime=(true/false)`.  
See also [Interaction with Overtime](#interaction-with-overtime).

### RespawnDelay
This is the default delay after death for player before they can respawn. Applies throughout the game until [OvertimeRespawnDelayStartTime](#overtimerespawndelaystarttime) has been reached.

### OvertimeRespawnDelay
After [OvertimeRespawnDelayStartTime](#overtimerespawndelaystarttime) seconds of overtime respawning is delayed by this many seconds (at least 1 second).

### OvertimeRespawnDelayCoefficient
Only applies if greater than `0.0`.  
Every this many seconds of overtime past [OvertimeRespawnDelayStartTime](#overtimerespawndelaystarttime) respawning is delayed by one additional second.

### OvertimeRespawnDelayStartTime
After this many seconds of overtime, respawning could be delayed by more than normal, depending on [OvertimeRespawnDelay](#overtimerespawndelay) and [OvertimeRespawnDelayCoefficient](#overtimerespawndelaycoefficient).

### AdvantageDuration
How much time (in seconds) to add on top of the regular time to allow flags in play at the end to be resolved. Note that due to implementation details AdvantageDuration can not be set to 60 seconds. NewCTF will write a warning about this to the log and set AdvantageDuration to 59 automatically.  
Can also be set through the URL using `?AdvantageDuration=X`.  
See section [Advantage](#advantage).

### AdvantageMaxScoreDiff
This is intended to allow limiting when advantage can happen by looking at the difference in score between the two teams and not going to advantage when the difference is greater than the value of this setting.

Negative values for this setting disable it, so advantage can always kick in.

### MercyScore
If MercyScore is greater than 0, and one team is at least one more than
MercyScore ahead of their closest opponent, the game ends immediately.  
Can also be set through the URL using `?MercyScore=X`.

### bFlagGlow
Controls whether flags glow when being carried by players.  
Can also be set through the URL using `bFlagGlow=(True/False)`.

### FlagTimeout
Controls how long a flag stays on the ground before being returned automatically. This variable controls the Timeout during normal play.

### FlagTimeoutAdvantage
Controls how long a flag stays on the ground before being returned automatically during advantage.

### FlagTimeoutOvertime
Controls how long a flag stays on the ground before being returned automatically during overtime.

## Spawn System

NewCTF comes with a new spawn system, replacing the default one. For the purposes of this document, spawn point and PlayerStart refer to the same thing.

If the number of players on the server is less than or equal to `SpawnSystemThreshold`, the default spawn algorithm of UT99 is used.

NewCTF has a list of spawn points for each team, which is created at the start of each map and shuffled once.

NewCTF has two spawn systems called primary system and secondary system. The primary system tries to find a high-quality spawn point. If the primary system does not find a suitable spawn point, the secondary system is used, which will result in spawns that violate one or more of the rules of the primary system.

Every time a player tries to respawn during the game, the primary spawn system goes through the list of that player's team and tries to find a spawn point that can be *used* given the following restrictions:

1. No enemy is within `SpawnEnemyBlockRange` of the spawn point,
2. No enemy is within `SpawnEnemyVisionBlockRange` and has vision of the spawn point (tracing EyeHeight of player to Location of spawn point),
3. No teammate is within `SpawnFriendlyBlockRange` of the spawn point,
4. No teammate is within `SpawnFriendlyVisionBlockRange` and has vision of the spawn point,
5. No flag is within `SpawnFlagBlockRange` of the spawn point and
6. At least `SpawnMinCycleDistance` other spawn points have been used since the last time this one was used

If no suitable spawn point can be found, the system falls back to the secondary system.

The secondary system finds the spawn point thats furthest away from all players. It does this by adding up the distance of every player for each spawn point. The spawn point with the highest sum is then used to spawn. For certain classes of players, the distance can be modified using the following settings:

1. `SpawnSecondaryOwnTeamWeight` (members of the same team)
2. `SpawnSecondaryCarrierWeight` (enemy flag carriers)

Keep in mind that if you want to prioritize spawning next to a certain class of players, you want to decrease the weight compared to the default for enemies, which is `1.0`.

The spawn point selected by one of the two systems is moved to the end of the list.

### Settings

#### SpawnSystemThreshold
Specifies the maximum number of players on a map that will not use the new spawn system. Set to 0 to always use it, or to a very high value to never use it.

#### SpawnEnemyBlockRange
Specifies the range within which an enemy will block a spawn from being used, no matter the visibility.

#### SpawnEnemyVisionBlockRange
Specifies the range within which an enemy with vision of the spawn point will block it from being used.

#### SpawnFriendlyBlockRange
Specifies the range within which a teammate will block a spawn from being used, regardless of visibility.

#### SpawnFriendlyVisionBlockRange
Specifies the range within which a teammate with vision of the spawn point will block it from being used.

#### SpawnFlagBlockRange
Specifies the range within which a Flag will block a spawn from being used, regardless of visibility.

#### SpawnMinCycleDistance
Specifies the number of other spawn points that have to have been used before a given spawn point can be used again. Setting it to 0 disables this restriction.

#### bSpawnExtrapolateMovement
If enabled, use extrapolated position of remote player for range checks of spawn points.

#### bSpawnSecondaryEnabled
If enabled, use secondary algorithm to find a suitable spawn point if primary algorithm cant find one. If disabled, skip using secondary algorithm and fall back to default algorithm.

#### SpawnSecondaryMaxDistance
Players at or above this distance from a spawn point all contribute the same amount to its weight for the secondary algorithm.

#### SpawnSecondaryOwnTeamWeight
Multiplier of the distance of members of the same team to spawn points.

#### SpawnSecondaryCarrierWeight
Multiplier of the distance of flag carriers to spawn points.

#### bEnableModifiedFlagDrop
If enabled, replaces the default flag drop behaviour. When a flag is dropped by a player, it will move in the player's last velocity direction at a maximum speed of FlagDropMaximumSpeed.

#### FlagDropMaximumSpeed
Limits the maximum speed of a flag to this value when it is dropped. Only applies if bEnableModifiedFlagDrop is enabled.

### Interface
NewCTFInterface contains an add-on for map makers that allows them to provide alternate spawn system settings for a single map.

For this purpose NewCTFInterface contains two placeable actors, `SpawnControlInfo` and `SpawnControlPlayerStart`.

In order to use it, place the file NewCTFInterface.u in your System folder and add `EditPackages=NewCTFInterface` to section `[Editor.EditorEngine]` in UnrealTournament.ini.

#### SpawnControlInfo
Can be placed anywhere on the map, is invisible and contains alternate settings for the entire map.

#### SpawnControlPlayerStart
This is a replacement for the default PlayerStart. It behaves like it in every way, but provides a way to override Range settings of the spawn system for a single spawn point.

### Visualization
NewCTF places a player dummy on each spawn point until the match starts. Its texture indicates whether the spawn point would be used by the primary algorithm.

* Green: Spawn point ready to spawn a player
* Red: Spawn point blocked by enemy player
* Blue: Spawn point blocked by friendly player
* Gold: Spawn point blocked by flag
* Grey: Spawn point used too recently

## Advantage
NewCTF introduces an advantage system which delays the end of a match if at least one flag is not on its FlagBase at the end of the regular time. Advantage will end once all flags are on their FlagBases, either by being returned or by being captured, or alternatively it will end when the additional time granted by the [AdvantageDuration](#advantageduration) setting runs out.

### Interaction with Overtime
Advantage applies even if overtime is allowed.  
The game might first go into Advantage, then into Overtime if the resolution of Advantage resulted in a drawn game.

## Building
1. Open a command line window, go to your UnrealTournament installation folder and clone this repository using `git clone https://github.com/Deaod/NewCTF.git`
2. Use build.bat to build a new NewCTF.u, which will also be copied to the System folder of this repository
