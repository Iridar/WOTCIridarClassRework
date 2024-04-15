class Sharpshooter extends Common;

var localized string strSerialAimPenaltyEffectDesc;
var localized string SharpshooterAimBonusDesc;

static final function PatchAbilities()
{
	PatchSerial();
	PatchFanFire();
	PatchDeadeye();
	PatchDeadeyeDuncan();
	PatchDeathFromAbove();
	PatchSharpshooterAim();
	PatchReturnFire();

	PatchKillZoneShot();

	MakeInterruptible('LightningHands');
	MakeInterruptible('Faceoff');
}

static private function PatchKillZoneShot()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('KillZoneShot');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.AddTargetEffect(default.WeaponUpgradeMissDamage);
}

static private function PatchReturnFire()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect						Effect;
	local X2Effect_ReturnFire			FireEffect;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ReturnFire');
	if (AbilityTemplate == none)
		return;

	foreach AbilityTemplate.AbilityTargetEffects(Effect)
	{
		FireEffect = X2Effect_ReturnFire(Effect);
		if (X2Effect_ReturnFire(Effect) == none)
			continue;

		FireEffect.bPreEmptiveFire = true;
		break;
	}
	
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('PistolReturnFire');
	if (AbilityTemplate == none)
		return;

	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if (ToHitCalc == none)
		return;

	ToHitCalc.bIgnoreCoverBonus = true;
	//AbilityTemplate.AddTargetEffect(new class'X2Effect_ReturnFireIgnoresCover');
}

static private function PatchSharpshooterAim()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2DataTemplate					DataTemplate;
	local X2Effect_SH_SharpshooterAim		AimEffect;
	local X2Condition_AbilityProperty		AbilityCondition;
	local int i;

	AimEffect = new class'X2Effect_SH_SharpshooterAim';
	AimEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	AimEffect.SetDisplayInfo(ePerkBuff_Bonus, class'X2Ability_SharpshooterAbilitySet'.default.SharpshooterAimBonusName, default.SharpshooterAimBonusDesc, "img:///UILibrary_PerkIcons.UIPerk_aim");
	
	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('SharpshooterAim');
	AimEffect.TargetConditions.AddItem(AbilityCondition);

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach AbilityMgr.IterateTemplates(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if (AbilityTemplate == none)
			continue;

		for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
		{
			if (X2Effect_SharpshooterAim(AbilityTemplate.AbilityTargetEffects[i]) != none)
			{
				AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
				AbilityTemplate.AddTargetEffect(AimEffect);
				break;
			}
		}

		for (i = AbilityTemplate.AbilityShooterEffects.Length - 1; i >= 0; i--)
		{
			if (X2Effect_SharpshooterAim(AbilityTemplate.AbilityShooterEffects[i]) != none)
			{
				AbilityTemplate.AbilityShooterEffects.Remove(i, 1);
				AbilityTemplate.AddShooterEffect(AimEffect);
				break;
			}
		}

		for (i = AbilityTemplate.AbilityMultiTargetEffects.Length - 1; i >= 0; i--)
		{
			if (X2Effect_SharpshooterAim(AbilityTemplate.AbilityMultiTargetEffects[i]) != none)
			{
				AbilityTemplate.AbilityMultiTargetEffects.Remove(i, 1);
				AbilityTemplate.AddMultiTargetEffect(AimEffect);
				break;
			}
		}
	}
}

static private function PatchDeathFromAbove()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_SH_DeathFromAbove		DeathFromAbove;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('DeathFromAbove');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_DeathFromAbove(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			DeathFromAbove = new class'X2Effect_SH_DeathFromAbove';
			DeathFromAbove.BuildPersistentEffect(1, true, false, false);
			DeathFromAbove.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, true,,AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(DeathFromAbove);

			break;
		}
	}
}

static private function PatchDeadeyeDuncan()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_SH_DeadeyeDamage			DamageEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('DeadeyeDamage');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_DeadeyeDamage(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			DamageEffect = new class'X2Effect_SH_DeadeyeDamage';
			DamageEffect.BuildPersistentEffect(1, true, false, false);
			DamageEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, false,,AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(DamageEffect);

			break;
		}
	}
}

static private function PatchDeadeye()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Deadeye');
	if (AbilityTemplate == none)	
		return;

	// Use flat aim penalty instead of percentage based
	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	ToHitCalc.FinalMultiplier = 1.0f;
	ToHitCalc.BuiltInHitMod = `GetConfigInt("IRI_SH_DeadEye_AimPenalty");

	AbilityTemplate.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	AbilityTemplate.bAllowFreeFireWeaponUpgrade = true;
}

static private function PatchFanFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityCost_ActionPoints		ActionCost;
	local X2AbilityCost						AbilityCost;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('FanFire');
	if (AbilityTemplate == none)	
		return;

	foreach AbilityTemplate.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost == none)
			continue;

		// Make it turn-ending
		ActionCost.bConsumeAllPoints = true;
	}

	AbilityTemplate.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchSerial()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_Serial_AimPenalty		AimPenalty;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('InTheZone');
	if (AbilityTemplate == none)	
		return;

	AimPenalty = new class'X2Effect_Serial_AimPenalty';
	//AimPenalty.AimPenaltyPerShot = `GetConfigInt("IRI_SH_Serial_AimPenaltyPerShot");
	AimPenalty.CritChancePenaltyPerShot = `GetConfigInt("IRI_SH_Serial_CritChancePenaltyPerShot");
	AimPenalty.SetDisplayInfo(ePerkBuff_Penalty, AbilityTemplate.LocFriendlyName, default.strSerialAimPenaltyEffectDesc, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(AimPenalty);
}