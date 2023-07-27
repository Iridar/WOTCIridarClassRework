class Grenadier extends Common;

static final function PatchAbilities()
{
	PatchBlastPadding();
	PatchSaturationFire();
	PatchChainShot();
	//PatchSuppression();
	PatchSuppressionShot();
}

static private function PatchSuppression()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Suppression');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.AddTargetEffect(new class'X2Effect_TriggerSuppressionShot');
}

static private function PatchSuppressionShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim	ToHitCalc;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_ApplyWeaponDamage		StockEffect;
	local X2Effect_RemoveEffects			RemoveEffects;
	local X2AbilityTrigger					AbilityTrigger;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SuppressionShot');
	if (AbilityTemplate == none)	
		return;

	// Ensure weapon upgrade compat
	AbilityTemplate.bAllowAmmoEffects = true;
	AbilityTemplate.bAllowBonusWeaponEffects = true;
	AbilityTemplate.bAllowFreeFireWeaponUpgrade = true;

	StockEffect = new class'X2Effect_ApplyWeaponDamage';
	StockEffect.bApplyOnHit = false;
	StockEffect.bApplyOnMiss = true;
	StockEffect.bIgnoreBaseDamage = true;
	StockEffect.DamageTag = 'Miss';
	StockEffect.bAllowWeaponUpgrade = true;
	StockEffect.bAllowFreeKill = false;
	StockEffect.TargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());
	AbilityTemplate.AddTargetEffect(StockEffect);

	// Patch the original on-move listener with a custom EventFn that will remove the suppression effect if the suppression is triggered
	//foreach AbilityTemplate.AbilityTriggers(AbilityTrigger)
	//{
	//	Trigger = X2AbilityTrigger_EventListener(AbilityTrigger);
	//	if (Trigger == none)
	//		continue;
	//
	//	if (Trigger.ListenerData.EventID == 'ObjectMoved')
	//	{
	//		Trigger.ListenerData.EventFn = SuppressionShotMoveListener;
	//		break;
	//	}
	//}

	// Trigger on ability activation too
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalAttackListener;
	AbilityTemplate.AbilityTriggers.AddItem(Trigger);

	// Trigger immediately against units that aren't in cover.
	//Trigger = new class'X2AbilityTrigger_EventListener';
	//Trigger.ListenerData.EventID = 'IRI_GN_TriggerSuppression';
	//Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	//Trigger.ListenerData.Filter = eFilter_None;
	//Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.ChainShotListener;
	//AbilityTemplate.AbilityTriggers.AddItem(Trigger);
	
	// Make Suppression not remove itself after the shot.
	//for (i = AbilityTemplate.AbilityShooterEffects.Length - 1; i >= 0; i--)
	//{
	//	RemoveEffects = X2Effect_RemoveEffects(AbilityTemplate.AbilityShooterEffects[i]);
	//	if (RemoveEffects == none)
	//		continue;
	//
	//	if (RemoveEffects.EffectNamesToRemove.Find(class'X2Effect_Suppression'.default.EffectName) != INDEX_NONE)
	//	{	
	//		AbilityTemplate.AbilityShooterEffects.Remove(i, 1);
	//	}
	//}

	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if (ToHitCalc == none)
		return;

	ToHitCalc.bIgnoreCoverBonus = true;

	//AbilityTemplate.PostActivationEvents.AddItem('IRI_GN_SuppressionActivated');
}

static private function EventListenerReturn OverwatchShot_AttackListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit			TargetUnit;
	local XComGameStateContext_Ability	AbilityContext;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameStateHistory			History;
	local StateObjectReference			EffectRef;
	local XComGameState					NewGameState;
	local XComGameState_Ability			AbilityState;
	local XComGameState_Effect			EffectState;
	local XComGameState_Unit			SourceUnit;
	local bool							bRemoveEffect;
	local bool							bSuppressionShotFired;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(EventSource);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
	if (AbilityTemplate == none || AbilityTemplate.Hostility != eHostility_Offensive)
		return ELR_NoInterrupt;
	
	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	if (AbilityState.CanActivateAbilityForObserverEvent(TargetUnit) == 'AA_Success')
	{
		bSuppressionShotFired = AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);
	}

	History = `XCOMHISTORY;
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	if (TargetUnit.IsDead())
	{
		bRemoveEffect = true;
	}
	else if (bSuppressionShotFired && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		// Remove the Suppression effect from target, but only after the interruption step so that the Suppression's aim penalty
		// has a chance to apply to the ability that triggered the suppression shot.
		bRemoveEffect = true;
	}

	
	//foreach TargetUnit.AffectedByEffects(EffectRef)
	//{
	//	EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
	//	if (EffectState == none || EffectState.bRemoved)
	//		continue;
	//
	//	if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID != AbilityState.OwnerStateObject.ObjectID)
	//		continue;
	//
	//	if (EffectState.GetX2Effect().EffectName != class'X2Effect_Suppression'.default.EffectName)
	//		continue;
	//
	//	EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
	//	NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
	//	EffectState.RemoveEffect(NewGameState, NewGameState);
	//	`GAMERULES.SubmitGameState(NewGameState);
	//	break;
	//}

	return ELR_NoInterrupt;
}

