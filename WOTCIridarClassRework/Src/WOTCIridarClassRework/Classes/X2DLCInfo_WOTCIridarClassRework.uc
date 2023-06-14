class X2DLCInfo_WOTCIridarClassRework extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	PatchSkirmisherAmbush();
	PatchManualOverride();
	PatchSkirmisherMelee();
	PatchSkirmisherInterrupt();
	PatchFullThrottle();
	PatchZeroIn();
	PatchSkirmisherReflex();
	PatchBattlelord();
	PatchWhiplash();
	PatchParkour();
}

static private function PatchSkirmisherAmbush()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ModifyReactionFire       ReactionFire;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherAmbush');
	if (AbilityTemplate == none)	
		return;

	ReactionFire = new class'X2Effect_ModifyReactionFire';
	ReactionFire.bAllowCrit = true;
	ReactionFire.BuildPersistentEffect(1, true, true, true);
	AbilityTemplate.AddTargetEffect(ReactionFire);
}

static private function PatchManualOverride()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_Persistent				PersistentEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ManualOverride');
	if (AbilityTemplate == none)	
		return;

	RemoveActionCost(AbilityTemplate);
	AddFreeActionCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("ManualOverride_Cooldown"));

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_ManualOverride(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			PersistentEffect = new class'X2Effect_Persistent';
			PersistentEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
			PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyHelpText(), AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			PersistentEffect.EffectAddedFn = ManualOverride_EffectAdded;
			PersistentEffect.EffectRemovedFn = ManualOverride_EffectRemoved;
			AbilityTemplate.AddTargetEffect(PersistentEffect);

			break;
		}
	}
}

static private function ManualOverride_EffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local array<name>				AbilityNames;
	local name						AbilityName;
	local XComGameState_Unit		UnitState;
	local StateObjectReference		AbilityRef;
	local XComGameState_Ability		AbilityState;
	local XComGameStateHistory		History;
	local name						ValueName;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == none)
		return;

	History = `XCOMHISTORY;
	AbilityNames = `GetConfigArrayName("ManualOverride_Abilities");

	foreach AbilityNames(AbilityName)
	{
		AbilityRef = UnitState.FindAbility(AbilityName);
		if (AbilityRef.ObjectID <= 0)
			continue;

		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState == none)
			continue;

		ValueName = name(AbilityState.GetMyTemplateName() @ "_IRI_MO_Cooldown");
		UnitState.SetUnitFloatValue(ValueName, AbilityState.iCooldown, eCleanup_BeginTactical);

		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
		AbilityState.iCooldown = 0;
	}
}
static private function ManualOverride_EffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local array<name>				AbilityNames;
	local name						AbilityName;
	local XComGameState_Unit		UnitState;
	local StateObjectReference		AbilityRef;
	local XComGameState_Ability		AbilityState;
	local XComGameStateHistory		History;
	local name						ValueName;	
	local UnitValue					UV;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
		return;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

	AbilityNames = `GetConfigArrayName("ManualOverride_Abilities");

	foreach AbilityNames(AbilityName)
	{
		AbilityRef = UnitState.FindAbility(AbilityName);
		if (AbilityRef.ObjectID <= 0)
			continue;

		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState == none)
			continue;

		ValueName = name(AbilityState.GetMyTemplateName() @ "_IRI_MO_Cooldown");
		if (!UnitState.GetUnitValue(ValueName, UV))
			continue;

		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
		AbilityState.iCooldown = UV.fValue - 1;
		if (AbilityState.iCooldown < 0)
			AbilityState.iCooldown = 0;

		UnitState.ClearUnitValue(ValueName);
	}
}

static private function PatchSkirmisherMelee()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityCost_ActionPoints        ActionPointCost;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherMelee');
	if (AbilityTemplate == none)	
		return;

	// Firaxis forgot (?) to change the icon, so it looks like slash.
	AbilityTemplate.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Reckoning";

	AbilityTemplate.AbilityCooldown = none;
	AddCooldown(AbilityTemplate, `GetConfigInt("Reckoning_Cooldown"));

	RemoveActionCost(AbilityTemplate);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bMoveCost = true;
	ActionPointCost.bConsumeAllPoints = false;
	AbilityTemplate.AbilityCosts.AddItem(ActionPointCost);
}

