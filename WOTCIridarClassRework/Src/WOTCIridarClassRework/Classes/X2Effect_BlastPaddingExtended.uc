class X2Effect_BlastPaddingExtended extends X2Effect_BlastPadding;

// Copied from More Effective Blast Padding by RealityMachina
// https://steamcommunity.com/sharedfiles/filedetails/?id=1379047477

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	// Neuter the original function in favor of the CHL one.
	// local int DamageMod;
	// 
	// if (WeaponDamageEffect.bExplosiveDamage)
	// {
	// 	DamageMod = -int(float(CurrentDamage) * ExplosiveDamageReduction);
	// }
	// 
	// return DamageMod;

	return 0;
}

function float GetPostDefaultDefendingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local bool			bExplosiveDamage;
	local array<name>	AttackDamageTypes;

	if (WeaponDamageEffect.bExplosiveDamage)
	{
		bExplosiveDamage = true;
	}
	else
	{
		WeaponDamageEffect.GetEffectDamageTypes(NewGameState, ApplyEffectParameters, AttackDamageTypes);

		// Might be redundant
		if (WeaponDamageEffect.EffectDamageValue.DamageType != '')
		{
			AttackDamageTypes.AddItem(WeaponDamageEffect.EffectDamageValue.DamageType);
		}

		if (AttackDamageTypes.Find('Explosion') != INDEX_NONE || AttackDamageTypes.Find('BlazingPinions') != INDEX_NONE)
		{
			bExplosiveDamage = true;
		}
	}

	if (bExplosiveDamage)
	{
		return CurrentDamage * -ExplosiveDamageReduction;
	}
	return 0;
}

function int ModifyDamageFromDestructible(XComGameState_Destructible DestructibleState, int IncomingDamage, XComGameState_Unit TargetUnit, XComGameState_Effect EffectState)
{
	//	destructible damage is always considered to be explosive

	return float(IncomingDamage) * -ExplosiveDamageReduction;
}

defaultproperties
{
	bDisplayInSpecialDamageMessageUI = true
}
