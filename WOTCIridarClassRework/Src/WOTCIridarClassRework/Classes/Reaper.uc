class Reaper extends Common;

static final function PatchAbilities()
{
	PatchSting();
	PatchBloodTrail();
	PatchImprovisedSilencer();
	PatchExecutioner();
}

static private function PatchExecutioner()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_RP_Executioner		Effect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Executioner');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Executioner(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
		}
	}

	Effect = new class'X2Effect_RP_Executioner';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(Effect);
}

static private function PatchBloodTrail()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_RP_BloodTrail		Effect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('BloodTrail');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_BloodTrail(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
		}
	}

	Effect = new class'X2Effect_RP_BloodTrail';
	Effect.BonusDamage = class'X2Ability_ReaperAbilitySet'.default.BloodTrailDamage;
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(Effect);
}



static private function PatchSting()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim	StandardAim;
	local X2Effect_Charges					SetCharges;
	local X2Effect_Charges					SetClaymoreCharges;
	local X2Condition_AbilityProperty		AbilityProperty;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Sting');
	if (AbilityTemplate == none)	
		return;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bHitsAreCrits = true;
	StandardAim.BuiltInCritMod = 100;
	AbilityTemplate.AbilityToHitCalc = StandardAim;

	SetCharges = new class'X2Effect_Charges';
	SetCharges.AbilityNames.AddItem('Sting');
	SetCharges.Charges = class'X2Ability_ReaperAbilitySet'.default.StingCharges;
	SetCharges.bSetCharges = true;


	SetClaymoreCharges = new class'X2Effect_Charges';
	SetClaymoreCharges.AbilityNames.AddItem('ThrowClaymore');
	SetClaymoreCharges.AbilityNames.AddItem('ThrowShrapnel');
	SetClaymoreCharges.AbilityNames.AddItem('HomingMine');
	SetClaymoreCharges.AbilityNames.AddItem('IRI_RP_Takedown');
	SetClaymoreCharges.Charges = 1;
	SetClaymoreCharges.bRespectInitialCharges = true;
	
	AbilityProperty = new class'X2Condition_AbilityProperty';
	AbilityProperty.OwnerHasSoldierAbilities.AddItem('IRI_RP_MakeshiftExplosives');
	SetClaymoreCharges.TargetConditions.AddItem(AbilityProperty);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Shadow');
	if (AbilityTemplate != none)	
	{
		AbilityTemplate.AddTargetEffect(SetCharges);
		AbilityTemplate.AddTargetEffect(SetClaymoreCharges);
	}

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('DistractionShadow');
	if (AbilityTemplate != none)	
	{
		AbilityTemplate.AddTargetEffect(SetCharges);
		AbilityTemplate.AddTargetEffect(SetClaymoreCharges);
	}
}

static private function PatchImprovisedSilencer()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ImprovisedSilencer');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_improvisedsilencer";
}
