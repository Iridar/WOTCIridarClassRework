class Common extends X2Ability;

static final protected function UpdateShotHUDPrioritiesForClass(const name ClassName)
{
	local X2SoldierClassTemplate		ClassTemplate;
	local X2SoldierClassTemplateManager	ClassMgr;
	local X2AbilityTemplateManager		AbilityMgr;
	local SoldierClassRank				SoldierRank;
	local SoldierClassAbilitySlot		AbilitySlot;
	local int							iRank;

	if (!`GetConfigBool("Update_HUD_Priorities"))
		return;

	ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	ClassTemplate = ClassMgr.FindSoldierClassTemplate(ClassName);
	if (ClassTemplate == none)
		return;

	`AMLOG("--- Updating Shot HUD Priority for Class:" @ ClassName @ "---");

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	foreach ClassTemplate.SoldierRanks(SoldierRank, iRank)
	{
		foreach SoldierRank.AbilitySlots(AbilitySlot)
		{
			UpdateAbilityPriorityRecursive(AbilitySlot.AbilityType.AbilityName, AbilityMgr, iRank);
		}
	}
}

static final protected function UpdateAbilityPriorityRecursive(const name AbilityName, X2AbilityTemplateManager AbilityMgr, const int iRank)
{
	local X2AbilityTemplate Template;
	local name AdditionalAbility;

	Template = AbilityMgr.FindAbilityTemplate(AbilityName);
	if (Template == none)
		return;

	// If Priority isn't set or it already uses one of the rank priorities
	if (Template.ShotHUDPriority == -1 || Template.ShotHUDPriority >= 310 && Template.ShotHUDPriority <= 370)
	{
		if (Template.ShotHUDPriority != 310 + iRank * 10)
		{
			`AMLOG("Updating priority for ability:" @ Template.DataName @ "to:" @ 310 + iRank * 10);
		}

		// Then make sure it uses the right priority.
		Template.ShotHUDPriority = 310 + iRank * 10;
	}

	foreach Template.AdditionalAbilities(AdditionalAbility)
	{
		UpdateAbilityPriorityRecursive(AdditionalAbility, AbilityMgr, iRank);
	}
}

static final protected function EnsureWeaponUpgradeInteraction(out X2AbilityTemplate AbilityTemplate)
{
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local X2Effect						Effect;
	local bool							bEffectFound;

	AbilityTemplate.bAllowAmmoEffects = true;
	AbilityTemplate.bAllowBonusWeaponEffects = true;
	AbilityTemplate.bAllowFreeFireWeaponUpgrade = true;

	`AMLOG("Running for:" @ AbilityTemplate.DataName);

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

		// Add Holo Targeting effect -- Firaxis didn't want multi target abilities to apply holo targeting.
		//bEffectFound = false;
		//foreach AbilityTemplate.AbilityMultiTargetEffects(Effect)
		//{
		//	if (X2Effect_HoloTarget(Effect) != none)
		//	{
		//		bEffectFound = true;
		//		break;
		//	}			
		//}
		//if (!bEffectFound)
		//{
		//	AbilityTemplate.AddMultiTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
		//	if (AbilityTemplate.AssociatedPassives.Find('HoloTargeting') == INDEX_NONE)
		//	{
		//		AbilityTemplate.AssociatedPassives.AddItem('HoloTargeting');
		//	}
		//}
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

static final protected function RemoveFocusCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_Focus(AbilityTemplate.AbilityCosts[i]) != none)
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

static final protected function MakeFreeActionCost(out X2AbilityTemplate AbilityTemplate)
{
	local X2AbilityCost_ActionPoints	ActionCost;
	local X2AbilityCost					AbilityCost;

	foreach AbilityTemplate.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost == none)
			continue;

		ActionCost.bFreeCost = true;
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

static final protected function CopyLocalization(const name TemplateName, const name DonorTemplateName)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate Template;
	local X2AbilityTemplate DonorTemplate;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

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


static final protected function MakeInterruptible(const name TemplateName)
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate(TemplateName);
	if (Template == none)	
		return;

	if (Template.BuildInterruptGameStateFn != none)
		return;

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}
