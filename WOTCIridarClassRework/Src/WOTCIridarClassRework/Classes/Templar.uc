class Templar extends Common;

static final function PatchAbilities()
{
	//PatchVoidConduit();
}

static private function PatchVoidConduit()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect_PersistentVoidConduit_Fixed	PersistentEffect;
	local X2Effect_VoidConduit				TickEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('VoidConduit');
	if (Template == none)	
		return;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);
		}
	}

	//	build the persistent effect
	PersistentEffect = new class'X2Effect_PersistentVoidConduit_Fixed';
	PersistentEffect.InitialDamage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitInitialDamage;
	PersistentEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false, , Template.AbilitySourceName);
	PersistentEffect.bRemoveWhenTargetDies = true;
	//	build the per tick damage effect
	TickEffect = new class'X2Effect_VoidConduit';
	TickEffect.DamagePerAction = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage;
	TickEffect.HealthReturnMod = class'X2Ability_TemplarAbilitySet'.default.VoidConduitHPMod;
	PersistentEffect.ApplyOnTick.AddItem(TickEffect);
	Template.AddTargetEffect(PersistentEffect);
}
