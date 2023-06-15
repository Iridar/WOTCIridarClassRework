class X2Effect_SkirmisherInterrupt_Fixed extends X2Effect_SkirmisherInterrupt;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	UnitState;
	local XComGameStateHistory	History;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_AIGroup	GroupState;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	GroupState = TargetUnit.GetGroupMembership();
	TargetUnit.SetUnitFloatValue('SkirmisherInterruptOriginalGroup', GroupState.ObjectID, eCleanup_BeginTactical);

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
	local XComGameState_Unit TargetUnit;
	local XComGameState_AIGroup GroupState;
	local UnitValue GroupValue;

	TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	GroupState = TargetUnit.GetGroupMembership();
	if (GroupState.m_arrMembers.Length == 1 && GroupState.m_arrMembers[0].ObjectID == TargetUnit.ObjectID)
	{
		NewGameState.RemoveStateObject(GroupState.ObjectID);
	}

	TargetUnit.GetUnitValue('SkirmisherInterruptOriginalGroup', GroupValue);
	GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GroupValue.fValue));
	GroupState.AddUnitToGroup(TargetUnit.ObjectID, NewGameState);
	TargetUnit.ClearUnitValue('SkirmisherInterruptOriginalGroup');
}
