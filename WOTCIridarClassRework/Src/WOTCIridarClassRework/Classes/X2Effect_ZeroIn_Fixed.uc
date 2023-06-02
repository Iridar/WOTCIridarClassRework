class X2Effect_ZeroIn_Fixed extends X2Effect_ZeroIn;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_BaseObject TargetUnit;
	local X2EventManager EventMgr;
	local Object EffectObj;

	TargetUnit = `XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);
	if (TargetUnit == none)
		return;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', ZeroInListener, ELD_OnStateSubmitted,, TargetUnit,, EffectObj);
}

static private function EventListenerReturn ZeroInListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Effect EffectGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit TargetState;
	local UnitValue UValue;
	local UnitValue TargetUValue;
	local name ValueName;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	if (AbilityState.GetMyTemplate().Hostility != eHostility_Offensive)
		return ELR_NoInterrupt;

	EffectGameState = XComGameState_Effect(CallbackData);
	if (EffectGameState == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	TargetState = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetState == none)
		return ELR_NoInterrupt;

	ValueName = GetUnitValueName(UnitState.ObjectID);
		
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ZeroIn Increment");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.GetUnitValue(ValueName, UValue);
	UnitState.SetUnitFloatValue(ValueName, UValue.fValue + 1);

	TargetState = XComGameState_Unit(NewGameState.ModifyStateObject(TargetState.Class, TargetState.ObjectID));
	TargetState.GetUnitValue(ValueName, TargetUValue);
	TargetState.SetUnitFloatValue(ValueName, TargetUValue.fValue + 1);

	if (UnitState.ActionPoints.Length > 0 || UnitState.ReserveActionPoints.Length > 0)
	{
		//	show flyover for boost, but only if they have actions left to potentially use them
		NewGameState.ModifyStateObject(class'XComGameState_Ability', EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID);		//	create this for the vis function
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = EffectGameState.TriggerAbilityFlyoverVisualizationFn;
	}
	SubmitNewGameState(NewGameState);
	
	return ELR_NoInterrupt;
}

static private function name GetUnitValueName(const int ObjectID)
{
	return name("ZeroInShots" $ ObjectID);
}

static private function SubmitNewGameState(out XComGameState NewGameState)
{
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		TacticalRules = `TACTICALRULES;
		TacticalRules.SubmitGameState(NewGameState);
	}
	else
	{
		History = `XCOMHISTORY;
		History.CleanupPendingGameState(NewGameState);
	}
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;
	local UnitValue ShotsValue;
	local UnitValue TargetValue;
	local name ValueName;

	if (bIndirectFire)
		return;

	ValueName = GetUnitValueName(Attacker.ObjectID);

	Attacker.GetUnitValue(ValueName, ShotsValue);
	Target.GetUnitValue(ValueName, TargetValue);
		
	if (ShotsValue.fValue > 0)
	{
		ShotMod.ModType = eHit_Crit;
		ShotMod.Reason = FriendlyName;
		ShotMod.Value = ShotsValue.fValue * default.CritPerShot;
		ShotModifiers.AddItem(ShotMod);
	}

	if (TargetValue.fValue > 0)
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Reason = FriendlyName;
		ShotMod.Value = ShotsValue.fValue * default.LockedInAimPerShot;
		ShotModifiers.AddItem(ShotMod);
	}
}