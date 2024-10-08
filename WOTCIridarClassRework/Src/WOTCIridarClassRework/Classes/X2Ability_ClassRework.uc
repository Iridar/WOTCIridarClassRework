class X2Ability_ClassRework extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_RN_Shadowstrike_OnBreakConcealment());
	Templates.AddItem(PurePassive('IRI_RP_MakeshiftExplosives', "img:///IRIClassReworkUI.UIPerk_MakeshiftExplosives", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(IRI_SK_Whiplash_BonusDamage());

	return Templates;
}

static function X2AbilityTemplate IRI_SK_Whiplash_BonusDamage()
{
	local X2AbilityTemplate					Template;
	local X2Effect_SK_WhiplashBonusDamage	Effect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SK_Whiplash_BonusDamage');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowstrike";
	SetHidden(Template);
	SetPassive(Template);
		
	Effect = new class'X2Effect_SK_WhiplashBonusDamage';
	Effect.BuildPersistentEffect(1, true);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Localize("Whiplash X2AbilityTemplate", "LocFriendlyName", "XComGame"), Template.GetMyLongDescription(), Template.IconImage, false,,Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	return Template;
}

static function X2AbilityTemplate IRI_RN_Shadowstrike_OnBreakConcealment()
{
	local X2AbilityTemplate			Template;
	local X2Effect_ToHitModifier	Effect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_RN_Shadowstrike_OnBreakConcealment');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowstrike";
	SetHidden(Template);

	// High priority so that we get our bonuses even if we get concealment broken in the middle of another action.
	SetSelfTarget_WithEventTrigger(Template, 'UnitConcealmentBroken', ELD_OnStateSubmitted, eFilter_Unit, 100);

	Effect = new class'X2Effect_ToHitModifier';
	Effect.EffectName = 'IRI_RN_Shadowstrike_OnBreakConcealment';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, false,,, eGameRule_PlayerTurnEnd);
	//Effect.bDisplayInSpecialDamageMessageUI = true; // Works only when modifying damage.
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	Effect.AddEffectHitModifier(eHit_Success, class'X2Ability_RangerAbilitySet'.default.SHADOWSTRIKE_AIM, Template.LocFriendlyName);
	Effect.AddEffectHitModifier(eHit_Crit, class'X2Ability_RangerAbilitySet'.default.SHADOWSTRIKE_CRIT, Template.LocFriendlyName);
	Template.AddTargetEffect(Effect);

	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}


//	========================================
//				COMMON CODE
//	========================================

static function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}

static function AddCharges(out X2AbilityTemplate Template, int InitialCharges)
{
	local X2AbilityCharges		Charges;
	local X2AbilityCost_Charges	ChargeCost;

	if (InitialCharges > 0)
	{
		Charges = new class'X2AbilityCharges';
		Charges.InitialCharges = InitialCharges;
		Template.AbilityCharges = Charges;

		ChargeCost = new class'X2AbilityCost_Charges';
		ChargeCost.NumCharges = 1;
		Template.AbilityCosts.AddItem(ChargeCost);
	}
}

static function AddFreeCost(out X2AbilityTemplate Template)
{
	local X2AbilityCost_ActionPoints ActionPointCost;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
}

static function RemoveVoiceLines(out X2AbilityTemplate Template)
{
	Template.ActivationSpeech = '';
	Template.SourceHitSpeech = '';
	Template.TargetHitSpeech = '';
	Template.SourceMissSpeech = '';
	Template.TargetMissSpeech = '';
	Template.TargetKilledByAlienSpeech = '';
	Template.TargetKilledByXComSpeech = '';
	Template.MultiTargetsKilledByAlienSpeech = '';
	Template.MultiTargetsKilledByXComSpeech = '';
	Template.TargetWingedSpeech = '';
	Template.TargetArmorHitSpeech = '';
	Template.TargetMissedSpeech = '';
}

