class X2Effect_PersistentVoidConduit_Fixed extends X2Effect_PersistentVoidConduit;

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit SourceUnit;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return 1;

	`AMLOG("Returning:" @ SourceUnit.GetTemplarFocusLevel());

	return SourceUnit.GetTemplarFocusLevel();
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.Length = 0;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	//local XComGameState_Unit TargetUnit;
	//
	//TargetUnit = XComGameState_Unit(kNewTargetState);
	//if (TargetUnit != none)
	//{
	//	TargetUnit.TakeEffectDamage(self, InitialDamage, 0, 0, ApplyEffectParameters, NewGameState);
	//}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
}

function bool AllowDodge(XComGameState_Unit Attacker, XComGameState_Ability AbilityState) { return false; }

DefaultProperties
{
	bCanTickEveryAction = false
}