static private function PatchFullThrottle()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ReduceCooldown			ReduceCooldown;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('FullThrottle');
	if (AbilityTemplate == none)
		return;

	ReduceCooldown = new class'X2Effect_ReduceCooldown';
	ReduceCooldown.AbilityName = 'SkirmisherGrapple';
	ReduceCooldown.ReduceCooldown = `GetConfigInt("FullThrottle_CooldownReduction");;
	AbilityTemplate.AddTargetEffect(ReduceCooldown);
}

static private function PatchZeroIn()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ZeroIn_Fixed				ZeroInEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ZeroIn');
	if (AbilityTemplate == none)
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_ZeroIn(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			ZeroInEffect = new class'X2Effect_ZeroIn_Fixed';
			ZeroInEffect.BuildPersistentEffect(1, true, false, false);
			ZeroInEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyHelpText(), AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(ZeroInEffect);

			break;
		}
	}
}



static private function PatchSkirmisherInterrupt()
{
	local X2AbilityTemplateManager					AbilityMgr;
	local X2AbilityTemplate							AbilityTemplate;
	local X2Effect_ReserveOverwatchPoints_NoCost	ReserveOverwatchPoints;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherInterruptInput');
	if (AbilityTemplate == none)
		return;

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Interrupt_Cooldown"));

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_ReserveOverwatchPoints(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			ReserveOverwatchPoints = new class'X2Effect_ReserveOverwatchPoints_NoCost';
			ReserveOverwatchPoints.UseAllPointsWithAbilities.Length = 0;
			ReserveOverwatchPoints.ReserveType = 'ReserveInterrupt';
			AbilityTemplate.AddTargetEffect(ReserveOverwatchPoints);

			break;
		}
	}
}

static private function PatchSkirmisherReflex()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_SkirmisherReflex_Fixed	ReflexEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherReflex');
	if (AbilityTemplate == none)
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_SkirmisherReflex(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			ReflexEffect = new class'X2Effect_SkirmisherReflex_Fixed';
			ReflexEffect.BuildPersistentEffect(1, true, false, false);
			ReflexEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(ReflexEffect);

			break;
		}
	}
}

static private function PatchBattlelord()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Battlelord');
	if (AbilityTemplate == none)
		return;

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Battlelord_Cooldown"));
}


static private function PatchParkour()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate; 
	local X2Effect_GrantActionPoints		AddActionPointsEffect;
	local X2AbilityTrigger_EventListener	ActivationTrigger;
	local X2Effect							Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Parkour');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.AbilityTriggers.Length = 0;
	ActivationTrigger = new class'X2AbilityTrigger_EventListener';
	ActivationTrigger.ListenerData.EventID = 'IRI_SkirmisherGrappleActivated';
	ActivationTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	ActivationTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	ActivationTrigger.ListenerData.Filter = eFilter_Unit;
	AbilityTemplate.AbilityTriggers.AddItem(ActivationTrigger);

	foreach AbilityTemplate.AbilityShooterEffects(Effect)
	{
		AddActionPointsEffect = X2Effect_GrantActionPoints(Effect);
		if (AddActionPointsEffect == none)
			continue;

		AddActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;
	}

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherGrapple');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.PostActivationEvents.AddItem('IRI_SkirmisherGrappleActivated');
}

static private function PatchWhiplash()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local X2Condition_UnitProperty		OnlyOrganic;
	local X2Condition_UnitProperty		OnlyRobotic;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Whiplash');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.DefaultSourceItemSlot = eInvSlot_SecondaryWeapon;

	X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).BuiltInHitMod -= 20;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		DamageEffect = X2Effect_ApplyWeaponDamage(AbilityTemplate.AbilityTargetEffects[i]);
		if (DamageEffect == none)
			continue;

		if (DamageEffect.EffectDamageValue == class'X2Ability_SkirmisherAbilitySet'.default.WHIPLASH_BASEDAMAGE)
		{	
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
		}
	}

	OnlyOrganic = new class'X2Condition_UnitProperty';
	OnlyOrganic.ExcludeRobotic = true;
	OnlyOrganic.ExcludeOrganic = false;

	OnlyRobotic = new class'X2Condition_UnitProperty';
	OnlyRobotic.ExcludeRobotic = false;
	OnlyRobotic.ExcludeOrganic = true;

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'Whiplash';
	DamageEffect.TargetConditions.AddItem(OnlyOrganic);
	AbilityTemplate.AddTargetEffect(DamageEffect);

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'Whiplash_Robotic';
	DamageEffect.TargetConditions.AddItem(OnlyRobotic);
	AbilityTemplate.AddTargetEffect(DamageEffect);

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Whiplash_Cooldown"));
	
}

static private function RemoveChargeCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	AbilityTemplate.AbilityCharges = none;

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_Charges(AbilityTemplate.AbilityCosts[i]) != none)
		{
			AbilityTemplate.AbilityCosts.Remove(i, 1);
		}
	}
}

static private function RemoveActionCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	AbilityTemplate.AbilityCharges = none;

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[i]) != none)
		{
			AbilityTemplate.AbilityCosts.Remove(i, 1);
		}
	}
}

static private function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}

static function AddFreeActionCost(out X2AbilityTemplate Template)
{
	local X2AbilityCost_ActionPoints ActionPointCost;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
}