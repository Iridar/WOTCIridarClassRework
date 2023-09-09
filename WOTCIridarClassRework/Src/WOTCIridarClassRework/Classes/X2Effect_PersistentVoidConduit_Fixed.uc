class X2Effect_PersistentVoidConduit_Fixed extends X2Effect_PersistentVoidConduit;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local TTile TileLocation;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none || TargetUnit.IsDead())
		return;

	TileLocation = TargetUnit.TileLocation;

	TileLocation.Z += 4;

	TargetUnit.SetVisibilityLocation(TileLocation);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit TargetUnit;
	local TTile TileLocation;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if (TargetUnit != none)
		{
			TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
		}
	}
	if (TargetUnit == none)
		return;

	TileLocation = TargetUnit.TileLocation;
	if (!`XWORLD.IsFloorTile(TileLocation))
	{
		TileLocation.Z -= 4;
		TargetUnit.SetVisibilityLocation(TileLocation);
	}
}