static private function EventListenerReturn SuppressionShotMoveListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit					TargetUnit;
	local XComGameState_Unit					SourceUnit;
	local XComGameState_Unit					ChainStartTarget;
	local XComGameState_Ability					AbilityState;
	local XComGameState_Effect					EffectState;
	local XComGameStateContext_Ability			AbilityContext;
	local XComGameStateHistory					History;
	local int									ChainStartIndex;
	local name									EffectName;
	local StateObjectReference					EffectRef;
	local XComGameState							NewGameState;
	local PathingInputData						MovementPath;
	local TTile									UncoveredTile;
	local XComGameStateContext_EffectRemoved	EffectRemovedContext;

	TargetUnit = XComGameState_Unit(EventData);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none)
	{
		if (class'X2Ability_DefaultAbilitySet'.default.OverwatchIgnoreAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE)
			return ELR_NoInterrupt;
	}

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	// Check effects on target unit at the start of this chain.
	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	//if (AbilityState.CanActivateAbilityForObserverEvent(TargetUnit, SourceUnit) != 'AA_Success')
	//	return ELR_NoInterrupt;

	ChainStartIndex = History.GetEventChainStartIndex();
	if (ChainStartIndex != INDEX_NONE)
	{
		ChainStartTarget = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID, , ChainStartIndex));
		foreach class'X2Ability_DefaultAbilitySet'.default.OverwatchExcludeEffects(EffectName)
		{
			if (ChainStartTarget.IsUnitAffectedByEffectName(EffectName))
			{
				return ELR_NoInterrupt;
			}
		}
	}

	//// If target can take cover
	//if (TargetUnit.CanTakeCover())
	//{
	//	foreach AbilityContext.InputContext.MovementPaths(MovementPath)
	//	{
	//		if (MovementPath.MovingUnitRef.ObjectID != TargetUnit.ObjectID)
	//			continue;
	//	
	//		// And will eventually move out of cover
	//		if (GetUncoveredTileOnPath(SourceUnit, MovementPath, UncoveredTile))
	//		{
	//			// But is not currently at that location
	//			if (TargetUnit.TileLocation != UncoveredTile)
	//			{
	//				// Delay the suppression shot until it is.
	//				return ELR_NoInterrupt;
	//			}
	//		}
	//		break;
	//	}
	//}

	AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);

	if (AbilityContext.InputContext.MovementPaths[0].MovementTiles[AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1] == TargetUnit.TileLocation)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
		NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID);
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = ResuppressTarget_BuildVisualization;
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).SetDesiredVisualizationBlockIndex(GameState.HistoryIndex);

		`AMLOG("Resuppressing target at history index:" @ GameState.HistoryIndex);
		`GAMERULES.SubmitGameState(NewGameState);

	}
	
	// Remove the suppression effect due to target moving.
	//foreach TargetUnit.AffectedByEffects(EffectRef)
	//{
	//	EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
	//	if (EffectState == none || EffectState.bRemoved)
	//		continue;
	//
	//	if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID != AbilityState.OwnerStateObject.ObjectID)
	//		continue;
	//
	//	if (EffectState.GetX2Effect().EffectName != class'X2Effect_Suppression'.default.EffectName)
	//		continue;
	//
	//	EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
	//	NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
	//	EffectState.RemoveEffect(NewGameState, NewGameState);
	//	`GAMERULES.SubmitGameState(NewGameState);
	//	break;
	//}

	return ELR_NoInterrupt;
}

