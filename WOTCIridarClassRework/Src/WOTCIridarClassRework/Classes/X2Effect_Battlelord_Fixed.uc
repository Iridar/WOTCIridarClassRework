class X2Effect_Battlelord_Fixed extends X2Effect_Battlelord;

//var private const name UnitHadInterrupValue;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMan;
	local Object EffectObj;

	EventMan = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMan.RegisterForEvent(EffectObj, 'ExhaustedActionPoints', class'XComGameState_Effect'.static.BattlelordListener, ELD_OnStateSubmitted);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	UnitState;
	local XComGameStateHistory	History;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_AIGroup	GroupState;
	//local int					iNumInterrupts;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none)
		return;

	GroupState = TargetUnit.GetGroupMembership();
	if (GroupState == none)
		return;

	// Soldier has Interrupt 
	//if (TargetUnit.HasSoldierAbility('SkirmisherInterrupt'))
	//{
	//	iNumInterrupts = TargetUnit.NumReserveActionPoints(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	//	// And used it before activating Battlelord
	//	if (iNumInterrupts > 0)
	//	{
	//		// Remember how many interrupts they had (assuming more than one is even possible and would work correctly)
	//		TargetUnit.SetUnitFloatValue('UnitHadInterrupValue', iNumInterrupts, eCleanup_BeginTactical);
	//
	//		// Then take away all Interrupt action points, otherwise Battlelord and Interrupt will attempt to activate together,
	//		// causing buuuuuuuugs
	//		TargetUnit.ReserveActionPoints.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	//	}
	//}

	TargetUnit.SetUnitFloatValue('BattlelordOriginalGroup', GroupState.ObjectID, eCleanup_BeginTactical);

	// ---- Start New Code ---
	// Search for other units on the same team also affected by the Interrupt effect,
	// and if there are any, add the TargetUnit to the same group.
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (!UnitState.IsUnitAffectedByEffectName(EffectName))
			continue;

		if (UnitState.IsDead() || !UnitState.IsInPlay())
			continue;

		if (UnitState.GetTeam() != TargetUnit.GetTeam())
			continue;

		GroupState = UnitState.GetGroupMembership();
		if (GroupState == none)
			continue;

		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(GroupState.Class, GroupState.ObjectID));	
		GroupState.AddUnitToGroup(TargetUnit.ObjectID, NewGameState);
		return;
	}
	// ---- End New Code ---

	GroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));
	GroupState.AddUnitToGroup(TargetUnit.ObjectID, NewGameState);
	GroupState.bSummoningSicknessCleared = true;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit	TargetUnit;
	local XComGameState_AIGroup	GroupState;
	local UnitValue				GroupValue;

	TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit != none && TargetUnit.GetUnitValue('BattlelordOriginalGroup', GroupValue))
	{
		GroupState = TargetUnit.GetGroupMembership();
		if (GroupState.m_arrMembers.Length == 1 && GroupState.m_arrMembers[0].ObjectID == TargetUnit.ObjectID)
		{
			NewGameState.RemoveStateObject(GroupState.ObjectID);
		}

		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GroupValue.fValue));
		GroupState.AddUnitToGroup(TargetUnit.ObjectID, NewGameState);
		TargetUnit.ClearUnitValue('BattlelordOriginalGroup');
	}
}

//function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
//{
//	local UnitValue UV;
//
//	super.ModifyTurnStartActionPoints(UnitState, ActionPoints, EffectState);
//
//	// If unit used Interrupt prior to activating Battlelord, give them an extra action for every Interrupt.
//	if (UnitState.GetUnitValue(UnitHadInterrupValue, UV))
//	{
//		ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
//		UV.fValue = UV.fValue - 1;
//		if (int(UV.fValue) <= 0)
//		{
//			UnitState.ClearUnitValue(UnitHadInterrupValue);
//		}
//		else
//		{
//			UnitState.SetUnitFloatValue(UnitHadInterrupValue, UV.fValue, UV.eCleanup);			
//		}
//	}
//}

//defaultproperties
//{
//	UnitHadInterrupValue = "IRI_SK_Battlelord_Interrupt_Value"
//}