static function SetFireAnim(out X2AbilityTemplate Template, name Anim)
{
	Template.CustomFireAnim = Anim;
	Template.CustomFireKillAnim = Anim;
	Template.CustomMovingFireAnim = Anim;
	Template.CustomMovingFireKillAnim = Anim;
	Template.CustomMovingTurnLeftFireAnim = Anim;
	Template.CustomMovingTurnLeftFireKillAnim = Anim;
	Template.CustomMovingTurnRightFireAnim = Anim;
	Template.CustomMovingTurnRightFireKillAnim = Anim;
}

static function SetHidden(out X2AbilityTemplate Template)
{
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	
	//TacticalText is for mainly for item-granted abilities (e.g. to hide the ability that gives the armour stats)
	Template.bDisplayInUITacticalText = false;
	
	//	bDisplayInUITooltip isn't actually used in the base game, it should be for whether to show it in the enemy tooltip, 
	//	but showing enemy abilities didn't make it into the final game. Extended Information resurrected the feature  in its enhanced enemy tooltip, 
	//	and uses that flag as part of it's heuristic for what abilities to show, but doesn't rely solely on it since it's not set consistently even on base game abilities. 
	//	Anyway, the most sane setting for it is to match 'bDisplayInUITacticalText'. (c) MrNice
	Template.bDisplayInUITooltip = false;
	
	//Ability Summary is the list in the armoury when you're looking at a soldier.
	Template.bDontDisplayInAbilitySummary = true;
	Template.bHideOnClassUnlock = true;
}

static function X2AbilityTemplate Create_AnimSet_Passive(name TemplateName, string AnimSetPath)
{
	local X2AbilityTemplate                 Template;
	local X2Effect_AdditionalAnimSets		AnimSetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	
	AnimSetEffect = new class'X2Effect_AdditionalAnimSets';
	AnimSetEffect.AddAnimSetWithPath(AnimSetPath);
	AnimSetEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(AnimSetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function SetPassive(out X2AbilityTemplate Template)
{
	Template.bIsPassive = true;

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITacticalText = true;
	Template.bDisplayInUITooltip = true;
	Template.bDontDisplayInAbilitySummary = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
}

static function X2AbilityTemplate HiddenPurePassive(name TemplateName, optional string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard", optional bool bCrossClassEligible=false, optional Name AbilitySourceName='eAbilitySource_Perk', optional bool bDisplayInUI=true)
{
	local X2AbilityTemplate	Template;
	
	Template = PurePassive(TemplateName, TemplateIconImage, bCrossClassEligible, AbilitySourceName, bDisplayInUI);
	SetHidden(Template);
	
	return Template;
}

//	Use: SetSelfTarget_WithEventTrigger(Template, 'PlayerTurnBegun',, eFilter_Player);
static function	SetSelfTarget_WithEventTrigger(out X2AbilityTemplate Template, name EventID, optional EventListenerDeferral Deferral = ELD_OnStateSubmitted, optional AbilityEventFilter Filter = eFilter_None, optional int Priority = 50)
{
	local X2AbilityTrigger_EventListener Trigger;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = EventID;
	Trigger.ListenerData.Deferral = Deferral;
	Trigger.ListenerData.Filter = Filter;
	Trigger.ListenerData.Priority = Priority;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);
}

static function PrintActionRecursive(X2Action Action, int iLayer)
{
	local X2Action ChildAction;
	local XComGameState_Unit UnitState;
	local string strMessage;
	local X2Action_MarkerNamed MarkerAction;

	strMessage = "Action layer:" @ iLayer @ ":" @ Action.Class.Name;

	MarkerAction = X2Action_MarkerNamed(Action);
	if (MarkerAction != none)
	{
		strMessage @= MarkerAction.MarkerName;
	}

	UnitState = XComGameState_Unit(Action.Metadata.StateObject_NewState);
	if (UnitState != none)
	{
		strMessage @= UnitState.GetFullName();
	}
	strMessage @= Action.StateChangeContext.AssociatedState.HistoryIndex;
		
	`AMLOG(strMessage); 
	foreach Action.ChildActions(ChildAction)
	{
		PrintActionRecursive(ChildAction, iLayer + 1);
	}
}
