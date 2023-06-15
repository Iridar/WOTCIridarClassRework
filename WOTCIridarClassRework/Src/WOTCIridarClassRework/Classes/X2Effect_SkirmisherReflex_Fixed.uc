class X2Effect_SkirmisherReflex_Fixed extends X2Effect_SkirmisherReflex;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', SkirmisherReflexListener, ELD_OnStateSubmitted,, ,, EffectObj);
}

// Same as original, just replaced eCleanup_BeginTactical with eCleanup_BeginTurn
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

	AbilityState = XComGameState_Ability(EventData);
	// Set to only Offensive abilities to prevent Reflex from being kicked off on Chosen Tracking Shot Marker.
	if (AbilityState.IsAbilityInputTriggered() && AbilityState.GetMyTemplate().Hostility == eHostility_Offensive)
	{
		AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
		if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
		{
			if (AbilityContext.InputContext.PrimaryTarget.ObjectID == EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
			{
				SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
				if (SourceUnit == none)
					return ELR_NoInterrupt;

				TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
				if (TargetUnit == none)
					TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
				if (TargetUnit == none)
					return ELR_NoInterrupt;

				if (TargetUnit.IsFriendlyUnit(SourceUnit))
					return ELR_NoInterrupt;

				TargetUnit.GetUnitValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue);
				if (TotalValue.fValue >= 1)
					return ELR_NoInterrupt;

				//	if it's the target unit's current turn, give them an action immediately
				if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID == TargetUnit.ControllingPlayer.ObjectID)
				{
					if (TargetUnit.IsAbleToAct())
					{
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skirmisher Reflex Immediate Action");
						TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
						TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue.fValue + 1, eCleanup_BeginTurn);
						TargetUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);

						bActionGiven = true;
					}
				}
				//	if it's not their turn, increment the counter for next turn
				else if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID != TargetUnit.ControllingPlayer.ObjectID)
				{
					TargetUnit.GetUnitValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, ReflexValue);
					if (ReflexValue.fValue == 0)
					{
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skirmisher Reflex For Next Turn Increment");
						TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
						TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, 1, eCleanup_BeginTurn);
						TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue.fValue + 1, eCleanup_BeginTurn);
					
						bActionGiven = true;
					}
				}

				if (NewGameState != none && bActionGiven)
				{
					NewGameState.ModifyStateObject(class'XComGameState_Ability', EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID);
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = class'XComGameState_Effect'.static.TriggerAbilityFlyoverVisualizationFn;
					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
		}
	}
	
	return ELR_NoInterrupt;
}