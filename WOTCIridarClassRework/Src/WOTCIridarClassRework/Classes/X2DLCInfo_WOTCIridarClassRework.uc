class X2DLCInfo_WOTCIridarClassRework extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	PatchWhiplash();
}

static private function PatchWhiplash()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local X2Condition_UnitProperty		OnlyOrganic;
	local X2Condition_UnitProperty		OnlyRobotic;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Whiplash');
	AbilityTemplate.DefaultSourceItemSlot = eInvSlot_SecondaryWeapon;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		DamageEffect = X2Effect_ApplyWeaponDamage(AbilityTemplate.AbilityTargetEffects[i]);
		if (DamageEffect == none)
			continue;

		if (DamageEffect.EffectDamageValue == class'X2Ability_SkirmisherAbilitySet'.default.WHIPLASH_BASEDAMAGE)
		{	
			AbilityTemplate.AbilityTargetEffects.RemoveItem(i, 1);
		}
	}

	if (EffectHasRoboticCondition(DamageEffect))
	{
		DamageEffect.EffectDamageValue = EmptyDamageValue;
			
	}
	else
	{
		DamageEffect.EffectDamageValue = EmptyDamageValue;
		DamageEffect.bIgnoreBaseDamage = true;
		DamageEffect.DamageTag = 'Whiplash';
	}

	OnlyOrganic = new class'X2Condition_UnitProperty';
	OnlyOrganic.ExcludeRobotic = true;
	OnlyOrganic.ExcludeOrganic = false;

	OnlyRobotic = new class'X2Condition_UnitProperty';
	OnlyRobotic.ExcludeRobotic = false;
	OnlyRobotic.ExcludeOrganic = true;

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'Whiplash';
	DamageEffect.TargetConditions.AddItem(OnlyOrganic);
	AbilityTemplate.AddTargetEffect(DamageEffect);

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'Whiplash_Robotic';
	DamageEffect.TargetConditions.AddItem(OnlyRobotic);
	AbilityTemplate.AddTargetEffect(DamageEffect);
}