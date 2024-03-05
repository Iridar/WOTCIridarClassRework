class X2Effect_RP_Executioner extends X2Effect_Executioner;

function int GetAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	local XComGameState_Item SourceWeapon;
	local WeaponDamageValue DamageValue;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);

	//  only add bonus damage on a crit, flanking, while in shadow
	if (AppliedData.AbilityResultContext.HitResult == eHit_Crit && Attacker.IsSuperConcealed() && TargetUnit != none && TargetUnit.IsFlanked(Attacker.GetReference()))
	{
		SourceWeapon = AbilityState.GetSourceWeapon();
		if (SourceWeapon != none)
		{
			SourceWeapon.GetBaseWeaponDamageValue(none, DamageValue);
		}
		else if (WeaponDamageEffect.bIgnoreBaseDamage)
		{

			DamageValue = WeaponDamageEffect.EffectDamageValue;
		}

		// Double the Crit damage
		return DamageValue.Crit;
	}

	return 0;
}
