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

static final protected function RemoveActionAndChargeCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	RemoveChargeCost(AbilityTemplate);

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[i]) != none)
		{
			AbilityTemplate.AbilityCosts.Remove(i, 1);
		}
	}
}

static final protected function AddActionPointNameToActionCost(out X2AbilityTemplate AbilityTemplate, const name ActionPointName)
{
	local X2AbilityCost_ActionPoints	ActionCost;
	local X2AbilityCost					AbilityCost;

	foreach AbilityTemplate.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost == none)
			continue;

		ActionCost.AllowedTypes.AddItem(ActionPointName);
	}
}

static final protected function MakeNotEndTurn(out X2AbilityTemplate AbilityTemplate)
{
	local X2AbilityCost_ActionPoints	ActionCost;
	local X2AbilityCost					AbilityCost;

	foreach AbilityTemplate.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost == none)
			continue;

		ActionCost.bConsumeAllPoints = false;
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
	else
	{
		Template.AbilityCooldown = none;
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

static final protected function CopyLocalization(X2AbilityTemplateManager AbilityTemplateManager, name TemplateName, name DonorTemplateName)
{
	local X2AbilityTemplate Template;
	local X2AbilityTemplate DonorTemplate;

	Template = AbilityTemplateManager.FindAbilityTemplate(TemplateName);
	DonorTemplate = AbilityTemplateManager.FindAbilityTemplate(DonorTemplateName);

	if (Template != none && DonorTemplate != none)
	{
		Template.LocFriendlyName = DonorTemplate.LocFriendlyName;
		Template.LocHelpText = DonorTemplate.LocHelpText;                   
		Template.LocLongDescription = DonorTemplate.LocLongDescription;
		Template.LocPromotionPopupText = DonorTemplate.LocPromotionPopupText;
		Template.LocFlyOverText = DonorTemplate.LocFlyOverText;
		Template.LocMissMessage = DonorTemplate.LocMissMessage;
		Template.LocHitMessage = DonorTemplate.LocHitMessage;
		Template.LocFriendlyNameWhenConcealed = DonorTemplate.LocFriendlyNameWhenConcealed;      
		Template.LocLongDescriptionWhenConcealed = DonorTemplate.LocLongDescriptionWhenConcealed;   
		Template.LocDefaultSoldierClass = DonorTemplate.LocDefaultSoldierClass;
		Template.LocDefaultPrimaryWeapon = DonorTemplate.LocDefaultPrimaryWeapon;
		Template.LocDefaultSecondaryWeapon = DonorTemplate.LocDefaultSecondaryWeapon;
	}
}