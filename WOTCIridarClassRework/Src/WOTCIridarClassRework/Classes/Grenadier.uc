class Grenadier extends Common;

static final function PatchAbilities()
{
	PatchBlastPadding();
	PatchSaturationFire();
	PatchChainShot();
	//PatchSuppression();
	PatchSuppressionShot();
}

//static private function PatchSuppression()
//{
//	local X2AbilityTemplateManager	AbilityMgr;
//	local X2AbilityTemplate			AbilityTemplate;
//
//	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
//	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Suppression');
//	if (AbilityTemplate == none)	
//		return;
//
//	//AbilityTemplate.AddTargetEffect(new class'X2Effect_TriggerSuppressionShot');
//}

static private function PatchSuppressionShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim	ToHitCalc;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_ApplyWeaponDamage		StockEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SuppressionShot');
	if (AbilityTemplate == none)	
		return;

	// Ensure weapon upgrade compat
	AbilityTemplate.bAllowAmmoEffects = true;
	AbilityTemplate.bAllowBonusWeaponEffects = true;
	AbilityTemplate.bAllowFreeFireWeaponUpgrade = true;

	StockEffect = new class'X2Effect_ApplyWeaponDamage';
	StockEffect.bApplyOnHit = false;
	StockEffect.bApplyOnMiss = true;
	StockEffect.bIgnoreBaseDamage = true;
	StockEffect.DamageTag = 'Miss';
	StockEffect.bAllowWeaponUpgrade = true;
	StockEffect.bAllowFreeKill = false;
	StockEffect.TargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());
	AbilityTemplate.AddTargetEffect(StockEffect);

	// Trigger on ability activation too
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalAttackListener;
	AbilityTemplate.AbilityTriggers.AddItem(Trigger);

	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if (ToHitCalc == none)
		return;

	ToHitCalc.bIgnoreCoverBonus = true;
}

static private function PatchChainShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityTemplate					AbilityTemplate2;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc2;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ChainShot');
	AbilityTemplate2 = AbilityMgr.FindAbilityTemplate('ChainShot2');
	if (AbilityTemplate == none || AbilityTemplate2 == none)	
		return;

	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	ToHitCalc2 = X2AbilityToHitCalc_StandardAim(AbilityTemplate2.AbilityToHitCalc);
	if (ToHitCalc == none || ToHitCalc2 == none)	
		return;

	ToHitCalc2.BuiltInHitMod = ToHitCalc.BuiltInHitMod;
	ToHitCalc.BuiltInHitMod = 0;
}

static private function PatchSaturationFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ReliableWorldDamage		WorldDamage;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SaturationFire');
	if (AbilityTemplate == none)	
		return;

	EnsureWeaponUpgradeInteraction(AbilityTemplate);

	WorldDamage = new class'WOTCIridarClassRework.X2Effect_ReliableWorldDamage';
	WorldDamage.DamageAmount = `GetConfigInt("IRI_GN_SaturationFire_Reliable_EnvDamage");

	// Many cover objects occupy more than one tile, and chance is rolled per-tile, so lower it accordingly
	WorldDamage.ApplyChancePerTile = class'X2Ability_GrenadierAbilitySet'.default.SATURATION_DESTRUCTION_CHANCE / 2;
	WorldDamage.bSkipGroundTiles = true;
	AbilityTemplate.AddShooterEffect(WorldDamage);
	AbilityTemplate.bRecordValidTiles = true; // For the world damage effect
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
