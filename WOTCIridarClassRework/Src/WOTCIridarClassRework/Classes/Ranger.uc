class Ranger extends Common;

static final function PatchAbilities()
{
	//PatchSwordSlice();
	PatchPhantom();
	PatchRapidFire();
	PatchGuardianForIntercept();
}

// Necessary only in a scenario where Slash doesn't end turn.
//static private function PatchSwordSlice()
//{
//	local X2AbilityTemplateManager			AbilityMgr;
//	local X2AbilityTemplate					AbilityTemplate;
//
//	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
//	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SwordSlice');
//	if (AbilityTemplate == none)	
//		return;
//
//	RemoveActionAndChargeCost(AbilityTemplate);
//
//	AbilityTemplate.AbilityCosts.AddItem(new class'X2AbilityCost_RN_SlashActionPoints');
//}

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

static private function PatchPhantom()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Phantom');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.AdditionalAbilities.AddItem('IRI_RN_ConcealDetectionRadiusReduction');
}

static private function PatchRapidFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ToHitModifier			ToHitModifier;
	local X2Effect							TargetEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('RapidFire');
	if (AbilityTemplate == none)	
		return;

	AddCooldown(AbilityTemplate, `GetConfigFloat("IRI_RapidFire_Cooldown"));
}