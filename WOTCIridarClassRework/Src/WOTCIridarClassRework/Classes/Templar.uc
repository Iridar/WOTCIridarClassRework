class Templar extends Common;

static final function PatchAbilities()
{
	PatchVoidConduit();
	PatchParryActivate();
	PatchStunStrike();
	PatchIonicStorm();
}

static private function PatchIonicStorm()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2AbilityTemplate					VolTemplate;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('IonicStorm');
	if (Template == none)	
		return;

	// Trigger Momentum
	Template.PostActivationEvents.AddItem('RendActivated');

	// Original preview increases displayed Ionic Storm's damage by Focus, but that mechanic is gone.
	Template.DamagePreviewFn = IonicStormDamagePreview;

	for (i = Template.AbilityMultiTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_ApplyWeaponDamage(Template.AbilityMultiTargetEffects[i]) != none)
		{
			if (X2Effect_ApplyWeaponDamage(Template.AbilityMultiTargetEffects[i]).DamageTag == 'IonicStorm')
			{
				X2Effect_ApplyWeaponDamage(Template.AbilityMultiTargetEffects[i]).DamageTag = 'IRI_TM_IonicStorm';
			}
			else
			if (X2Effect_ApplyWeaponDamage(Template.AbilityMultiTargetEffects[i]).DamageTag == 'IonicStorm_Psi')
			{
				X2Effect_ApplyWeaponDamage(Template.AbilityMultiTargetEffects[i]).DamageTag = 'IRI_TM_IonicStorm_Psi';
			}
		}
	}

	Template.AddMultiTargetEffect(GetConcentrationEffect());	

	VolTemplate = AbilityMgr.FindAbilityTemplate('IRI_TM_Volt');
	if (VolTemplate == none)	
		return;

	// Custom calc to force crits against Psionics for cosmetic effect.
	Template.AbilityToHitCalc = VolTemplate.AbilityToHitCalc;

	Template.BuildVisualizationFn = IonicStorm_BuildVisualization;
}

// Copy of the original with bCombineFlyovers set to false to make crit damage flyovers work.
static private function IonicStorm_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateVisualizationMgr VisMgr;
	local XComGameStateContext_Ability AbilityContext;
	local VisualizationActionMetadata SourceMetadata;
	local VisualizationActionMetadata ActionMetadata;
	local VisualizationActionMetadata BlankMetadata;
	local XGUnit SourceVisualizer;
	local X2Action_Fire FireAction;
	local X2Action_ExitCover ExitCoverAction;
	local StateObjectReference CurrentTarget;
	local int ScanTargets;
	local X2Action ParentAction;
	local X2Action_Delay CurrentDelayAction;
	local X2Action_ApplyWeaponDamageToUnit UnitDamageAction;
	local X2Effect CurrentEffect;
	local int ScanEffect;
	local Array<X2Action> LeafNodes;
	local X2Action_MarkerNamed JoinActions;
	local XComGameState_Effect_TemplarFocus FocusState;
	local int NumActualTargets;

	History = `XCOMHISTORY;
	VisMgr = `XCOMVISUALIZATIONMGR;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	SourceVisualizer = XGUnit(History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID));

	SourceMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceVisualizer.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(SourceVisualizer.ObjectID);
	SourceMetadata.StateObjectRef = AbilityContext.InputContext.SourceObject;
	SourceMetadata.VisualizeActor = SourceVisualizer;

	if( AbilityContext.InputContext.MovementPaths.Length > 0 )
	{
		class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, SourceMetadata);
	}

	ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceMetadata, AbilityContext, false, SourceMetadata.LastActionAdded));
	FireAction = X2Action_Fire(class'X2Action_Fire'.static.AddToVisualizationTree(SourceMetadata, AbilityContext, false, ExitCoverAction));
	class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceMetadata, AbilityContext, false, FireAction);

	FocusState = XComGameState_Unit(SourceMetadata.StateObject_OldState).GetTemplarFocusEffectState();
	// Jwats: We care about the focus that was used to cast this ability
	FocusState = XComGameState_Effect_TemplarFocus(History.GetGameStateForObjectID(FocusState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	NumActualTargets = AbilityContext.InputContext.MultiTargets.Length / FocusState.FocusLevel;

	ParentAction = FireAction;
	for (ScanTargets = 0; ScanTargets < AbilityContext.InputContext.MultiTargets.Length; ++ScanTargets)
	{
		CurrentTarget = AbilityContext.InputContext.MultiTargets[ScanTargets];
		ActionMetadata = BlankMetadata;

		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(CurrentTarget.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(CurrentTarget.ObjectID);
		ActionMetadata.StateObjectRef = CurrentTarget;
		ActionMetadata.VisualizeActor = History.GetVisualizer(CurrentTarget.ObjectID);

		if (ScanTargets == 0)
		{
			ParentAction = class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ParentAction);
		}
		else
		{
			CurrentDelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ParentAction));
			CurrentDelayAction.Duration = (`SYNC_FRAND_STATIC() * (class'X2Ability_TemplarAbilitySet'.default.IonicStormTargetMaxDelay - class'X2Ability_TemplarAbilitySet'.default.IonicStormTargetMinDelay)) + class'X2Ability_TemplarAbilitySet'.default.IonicStormTargetMinDelay;
			ParentAction = CurrentDelayAction;
		}

		UnitDamageAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ParentAction));
		for (ScanEffect = 0; ScanEffect < AbilityContext.ResultContext.MultiTargetEffectResults[ScanTargets].Effects.Length; ++ScanEffect)
		{
			if (AbilityContext.ResultContext.MultiTargetEffectResults[ScanTargets].ApplyResults[ScanEffect] == 'AA_Success')
			{
				CurrentEffect = AbilityContext.ResultContext.MultiTargetEffectResults[ScanTargets].Effects[ScanEffect];
				break;
			}
		}
		UnitDamageAction.OriginatingEffect = CurrentEffect;
		UnitDamageAction.bShowFlyovers = false;

		// Jwats: Only add death during the last apply weapon damage pass
		if (ScanTargets + NumActualTargets >= AbilityContext.InputContext.MultiTargets.Length)
		{
			UnitDamageAction.bShowFlyovers = true;
			//UnitDamageAction.bCombineFlyovers = true; 
			UnitDamageAction.bCombineFlyovers = false; // Iridar: this is literally the only place in code where this is used and it breaks the intended "critical hit" visualization. No idea what's the purpose of this and I don't care.
			XGUnit(ActionMetadata.VisualizeActor).BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}

	}

	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, LeafNodes);
	JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SourceMetadata, AbilityContext, false, , LeafNodes));
	JoinActions.SetName("Join");
}

static private function bool IonicStormDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	// Use the non-psionic damage effect for regular damage preview.
	AbilityState.GetMyTemplate().AbilityMultiTargetEffects[0].GetDamagePreview(TargetRef, AbilityState, false, MinDamagePreview, MaxDamagePreview, AllowsShield); 

	return true;
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
