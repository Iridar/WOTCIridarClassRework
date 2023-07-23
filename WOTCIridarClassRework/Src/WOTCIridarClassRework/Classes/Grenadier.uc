class Grenadier extends Common abstract;

static final function PatchAbilities()
{
	PatchBlastPadding();

}

static private function PatchBlastPadding()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_BlastPaddingExtended		PaddingEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('BlastPadding');
	if (AbilityTemplate == none)	
		return;

	PaddingEffect = new class'X2Effect_BlastPaddingExtended';
	PaddingEffect.ExplosiveDamageReduction = class'X2Ability_GrenadierAbilitySet'.default.BLAST_PADDING_DMG_ADJUST;
	PaddingEffect.BuildPersistentEffect(1, true, false);
	PaddingEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyHelpText(), AbilityTemplate.IconImage, false,, AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(PaddingEffect);
}

static private function PatchGuardianForIntercept()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_Guardian					GuardianEffect;
	local X2DataTemplate					DataTemplate;
	local X2Effect							Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach AbilityMgr.IterateTemplates(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if (AbilityTemplate == none)
			continue;

		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			GuardianEffect = X2Effect_Guardian(Effect);
			if (GuardianEffect == none)
				continue;

			GuardianEffect.AllowedAbilities.AddItem('IRI_RN_Intercept_Attack');
		}

		foreach AbilityTemplate.AbilityShooterEffects(Effect)
		{
			GuardianEffect = X2Effect_Guardian(Effect);
			if (GuardianEffect == none)
				continue;

			GuardianEffect.AllowedAbilities.AddItem('IRI_RN_Intercept_Attack');
		}

		foreach AbilityTemplate.AbilityMultiTargetEffects(Effect)
		{
			GuardianEffect = X2Effect_Guardian(Effect);
			if (GuardianEffect == none)
				continue;

			GuardianEffect.AllowedAbilities.AddItem('IRI_RN_Intercept_Attack');
		}
	}
}

static private function PatchConceal()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Phantom');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.AdditionalAbilities.AddItem('IRI_RN_ConcealDetectionRadiusReduction');
}

static private function PatchShadowstrike()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ToHitModifier			ToHitModifier;
	local X2Effect							TargetEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Shadowstrike');
	if (AbilityTemplate == none)	
		return;

	foreach AbilityTemplate.AbilityTargetEffects(TargetEffect)
	{
		ToHitModifier = X2Effect_ToHitModifier(TargetEffect);
		if (ToHitModifier == none)
			continue;


		for (i = ToHitModifier.ToHitConditions.Length - 1; i >= 0; i--)
		{
			if (X2Condition_Visibility(ToHitModifier.ToHitConditions[i]) != none)
			{
				ToHitModifier.ToHitConditions.Remove(i, 1);

				ToHitModifier.ToHitConditions.AddItem(new class'X2Condition_SourceIsConcealed');
				break;
			}
		}
		//break;
	}

	AbilityTemplate.AdditionalAbilities.AddItem('IRI_RN_Shadowstrike_OnBreakConcealment');
}