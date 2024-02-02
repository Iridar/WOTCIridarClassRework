class X2Action_SnapTurn extends X2Action;

var transient vector m_vFacePoint; // Not a direction, its a location
var transient bool	SyncZ;

var private transient vector SyncLocation;
var private transient vector m_vFaceDir; // a Direction, computed at execution time

var private transient XGUnit SyncUnit;
var private transient XComUnitPawn SyncPawn;
var private transient XComGameStateContext_Ability AbilityContext;


simulated state Executing
{
Begin:
	if (SyncZ) `AMLOG("X2Action_SnapTurn Running");
	Unit = XGUnit(Metadata.VisualizeActor);
	if (Unit != none)
	{
		UnitPawn = Unit.GetPawn();
		if (UnitPawn != none)
		{
			m_vFaceDir = m_vFacePoint - UnitPawn.Location;
			m_vFaceDir.Z = 0;
			m_vFaceDir = normal(m_vFaceDir);

			UnitPawn.SetRotation(Rotator(m_vFaceDir));
			UnitPawn.TargetLoc = m_vFacePoint;

			if (SyncZ) `AMLOG("Setting rotation");

			if (SyncZ)
			{
				AbilityContext = XComGameStateContext_Ability(StateChangeContext);
				if (AbilityContext != none)
				{
					`AMLOG("Got context");
					SyncUnit = XGUnit(`XCOMHISTORY.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID));
					if (SyncUnit != none)
					{
						`AMLOG("Got sync unit");
						SyncPawn = SyncUnit.GetPawn();
						if (SyncPawn != none)
						{
							`AMLOG("Got sync pawn, setting location from:" @ UnitPawn.Location.Z @ "to:" @ SyncPawn.Location.Z);
							SyncLocation = UnitPawn.Location;
							SyncLocation.Z = SyncPawn.Location.Z;
							//UnitPawn.SetLocation(SyncLocation);
							UnitPawn.SetLocationNoCollisionCheck(SyncLocation);
						}
					}
				}
			}
		}
	}
	CompleteAction();
}
