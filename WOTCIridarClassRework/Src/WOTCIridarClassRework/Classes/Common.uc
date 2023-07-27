class Common extends X2Ability;

static final protected function EnsureWeaponUpgradeInteraction(out X2AbilityTemplate AbilityTemplate)
{
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local X2Effect						Effect;
	local bool							bEffectFound;

	AbilityTemplate.bAllowAmmoEffects = true;
	AbilityTemplate.bAllowBonusWeaponEffects = true;
	AbilityTemplate.bAllowFreeFireWeaponUpgrade = true;

	if (AbilityTemplate.AbilityTargetEffects.Length > 0)
	{	
		// Add Stock Damage effect
		bEffectFound = false;
		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			DamageEffect = X2Effect_ApplyWeaponDamage(Effect);
			if (DamageEffect == none)
				continue;

			if (DamageEffect.DamageTag == 'Miss' && !DamageEffect.bApplyOnHit && DamageEffect.bApplyOnMiss && DamageEffect.bIgnoreBaseDamage)
			{
				bEffectFound = true;
				break;
			}
		}
		if (!bEffectFound)
		{
			AbilityTemplate.AddTargetEffect(default.WeaponUpgradeMissDamage);
		}

		// Add Holo Targeting effect
		bEffectFound = false;
		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			if (X2Effect_HoloTarget(Effect) != none)
			{
				bEffectFound = true;
				break;
			}			
		}
		if (!bEffectFound)
		{
			AbilityTemplate.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
			if (AbilityTemplate.AssociatedPassives.Find('HoloTargeting') == INDEX_NONE)
			{
				AbilityTemplate.AssociatedPassives.AddItem('HoloTargeting');
			}
		}
	}
	
	if (AbilityTemplate.AbilityMultiTargetEffects.Length > 0 && AbilityTemplate.AbilityMultiTargetStyle != none)
	{
		// Add Stock Damage effect
		bEffectFound = false;
		foreach AbilityTemplate.AbilityMultiTargetEffects(Effect)
		{
			DamageEffect = X2Effect_ApplyWeaponDamage(Effect);
			if (DamageEffect == none)
				continue;

			if (DamageEffect.DamageTag == 'Miss' && !DamageEffect.bApplyOnHit && DamageEffect.bApplyOnMiss && DamageEffect.bIgnoreBaseDamage)
			{
				bEffectFound = true;
				break;
			}
		}
		if (!bEffectFound)
		{
			AbilityTemplate.AddMultiTargetEffect(default.WeaponUpgradeMissDamage);
		}

		// Add Holo Targeting effect
		bEffectFound = false;
		foreach AbilityTemplate.AbilityMultiTargetEffects(Effect)
		{
			if (X2Effect_HoloTarget(Effect) != none)
			{
				bEffectFound = true;
				break;
			}			
		}
		if (!bEffectFound)
		{
			AbilityTemplate.AddMultiTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
			if (AbilityTemplate.AssociatedPassives.Find('HoloTargeting') == INDEX_NONE)
			{
				AbilityTemplate.AssociatedPassives.AddItem('HoloTargeting');
			}
		}
	}
}

static final protected function RemoveChargeCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	AbilityTemplate.AbilityCharges = none;

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_Charges(AbilityTemplate.AbilityCosts[i]) != none)
		{
			AbilityTemplate.AbilityCosts.Remove(i, 1);
		}
	}
}

static final protected function RemoveActionCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	AbilityTemplate.AbilityCharges = none;

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[i]) != none)
		{
			AbilityTemplate.AbilityCosts.Remove(i, 1);
		}
	}
}

static final protected function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}

static final protected function AddFreeActionCost(out X2AbilityTemplate Template)
{
	local X2AbilityCost_ActionPoints ActionPointCost;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
}
