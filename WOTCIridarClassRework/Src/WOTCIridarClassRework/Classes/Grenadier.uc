class Grenadier extends Common;

static final function PatchAbilities()
{
	PatchBlastPadding();
	PatchSaturationFire();
	PatchChainShot();
	PatchDemolition();
	//PatchSuppression();
	PatchSuppressionShot();
	//PatchRupture();

	PatchBulletShred();
	PatchHailOfBullets();
}

static private function PatchHailOfBullets()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('HailOfBullets');
	if (Template == none)	
		return;

	Template.bAllowFreeFireWeaponUpgrade = true;
}

static private function PatchBulletShred()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate				Template;
	local X2Condition_UnitEffects	UnitEffects;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('BulletShred');
	if (Template == none)	
		return;

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	// For some reason Firaxis decided to allow using Rupture while disoriented.
	UnitEffects = new class'X2Condition_UnitEffects';
	UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.DisorientedName, 'AA_UnitIsDisoriented');
	Template.AbilityShooterConditions.AddItem(UnitEffects);

	Template.AddTargetEffect(default.WeaponUpgradeMissDamage);
}

//static private function PatchRupture()
//{
//	local X2AbilityTemplateManager			AbilityMgr;
//	local X2AbilityTemplate					Template;
//	local X2AbilityToHitCalc_StandardAim	StandardAim;
//
//	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
//	Template = AbilityMgr.FindAbilityTemplate('BulletShred');
//	if (Template == none)
//		return;
//
//	Template.AddTargetEffect(new class'X2Effect_RuptureDamagePreview');
//
//	StandardAim = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
//	if (StandardAim == none)
//		return;
//	//StandardAim.bHitsAreCrits = true;
//	StandardAim.BuiltInCritMod = 100;
//}

static private function PatchDemolition()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;
	//local X2AbilityToHitCalc_StandardAim	StandardAim;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Demolition');
	if (Template == none)
		return;

	//Template.bLimitTargetIcons = false;
	Template.DisplayTargetHitChance = false;
	//StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	//StandardAim.bGuaranteedHit = true;
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
}

//static private function PatchSuppression()
//{
//	local X2AbilityTemplateManager	AbilityMgr;
//	local X2AbilityTemplate			Template;
//
//	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
//	Template = AbilityMgr.FindAbilityTemplate('Suppression');
//	if (Template == none)	
//		return;
//
//	//Template.AddTargetEffect(new class'X2Effect_TriggerSuppressionShot');
//}

static private function PatchSuppressionShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2AbilityToHitCalc_StandardAim	ToHitCalc;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_ApplyWeaponDamage		StockEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('SuppressionShot');
	if (Template == none)	
		return;

	// Ensure weapon upgrade compat
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = true;

	StockEffect = new class'X2Effect_ApplyWeaponDamage';
	StockEffect.bApplyOnHit = false;
	StockEffect.bApplyOnMiss = true;
	StockEffect.bIgnoreBaseDamage = true;
	StockEffect.DamageTag = 'Miss';
	StockEffect.bAllowWeaponUpgrade = true;
	StockEffect.bAllowFreeKill = false;
	StockEffect.TargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());
	Template.AddTargetEffect(StockEffect);

	// Trigger on ability activation too
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalAttackListener;
	Template.AbilityTriggers.AddItem(Trigger);

	ToHitCalc = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
	if (ToHitCalc == none)
		return;

	ToHitCalc.bIgnoreCoverBonus = true;
}

static private function PatchChainShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2AbilityTemplate					Template2;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc2;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('ChainShot');
	Template2 = AbilityMgr.FindAbilityTemplate('ChainShot2');
	if (Template == none || Template2 == none)	
		return;

	Template.bAllowFreeFireWeaponUpgrade = true;

	ToHitCalc = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
	ToHitCalc2 = X2AbilityToHitCalc_StandardAim(Template2.AbilityToHitCalc);
	if (ToHitCalc == none || ToHitCalc2 == none)	
		return;

	ToHitCalc2.BuiltInHitMod = ToHitCalc.BuiltInHitMod;
	ToHitCalc.BuiltInHitMod = 0;

	Template2.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchSaturationFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect_ReliableWorldDamage		WorldDamage;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('SaturationFire');
	if (Template == none)	
		return;

	EnsureWeaponUpgradeInteraction(Template);

	WorldDamage = new class'WOTCIridarClassRework.X2Effect_ReliableWorldDamage';
	WorldDamage.DamageAmount = `GetConfigInt("IRI_GN_SaturationFire_Reliable_EnvDamage");

	// Many cover objects occupy more than one tile, and chance is rolled per-tile, so lower it accordingly
	WorldDamage.ApplyChancePerTile = class'X2Ability_GrenadierAbilitySet'.default.SATURATION_DESTRUCTION_CHANCE / 2;
	WorldDamage.bSkipGroundTiles = true;
	Template.AddShooterEffect(WorldDamage);
	Template.bRecordValidTiles = true; // For the world damage effect

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchBlastPadding()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect_BlastPaddingExtended		PaddingEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('BlastPadding');
	if (Template == none)	
		return;

	PaddingEffect = new class'X2Effect_BlastPaddingExtended';
	PaddingEffect.ExplosiveDamageReduction = class'X2Ability_GrenadierAbilitySet'.default.BLAST_PADDING_DMG_ADJUST;
	PaddingEffect.BuildPersistentEffect(1, true, false);
	PaddingEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false,, Template.AbilitySourceName);
	Template.AddTargetEffect(PaddingEffect);
}
