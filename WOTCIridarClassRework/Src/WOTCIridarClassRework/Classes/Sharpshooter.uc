class Sharpshooter extends Common abstract;

var localized string strSerialAimPenaltyEffectDesc;

static final function PatchAbilities()
{
	PatchSerial();
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
	AimPenalty.AimPenaltyPerShot = `GetConfigInt("IRI_SH_Serial_AimPenaltyPerShot");
	AimPenalty.SetDisplayInfo(ePerkBuff_Penalty, AbilityTemplate.LocFriendlyName, default.strSerialAimPenaltyEffectDesc, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(AimPenalty);
}