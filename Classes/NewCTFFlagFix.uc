class NewCTFFlagFix extends Info;

var CTFReplicationInfo GRI;

simulated event Tick(float Delta) {
    if (Level.Game.GameReplicationInfo == none)
        return;

    GRI = CTFReplicationInfo(Level.Game.GameReplicationInfo);
    if (Role == ROLE_Authority)
        GotoState('ServerAction');
    else
        GotoState('ClientAction');
}

state ClientAction {
    simulated event Tick(float Delta) {
        local int i;
        local CTFFlag F;
        local EPhysics Phys;

        for (i = 0; i < arraycount(GRI.FlagList); i++) {
            F = GRI.FlagList[i];
            if (F != none) {
                Phys = F.Physics;
                if (Phys == PHYS_None || Phys == PHYS_Falling) {
                    F.SetBase(none);
                }
            }
        }
    }
}

state ServerAction {
    function BeginState() {
        Disable('Tick');
    }
}

defaultproperties {
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=True
}
