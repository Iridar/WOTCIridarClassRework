class X2Effect_Serial_AimPenalty extends X2Effect_Persistent;

//var int AimPenaltyPerShot;
var float DamagePenaltyPerShot;

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

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local UnitValue UV;
	local int Penalty;

	if (AbilityState.SourceWeapon.ObjectID != EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
		return 0; 

	if (Attacker.GetUnitValue(default.EffectName, UV))
	{
		Penalty = DamagePenaltyPerShot * UV.fValue;
		if (CurrentDamage + Penalty < 1)
			Penalty = CurrentDamage - 1;

		return Penalty;
	}
	return 0; 
}


//function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
//{
//	local UnitValue UV;
//	local ShotModifierInfo ShotMod;
//
//	if (Attacker.GetUnitValue(default.EffectName, UV))
//	{
//		ShotMod.ModType = eHit_Success;
//		ShotMod.Value = UV.fValue * AimPenaltyPerShot;
//		ShotMod.Reason = FriendlyName;
//		ShotModifiers.AddItem(ShotMod);
//	}
//}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_SH_X2Effect_Serial_AimPenalty_Effect"

	iNumTurns = 1
	bInfiniteDuration = true
	bRemoveWhenSourceDies = true
	WatchRule = eGameRule_TacticalGameStart
}
