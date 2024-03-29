class Templar extends Common;

static final function PatchAbilities()
{
	PatchVoidConduit();
	PatchParryActivate();
	PatchStunStrike();
}

static private function PatchStunStrike()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('StunStrike');
	if (Template == none)	
		return;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Knockback(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);
		}

		if (X2Effect_Persistent(Template.AbilityTargetEffects[i]).EffectName == class'X2AbilityTemplateManager'.default.DisorientedName)
		{
			Template.AbilityTargetEffects.Remove(i, 1);
		}
	}

	Template.AbilityToHitCalc = default.DeadEye;

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, false));

	Template.AddTargetEffect(new class'X2Effect_ReliableKnockback');

	Template.AddTargetEffect(GetConcentrationEffect());
}

// Concentration effect doesn't exist in the Class Rework, only in the perk pack, so copy it from the new Rend ability template.
static private function X2Effect GetConcentrationEffect()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					RendTemplate;
	local X2Effect							ConcentrationEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	RendTemplate = AbilityMgr.FindAbilityTemplate('IRI_TM_Rend');
	if (RendTemplate == none)
		return none;

	for (i = RendTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Persistent(RendTemplate.AbilityTargetEffects[i]).EffectName == 'IRI_TM_Concentration_Effect')
		{
			ConcentrationEffect = RendTemplate.AbilityTargetEffects[i];

			return ConcentrationEffect;
		}
	}

	return none;
}

// Patch Parry to be uninterruptble and not offensive
static private function PatchParryActivate()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('ParryActivate');
	if (Template == none)	
		return;

	Template.Hostility = eHostility_Defensive;
	Template.BuildInterruptGameStateFn = none;
}

static private function PatchVoidConduit()
{
	local X2AbilityTemplateManager				AbilityMgr;
	local X2AbilityTemplate						Template;
	//local X2Effect_PersistentVoidConduit_Fixed	PersistentEffect;
	//local X2Effect_VoidConduit					TickEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('VoidConduit');
	if (Template == none)	
		return;

	// Remove AP cost and increase Focus cost
	for (i = Template.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_ActionPoints(Template.AbilityCosts[i]) != none)
		{
			X2AbilityCost_ActionPoints(Template.AbilityCosts[i]).bFreeCost = true;
			X2AbilityCost_ActionPoints(Template.AbilityCosts[i]).AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
		} 
		else if (X2AbilityCost_Focus(Template.AbilityCosts[i]) != none)
		{
			X2AbilityCost_Focus(Template.AbilityCosts[i]).FocusAmount = `GetConfigInt("IRI_TM_VoidConduit_FocusCost");
		}
	}

	// Remove cooldown.
	Template.AbilityCooldown = none;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]) != none)
		{
			X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).bInfiniteDuration = false;
			X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).WatchRule = eGameRule_PlayerTurnEnd;
			X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).iNumTurns = 1;
			X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).EffectTickedFn = none;
		}
	}

	//	build the persistent effect
	//PersistentEffect = new class'X2Effect_PersistentVoidConduit_Fixed';
	//PersistentEffect.InitialDamage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitInitialDamage;
	//PersistentEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	//PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false, , Template.AbilitySourceName);
	//PersistentEffect.bRemoveWhenTargetDies = true;
	//
	////	build the per tick damage effect
	//TickEffect = new class'X2Effect_VoidConduit';
	//TickEffect.DamagePerAction = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage;
	//TickEffect.HealthReturnMod = class'X2Ability_TemplarAbilitySet'.default.VoidConduitHPMod;
	//PersistentEffect.ApplyOnTick.AddItem(TickEffect);
	//Template.AddTargetEffect(PersistentEffect);

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	// No longer deals initial damage, so damage preview is unnecessary.
	Template.DamagePreviewFn = VoidConduitDamagePreview;

	Template.AddTargetEffect(GetConcentrationEffect());
}

static private function bool VoidConduitDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	MinDamagePreview.Damage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage * 2;
	MaxDamagePreview.Damage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage * 2;
	return true;
}
