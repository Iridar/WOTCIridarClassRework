class X2Effect_ReduceCooldown extends X2Effect;

var name AbilityName;
var int ReduceCooldown;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit		UnitState;
	local StateObjectReference		AbilityRef;
	local XComGameState_Ability		AbilityState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == none)
		return;

	AbilityRef = UnitState.FindAbility(AbilityName);
	if (AbilityRef.ObjectID <= 0)
		return;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
		return;

	AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
	AbilityState.iCooldown -= ReduceCooldown;
	if (AbilityState.iCooldown < 0)
		AbilityState.iCooldown = 0;
}

