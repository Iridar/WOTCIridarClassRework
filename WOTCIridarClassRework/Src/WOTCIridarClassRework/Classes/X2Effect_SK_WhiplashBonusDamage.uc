class X2Effect_SK_WhiplashBonusDamage extends X2Effect_Persistent;

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(Target);

	if (TargetUnit != none && TargetUnit.IsRobotic() && AbilityState.GetMyTemplateName() == 'Whiplash')
	{
		return CurrentDamage * `GetConfigFloat("IRI_SK_Whiplash_BonusDamageRobotic"); 
	}
	return 0;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
}