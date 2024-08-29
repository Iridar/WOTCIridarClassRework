class X2Effect_SuperConcealModifier_Fixed extends X2Effect_SuperConcealModifier;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (UnitState != none)
	{
		EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted, 10, UnitState,, EffectObj);	// Reduced priority so this runs after the concealment break roll
	}

	super.RegisterForEvents(EffectGameState);
}

static private function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Ability					AbilityState;
	local XComGameState							NewGameState;
	local XComGameState_Effect					EffectState;
	local XComGameStateContext_EffectRemoved	EffectRemovedContext;
	local XComGameStateContext_Ability			AbilityContext;
	local XComGameState_Unit					UnitState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;
		
	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	if (AbilityState.SourceWeapon.ObjectID != EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
		return ELR_NoInterrupt;

	// Don't remove the effect if the ability wouldn't break concealment anyway, e.g. when shooting a claymore
	if (AbilityState.RetainConcealmentOnActivation(AbilityContext))
		return ELR_NoInterrupt;

	// Remove Improvised Silencer effect
	EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, EffectRemovedContext);
	EffectState.RemoveEffect(NewGameState, NewGameState);			
	`AMLOG("Removing Imp. Silencer effect.");
	`TACTICALRULES.SubmitGameState(NewGameState);

	// Trigger flyover
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	UnitState = XComGameState_Unit(EventSource);
	if (AbilityState != none && UnitState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Improvised Silencer Flyover");

		NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID);
		NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID);
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = EffectState.TriggerAbilityFlyoverVisualizationFn;
		
		`AMLOG("Triggering Imp. Silencer flyover" @ AbilityState.GetMyTemplateName() @ AbilityState.GetMyTemplate().LocFlyOverText @ "for unit:" @ UnitState.GetFullName());

		`TACTICALRULES.SubmitGameState(NewGameState);
	}

    return ELR_NoInterrupt;
}


function bool AdjustSuperConcealModifier(XComGameState_Unit UnitState, XComGameState_Effect EffectState, XComGameState_Ability AbilityState, XComGameState RespondToGameState, const int BaseModifier, out int Modifier)
{
	// Improvised Silencer applies only to primary weapon attacks
	if (AbilityState.SourceWeapon.ObjectID != EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
		return false;

	`AMLOG("Activating:" @ AbilityState.GetMyTemplateName() @ `ShowVar(BaseModifier));

	Modifier = -BaseModifier;
	return true;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_SuperConcealModifier_Fixed_Effect"
}
