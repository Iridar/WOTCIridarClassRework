class Specialist extends Common;

var private name GremlinActionPoint;

static final function PatchAbilities()
{
	PatchAidProtocol();
	PatchGremlinHeal();
	PatchGremlinStabilize();
	PatchCombatProtocol();
	PatchRevivalProtocol();
	PatchHaywireProtocol();
	PatchCapacitorDischarge();
	PatchRevival();
	PatchGremlins();
}

static private function PatchGremlins()
{
	local X2ItemTemplateManager		ItemMgr;
	local X2WeaponTemplate			WeaponTemplate;
	local array<X2WeaponTemplate>	WeaponTemplates;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	WeaponTemplates = ItemMgr.GetAllWeaponTemplates();

	foreach WeaponTemplates(WeaponTemplate)
	{
		if (WeaponTemplate.WeaponCat != class'X2GremlinTemplate'.default.WeaponCat || !WeaponTemplate.IsA('X2GremlinTemplate'))
			continue;

		WeaponTemplate.Abilities.AddItem('IRI_SP_ScoutingProtocol');
	}
}




static private function PatchCapacitorDischarge()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ApplyWeaponDamage		DamageEffect;
	local X2Effect							Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('CapacitorDischarge');
	if (AbilityTemplate == none)	
		return;

	foreach AbilityTemplate.AbilityTargetEffects(Effect)
	{
		DamageEffect = X2Effect_ApplyWeaponDamage(Effect);
		if (DamageEffect == none)
			continue;

		DamageEffect.bIgnoreArmor = true;
	}
}

static private function PatchHaywireProtocol()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityCharges_RevivalProtocol	Charges;
	local X2Effect_GiveStandardActionPoints GiveStandardActionPoints;
	local X2Effect_RemoveEffects			RemoveStunned;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('FinalizeHaywire');
	if (AbilityTemplate == none)	
		return;

	AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);
	
	MakeNotEndTurn(AbilityTemplate);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('HaywireProtocol');
	if (AbilityTemplate != none) AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('IntrusionProtocol_Chest');
	if (AbilityTemplate != none) AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);
	
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('IntrusionProtocol_Workstation');
	if (AbilityTemplate != none) AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('IntrusionProtocol_ObjectiveChest');
	if (AbilityTemplate != none) AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('IntrusionProtocol_Scan');
	if (AbilityTemplate != none) AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('FinalizeIntrusion');
	if (AbilityTemplate != none) AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);
}


static private function PatchRevivalProtocol()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityCharges_RevivalProtocol	Charges;
	local X2Effect_GiveStandardActionPoints GiveStandardActionPoints;
	local X2Effect_RemoveEffects			RemoveStunned;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('RevivalProtocol');
	if (AbilityTemplate == none)	
		return;

	AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);
	
	// ## Make charges scale with Gremlin tier.
	Charges = new class'X2AbilityCharges_RevivalProtocol';
	if (AbilityTemplate.AbilityCharges != none)
	{
		// Just in case user changed the default config of 1 charge.
		Charges.InitialCharges = AbilityTemplate.AbilityCharges.InitialCharges;
	}
	AbilityTemplate.AbilityCharges = Charges;

	// ## Allow targeting stunned units and all friendly units, not just XCOM
	for (i = AbilityTemplate.AbilityTargetConditions.Length - 1; i >= 0; i--)
	{
		if (X2Condition_RevivalProtocol(AbilityTemplate.AbilityTargetConditions[i]) != none)
		{
			AbilityTemplate.AbilityTargetConditions.Remove(i, 1);
		}
	}
	AbilityTemplate.AbilityTargetConditions.AddItem(new class'X2Condition_RevivalProtocol_Fixed');

	// ## Remove the poorly coded effect that always tops up the unit at 2 standard action points
	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_RestoreActionPoints(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
		}
	}
	// And replace it with the effect that isn't applied if the unit is just disorented.
	GiveStandardActionPoints = new class'X2Effect_GiveStandardActionPoints';
	GiveStandardActionPoints.TargetConditions.AddItem(new class'X2Condition_RevivalProtocolAP');
	AbilityTemplate.AddTargetEffect(GiveStandardActionPoints);

	// ## Remove stun from unit
	RemoveStunned = new class'X2Effect_RemoveEffects';
	RemoveStunned.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	AbilityTemplate.AddTargetEffect(RemoveStunned);

	// Give unit AP equal to the amount consumed by stun at the start of this turn
	AbilityTemplate.AddTargetEffect(new class'X2Effect_StunRecover');
}

static private function PatchRevival()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_GiveStandardActionPoints GiveStandardActionPoints;
	local X2Effect_RemoveEffects			RemoveStunned;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('RestorativeMist');
	if (AbilityTemplate == none)	
		return;

	// ## Remove the poorly coded effect that always tops up the unit at 2 standard action points
	for (i = AbilityTemplate.AbilityMultiTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_RestoreActionPoints(AbilityTemplate.AbilityMultiTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityMultiTargetEffects.Remove(i, 1);
		}
	}

	// And replace it with the effect that isn't applied if the unit is just disorented.
	GiveStandardActionPoints = new class'X2Effect_GiveStandardActionPoints';
	GiveStandardActionPoints.TargetConditions.AddItem(new class'X2Condition_RevivalProtocolAP');
	AbilityTemplate.AddMultiTargetEffect(GiveStandardActionPoints);

	// ## Remove stun from unit
	RemoveStunned = new class'X2Effect_RemoveEffects';
	RemoveStunned.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	AbilityTemplate.AddMultiTargetEffect(RemoveStunned);

	// Give unit AP equal to the amount consumed by stun at the start of this turn
	AbilityTemplate.AddMultiTargetEffect(new class'X2Effect_StunRecover');
}

static private function PatchCombatProtocol()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('CombatProtocol');
	if (AbilityTemplate == none)	
		return;

	AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);
	MakeNotEndTurn(AbilityTemplate);
}

static private function PatchAidProtocol()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('AidProtocol');
	if (AbilityTemplate == none)	
		return;

	AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);
}

static private function PatchGremlinHeal()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityCharges_GremlinHeal_Fixed GremilinHealCharges;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('GremlinHeal');
	if (AbilityTemplate == none)	
		return;

	AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);

	GremilinHealCharges = new class'X2AbilityCharges_GremlinHeal_Fixed';
	GremilinHealCharges.InitialCharges = `GetConfigInt("IRI_SP_MedicalProtocol_InitialCharges");
	AbilityTemplate.AbilityCharges = GremilinHealCharges;
}
static private function PatchGremlinStabilize()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityCharges_GremlinHeal_Fixed GremilinHealCharges;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('GremlinStabilize');
	if (AbilityTemplate == none)	
		return;

	AddActionPointNameToActionCost(AbilityTemplate, default.GremlinActionPoint);

	GremilinHealCharges = new class'X2AbilityCharges_GremlinHeal_Fixed';
	GremilinHealCharges.InitialCharges = `GetConfigInt("IRI_SP_MedicalProtocol_InitialCharges");
	AbilityTemplate.AbilityCharges = GremilinHealCharges;
}



defaultproperties
{
	GremlinActionPoint = "IRI_Gremlin_Action_Point"
}
