class X2Effect_UntouchableBuff extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local Object				EffectObj;
	local XComGameState_Unit	UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
		return;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'UnitDied', UntouchableCheck, ELD_OnStateSubmitted, 55, ,, EffectObj); // Slightly higher priority to run before the vanilla listener.
	EventMgr.RegisterForEvent(EffectObj, EffectName, EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, 40, UnitState);
}

static private function EventListenerReturn UntouchableCheck(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Effect			EffectState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState					NewGameState;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			DeadUnit;
	local XComGameStateHistory			History;
	local XComGameState_Ability			AbilityState;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none || EffectState.bRemoved)
		return ELR_NoInterrupt;


	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;
	
	if (AbilityContext.InputContext.SourceObject.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	DeadUnit = XComGameState_Unit(EventData);

	if (SourceUnit.IsEnemyUnit(DeadUnit) && (SourceUnit.Untouchable < class'X2Ability_RangerAbilitySet'.default.MAX_UNTOUCHABLE || class'X2Ability_RangerAbilitySet'.default.MAX_UNTOUCHABLE < 1))
	{
		// Trigger flyover
		
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		`XEVENTMGR.TriggerEvent(default.EffectName, AbilityState, SourceUnit, NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	return TargetUnit.Untouchable > 0; 
}

defaultproperties
{
	iNumTurns = 1
	bInfiniteDuration = true
	bRemoveWhenSourceDies = false
	bIgnorePlayerCheckOnTick = false

	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_RN_X2Effect_UntouchableBuff_Effect"
}