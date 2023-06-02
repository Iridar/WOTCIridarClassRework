class X2Effect_ReserveOverwatchPoints_NoCost extends X2Effect_ReserveOverwatchPoints;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;
	local int i, Points;

	TargetUnitState = XComGameState_Unit(kNewTargetState);
	if( TargetUnitState != none )
	{
		Points = GetNumPoints(TargetUnitState);

		for (i = 0; i < Points; ++i)
		{
			TargetUnitState.ReserveActionPoints.AddItem(GetReserveType(ApplyEffectParameters, NewGameState));
		}
		//TargetUnitState.ActionPoints.Length = 0;
	}
}