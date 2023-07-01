class Ranger extends Common abstract;

static final function PatchAbilities()
{
	PatchConceal();
	PatchShadowstrike();
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
	local X2Condition_Visibility			VisCondition;
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