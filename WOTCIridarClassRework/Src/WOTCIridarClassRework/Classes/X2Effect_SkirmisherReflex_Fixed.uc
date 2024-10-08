class X2Effect_SkirmisherReflex_Fixed extends X2Effect_SkirmisherReflex;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', SkirmisherReflexListener, ELD_OnStateSubmitted, 40, ,, EffectObj); // Reduced priority to make it trigger after Return Fire.
}

static private function EventListenerReturn SkirmisherReflexListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Effect EffectGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local UnitValue ReflexValue, TotalValue;
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameState_Ability AbilityState;
	local bool bActionGiven;

	EffectGameState = XComGameState_Effect(CallbackData);
	if (EffectGameState == none)
		return ELR_NoInterrupt;
	
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	if (AbilityContext.InputContext.PrimaryTarget.ObjectID != EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
			return ELR_NoInterrupt;

	`AMLOG("Initial checks done");

	SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID)); // For some reason this started failing once I reduced listener priority.
	if (SourceUnit == none)
	{
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		`AMLOG("Got source unit from history:" @ SourceUnit.GetFullName());
	}
	else
	{
		`AMLOG("Got source unit:" @ SourceUnit.GetFullName());
	}
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	// Set to only Offensive abilities to prevent Reflex from being kicked off on Chosen Tracking Shot Marker.
	AbilityState = XComGameState_Ability(EventData);
	`AMLOG("Triggered by ability:" @ AbilityState.GetMyTemplateName());
	if (AbilityState == none || !AbilityState.GetMyTemplate().TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState) || AbilityState.GetMyTemplate().Hostility != eHostility_Offensive)
		return ELR_NoInterrupt;

	`AMLOG("SourceUnit is dead:" @ SourceUnit.IsDead() @ "interruption status:" @ AbilityContext.InterruptionStatus);
		
	if (SourceUnit.IsDead() || AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt) // - Allow triggering during interrupt stage against dead units so that even if the enemy is killed by Return Fire, you still get the Reflex point.
	{
			TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
			if (TargetUnit == none)
				TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
			if (TargetUnit == none)
				return ELR_NoInterrupt;

			if (TargetUnit.IsFriendlyUnit(SourceUnit))
				return ELR_NoInterrupt;

			TargetUnit.GetUnitValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, TotalValue);
			if (TotalValue.fValue >= 1)
				return ELR_NoInterrupt;

			//	if it's the target unit's current turn, give them an action immediately
			if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID == TargetUnit.ControllingPlayer.ObjectID)
			{
				if (TargetUnit.IsAbleToAct())
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skirmisher Reflex Immediate Action");
					TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));

					// TotalEarnedValue is not used for anything in the reworked effect, but keep it around in case some other mod needs it for something else.
					TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue.fValue + 1, eCleanup_BeginTurn);
					TargetUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);

					bActionGiven = true;
				}
			}
			//	if it's not their turn, increment the counter for next turn
			else
			{
				TargetUnit.GetUnitValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, ReflexValue);
				if (ReflexValue.fValue == 0)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skirmisher Reflex For Next Turn Increment");
					TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));

					// Use Begin Tactical here. ModifyTurnStartActionPoints() will clean this unit value anyway, but until it's used up, we need to preserve it, so it doesn't tick away during Skirmisher Interrupt.
					TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, 1, eCleanup_BeginTactical); 
					TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue.fValue + 1, eCleanup_BeginTurn);
					
					bActionGiven = true;
				}
			}

			if (NewGameState != none && bActionGiven)
			{
				NewGameState.ModifyStateObject(class'XComGameState_Ability', EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID);
				// XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = class'XComGameState_Effect'.static.TriggerAbilityFlyoverVisualizationFn;
				`TACTICALRULES.SubmitGameState(NewGameState);

				GameState.GetContext().PostBuildVisualizationFn.AddItem(TriggerReflexFlyover_PostBuildVisualization);
			}
	}
	return ELR_NoInterrupt;
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	// Do nothing during Skirmisher Interrupt, we can't grant AP there, because Interrupt will wipe away all AP before giving its own.
	if (UnitState.IsUnitAffectedByEffectName(class'X2Effect_SkirmisherInterrupt'.default.EffectName) || UnitState.IsUnitAffectedByEffectName(class'X2Effect_Battlelord'.default.EffectName))
		return;

	super.ModifyTurnStartActionPoints(UnitState, ActionPoints, EffectState);
}

static private function TriggerReflexFlyover_PostBuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability	AbilityContext;
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local XComGameStateHistory			History;
	local XComGameState_Unit			UnitState;
	local VisualizationActionMetadata	ActionMetadata;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameState_Ability			AbilityState;
	local StateObjectReference			AbilityRef;
	local XComGameStateVisualizationMgr	VisMgr;
	local array<X2Action>				LeafNodes;
	local string						strFlyoverText;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	History = `XCOMHISTORY;

	History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState,, VisualizeGameState.HistoryIndex);
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

	// Use +1 Action Next Turn flyover if it's not this unit's turn
	if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID != UnitState.ControllingPlayer.ObjectID)
	{
		AbilityRef = UnitState.FindAbility('SkirmisherReflex');
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState == none)
			return;

		AbilityTemplate = AbilityState.GetMyTemplate();
		if (AbilityTemplate == none)
			return;

		strFlyoverText = AbilityTemplate.LocFlyOverText;
	}
	else
	{
		// Otherwise use +1 Action THIS Turn
		strFlyoverText = class'Skirmisher'.default.strReflexThisTurnFlyover;
	}	

	VisMgr = `XCOMVISUALIZATIONMGR;
	VisMgr.GetAllLeafNodes(VisMgr.VisualizationTree, LeafNodes);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false,, LeafNodes));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, strFlyoverText, '', eColor_Good, AbilityTemplate.IconImage, `DEFAULTFLYOVERLOOKATTIME, true);
}
