class X2Effect_Battlelord_CombatPresence extends X2Effect_Battlelord_Fixed;

// Same as original, but remove the effect once the unit spends their action.

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'ExhaustedActionPoints', class'XComGameState_Effect'.static.BattlelordListener, ELD_OnStateSubmitted);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != none)
	{
		EventMgr.RegisterForEvent(EffectObj, 'ExhaustedActionPoints', OnExhaustedActionPoints, ELD_Immediate,, UnitState,, EffectObj);
	}
}

static private function EventListenerReturn OnExhaustedActionPoints(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
	local XComGameState_Effect EffectState;

	EffectState = XComGameState_Effect(CallbackObject);
	if (EffectState != none)
	{
		EffectState.RemoveEffect(NewGameState, NewGameState, true);
	}

    return ELR_NoInterrupt;
}
