class Sharpshooter extends Common abstract;

var localized string strSerialAimPenaltyEffectDesc;

static final function PatchAbilities()
{
	PatchSerial();
	PatchFanFire();
	PatchDeadeye();
	PatchDeadeyeDuncan();
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
	AimPenalty.DamagePenaltyPerShot = `GetConfigFloat("IRI_SH_Serial_DamagePenaltyPerShot");
	AimPenalty.SetDisplayInfo(ePerkBuff_Penalty, AbilityTemplate.LocFriendlyName, default.strSerialAimPenaltyEffectDesc, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(AimPenalty);
}