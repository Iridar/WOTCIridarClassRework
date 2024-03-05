class X2Effect_RP_BloodTrail extends X2Effect_BloodTrail;

// Deal bonus damage, but only with normal weapon attacks, and also to units that are bleeding.

function int GetAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	if (!WeaponDamageEffect.bIgnoreBaseDamage)
	{
		return GetAttackingDamageModifier(EffectState, Attacker, TargetDamageable, AbilityState, AppliedData, CurrentDamage, NewGameState);
	}
	return 0;
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnit;
	local UnitValue DamageUnitValue;

	if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && AbilityState.IsAbilityInputTriggered())
	{
		if (AbilityState.SourceWeapon == EffectState.ApplyEffectParameters.ItemStateObjectRef)
		{
			TargetUnit = XComGameState_Unit(TargetDamageable);
			if (TargetUnit != none)
			{
				TargetUnit.GetUnitValue('DamageThisTurn', DamageUnitValue);
				if (DamageUnitValue.fValue > 0 || TargetUnit.IsUnitAffectedByEffectName(class'X2StatusEffects'.default.BleedingName) || TargetUnit.IsAlreadyTakingEffectDamage('Bleeding'))
				{
					return BonusDamage;
				}
			}			
		}
	}
	
	return 0;
}
