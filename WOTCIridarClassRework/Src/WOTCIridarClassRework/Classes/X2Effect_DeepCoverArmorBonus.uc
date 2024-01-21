class X2Effect_DeepCoverArmorBonus extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'X2Effect_DeepCoverArmorBonus_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	
	//	local X2EventManager EventMgr;
	//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('ABILITY_NAME').ObjectID));
	//	EventMgr = `XEVENTMGR;
	//	EventMgr.TriggerEvent('X2Effect_DeepCoverArmorBonus_Event', AbilityState, SourceUnit, NewGameState);
	
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', AbilityActivated_Listener, ELD_OnStateSubmitted,, UnitState);	
}

static function EventListenerReturn AbilityActivated_Listener(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameStateContext_Ability	AbilityContext;
		
	AbilityState = XComGameState_Ability(EventData);
	UnitState = XComGameState_Unit(EventSource);
	AbilityTemplate = AbilityState.GetMyTemplate();

	if (AbilityState.GetMyTemplateName() == 'HunkerDown')
	{
		`AMLOG("Hunker Down activated:" @ GameState.GetContext().Class.Name);
	}
	
    return ELR_NoInterrupt;
}

defaultproperties
{
	iNumTurns = 1
	bInfiniteDuration = true
	bRemoveWhenSourceDies = false
	bIgnorePlayerCheckOnTick = false

	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_RN_X2Effect_DeepCoverArmorBonus_Effect"
}