class X2Effect_RetainOverwatchOnDamage extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (UnitState != none)
	{
		EffectObj = EffectGameState;
		EventMgr = `XEVENTMGR;
		EventMgr.RegisterForEvent(EffectObj, 'OverrideDamageRemovesReserveActionPoints', OnOverrideDamageRemovesReserveActionPoints, ELD_Immediate,, UnitState,, EffectObj);	
		EventMgr.RegisterForEvent(EffectObj, 'X2Effect_RetainOverwatchOnDamage_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
	}
}

static private function EventListenerReturn OnOverrideDamageRemovesReserveActionPoints(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
    local XComGameState_Unit	UnitState;
    local XComLWTuple			Tuple;
	local X2EventManager		EventMgr;
	local XComGameState_Effect	EffectState;
	local XComGameState_Ability	AbilityState;

    UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none || UnitState.IsDead())
		return ELR_NoInterrupt;

    Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackObject);
	if (EffectState != none)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState != none)
		{
			EventMgr = `XEVENTMGR;
			EventMgr.TriggerEvent('X2Effect_RetainOverwatchOnDamage_Event', AbilityState, UnitState, NewGameState);
		}
	}

    Tuple.Data[0].b = false;

    return ELR_NoInterrupt;
}
