class Spark extends Common;

static final function PatchAbilities()
{
	PatchSacrifice();
	PatchRepair();

	UpdateShotHUDPrioritiesForClass('Spark');
}

static private function PatchRepair()
{
	local X2AbilityTemplateManager				AbilityMgr;
	local X2AbilityTemplate						AbilityTemplate;
	local X2Effect_RemoveEffectsByDamageType	RemoveEffects;
	local name									HealType;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Repair');
	if (AbilityTemplate == none)	
		return;

	// Make Repair remove negative effects.
	// Copied from SPARK Repair Fix by Udaya with permission.
	RemoveEffects = new class'X2Effect_RemoveEffectsByDamageType';
	foreach class'X2Ability_DefaultAbilitySet'.default.MedikitHealEffectTypes(HealType)
	{
		RemoveEffects.DamageTypesToRemove.AddItem(HealType);
	}
	AbilityTemplate.AddTargetEffect(RemoveEffects);
}


static private function PatchSacrifice()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Sacrifice');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.TargetingMethod = class'X2TargetingMethod_SacrificeSnapToTile';
}
