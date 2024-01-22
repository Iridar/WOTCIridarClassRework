class X2Effect_Serial_AimPenalty extends X2Effect_Persistent;

var int CritChancePenaltyPerShot;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != none)
	{
		EventMgr.RegisterForEvent(EffectObj, 'SerialKiller', OnSerialKiller, ELD_Immediate,, UnitState);	
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{ 
	local UnitValue UV;
	
	return TargetUnit.GetUnitValue(EffectName, UV);
}

static private function EventListenerReturn OnSerialKiller(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit UnitState;
	local UnitValue			 UV;
		
	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (UnitState == none)
		return ELR_NoInterrupt;

	UnitState.GetUnitValue(default.EffectName, UV);
	UnitState.SetUnitFloatValue(default.EffectName, UV.fValue + 1, eCleanup_BeginTurn);
	
    return ELR_NoInterrupt;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local UnitValue			UV;
	local ShotModifierInfo	ShotInfo;

	if (AbilityState.SourceWeapon.ObjectID != EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
		return;

	if (!Attacker.GetUnitValue(default.EffectName, UV))
		return;

	ShotInfo.Value = CritChancePenaltyPerShot * UV.fValue;
	ShotInfo.ModType = eHit_Crit;
	ShotInfo.Reason = FriendlyName;
	ShotModifiers.AddItem(ShotInfo);
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_SH_X2Effect_Serial_AimPenalty_Effect"

	iNumTurns = 1
	bInfiniteDuration = true
	bRemoveWhenSourceDies = true
	WatchRule = eGameRule_TacticalGameStart
}
