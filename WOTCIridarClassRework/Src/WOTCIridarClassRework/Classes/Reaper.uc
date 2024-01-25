class Reaper extends Common;

static final function PatchAbilities()
{
	PatchSting();
	PatchImprovisedSilencer();
}

static private function PatchSting()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim	StandardAim;
	local X2Effect_Charges					SetCharges;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Sting');
	if (AbilityTemplate == none)	
		return;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bHitsAreCrits = true;
	StandardAim.BuiltInCritMod = 100;
	AbilityTemplate.AbilityToHitCalc = StandardAim;

	SetCharges = new class'X2Effect_Charges';
	SetCharges.AbilityName = 'Sting';
	SetCharges.Charges = class'X2Ability_ReaperAbilitySet'.default.StingCharges;
	SetCharges.bSetCharges = true;

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Shadow');
	if (AbilityTemplate != none)	
	{
		AbilityTemplate.AddTargetEffect(SetCharges);
	}

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('DistractionShadow');
	if (AbilityTemplate != none)	
	{
		AbilityTemplate.AddTargetEffect(SetCharges);
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
