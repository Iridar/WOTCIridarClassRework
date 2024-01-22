class X2Effect_DeepCover_Tracker extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Player PlayerState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.PlayerStateObjectRef.ObjectID));
	if (PlayerState == none)
		return;
	
	// Slightly higher priority to run before the vanilla 
	EventMgr.RegisterForEvent(EffectObj, 'PlayerTurnEnded', DeepCover_ArmorBonus_TurnEndListener, ELD_OnStateSubmitted, 55, PlayerState,, EffectObj);	
}

static private function EventListenerReturn DeepCover_ArmorBonus_TurnEndListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit	UnitState;
	local UnitValue				AttacksThisTurn;
	local StateObjectReference	HunkerDownRef;
	local XComGameState_Ability	HunkerDownState;
	local XComGameStateHistory	History;
	local XComGameState			NewGameState;
	local XComGameState_Effect	EffectState;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (UnitState == none || UnitState.IsHunkeredDown())
		return ELR_NoInterrupt;

	if (UnitState.GetUnitValue('AttacksThisTurn', AttacksThisTurn) && AttacksThisTurn.fValue != 0)
		return ELR_NoInterrupt;

	HunkerDownRef = UnitState.FindAbility('HunkerDown');
	HunkerDownState = XComGameState_Ability(History.GetGameStateForObjectID(HunkerDownRef.ObjectID));
	if (HunkerDownState != none && HunkerDownState.CanActivateAbility(UnitState,,true) == 'AA_Success')
	{
		// Deep Cover is about to activate. Mark the unit with a unit value to prevent them from gaining the Armor Bonus.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.SetUnitFloatValue('IRI_RN_DeepCover_ArmorBonus_Value', 1.0f, eCleanup_BeginTurn);
		`TACTICALRULES.SubmitGameState(NewGameState);
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
	EffectName = "IRI_RN_X2Effect_DeepCover_Tracker_Effect"
}