static private function ResuppressTarget_BuildVisualization(XComGameState VisualizeGameState)
{	
	local XComGameState					SuppressionGameState;
	local XComGameState					SuppressionGameStateExt;
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability	AbilityContext;
	local VisualizationActionMetadata	ActionMetadata;
	local X2Action_EnterCover			Action;

	`AMLOG("Running for history index:" @ VisualizeGameState.GetContext().DesiredVisualizationBlockIndex);

	History = `XCOMHISTORY;

	SuppressionGameState = History.GetGameStateFromHistory(VisualizeGameState.GetContext().DesiredVisualizationBlockIndex);
	if (SuppressionGameState == none)
		return;

	`AMLOG("Got the game state");

	AbilityContext = XComGameStateContext_Ability(SuppressionGameState.GetContext());
	if (AbilityContext == none)
		return;

	`AMLOG("Got the context");

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID);

	//class'X2Action_StopSuppression'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded);

	class'X2Action_StopSuppression'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded);
	Action = X2Action_EnterCover(class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));

	SuppressionGameStateExt = History.GetGameStateFromHistory(XComGameState_Unit(ActionMetadata.StateObject_NewState).m_SuppressionHistoryIndex);
	`AMLOG("Got suppression game state for exit cover:" @ SuppressionGameStateExt != none);
	Action.AbilityContext = XComGameStateContext_Ability(SuppressionGameStateExt.GetContext());

	//class'X2Action_StartSuppression'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded);

	class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded);
	class'X2Action_StartSuppression'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded);
}

static private function bool GetUncoveredTileOnPath(const XComGameState_Unit SourceUnit, out const PathingInputData MovementPath, out TTile TestTile)
{
	local X2GameRulesetVisibilityManager		VisibilityMgr;
	local array<GameRulesCache_VisibilityInfo>	ViewerInfos;
	local GameRulesCache_VisibilityInfo			ViewerInfo;

	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	foreach MovementPath.MovementTiles(TestTile)
	{
		VisibilityMgr.GetAllViewersOfLocation(TestTile, ViewerInfos, class'XComGameState_Unit');
		foreach ViewerInfos(ViewerInfo)
		{
			if (ViewerInfo.SourceID != SourceUnit.ObjectID)
				continue;

			if (ViewerInfo.TargetCover == CT_None)
			{
				return true;
			}
		}

	}
	return false;
}

static private function PatchChainShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityTemplate					AbilityTemplate2;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc2;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ChainShot');
	AbilityTemplate2 = AbilityMgr.FindAbilityTemplate('ChainShot2');
	if (AbilityTemplate == none || AbilityTemplate2 == none)	
		return;

	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	ToHitCalc2 = X2AbilityToHitCalc_StandardAim(AbilityTemplate2.AbilityToHitCalc);
	if (ToHitCalc == none || ToHitCalc2 == none)	
		return;

	ToHitCalc2.BuiltInHitMod = ToHitCalc.BuiltInHitMod;
	ToHitCalc.BuiltInHitMod = 0;
}

static private function PatchSaturationFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ReliableWorldDamage		WorldDamage;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SaturationFire');
	if (AbilityTemplate == none)	
		return;

	EnsureWeaponUpgradeInteraction(AbilityTemplate);

	WorldDamage = new class'X2Effect_ReliableWorldDamage';
	WorldDamage.DamageAmount = `GetConfigInt("IRI_GN_SaturationFire_Reliable_EnvDamage");
	WorldDamage.ApplyChance = class'X2Ability_GrenadierAbilitySet'.default.SATURATION_DESTRUCTION_CHANCE;
	WorldDamage.bSkipGroundTiles = true;
	AbilityTemplate.AddMultiTargetEffect(WorldDamage);
}

static private function PatchBlastPadding()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_BlastPaddingExtended		PaddingEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('BlastPadding');
	if (AbilityTemplate == none)	
		return;

	PaddingEffect = new class'X2Effect_BlastPaddingExtended';
	PaddingEffect.ExplosiveDamageReduction = class'X2Ability_GrenadierAbilitySet'.default.BLAST_PADDING_DMG_ADJUST;
	PaddingEffect.BuildPersistentEffect(1, true, false);
	PaddingEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyHelpText(), AbilityTemplate.IconImage, false,, AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(PaddingEffect);
}
