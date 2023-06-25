class X2Effect_Battlelord_Fixed extends X2Effect_Battlelord;

//var private const name UnitHadInterrupValue;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMan;
	local Object EffectObj;
	local XComGameState_Ability AbilityState;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	EventMan = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMan.RegisterForEvent(EffectObj, 'ExhaustedActionPoints', BattlelordListener, ELD_OnStateSubmitted,, ,, AbilityState);
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
	local XComGameState_Ability	AbilityState;
	local UnitValue				BattlelordInterrupts;

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
			
		if (TargetUnit.GetUnitValue('BattlelordInterrupts', BattlelordInterrupts))
		{
			// Set the cooldown to be the same as the number of actions taken.
			// Doing so only in the event listener is not enough, because when the effect is removed at player turn start,
			// the cooldown will tick once, and will not be equal to the number of actions taken anymore.
			AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
			if (AbilityState == none)
			{
				AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
				if (AbilityState != none)
				{
					AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
				}
			}
			if (AbilityState != none)
			{
				AbilityState.iCooldown = BattlelordInterrupts.fValue;
			}

			TargetUnit.ClearUnitValue('BattlelordInterrupts');	
		}
	}
}

static private function EventListenerReturn BattlelordListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState					NewGameState;
	local X2TacticalGameRuleset			TacticalRules;
	local GameRulesCache_VisibilityInfo	VisInfo;
	local UnitValue						BattlelordInterrupts;
	local XComGameState_Ability			AbilityState;

	TargetUnit = XComGameState_Unit(EventData);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (SourceUnit == none || !SourceUnit.IsAbleToAct())
	{
		//`redscreen("@dkaplan: Skirmisher Battlelord interruption was prevented due to the Skirmisher being Unable to Act.");
		return ELR_NoInterrupt;
	}

	if (!SourceUnit.IsEnemyUnit(TargetUnit) || TargetUnit.GetTeam() == eTeam_TheLost)
		return ELR_NoInterrupt;

	TacticalRules = `TACTICALRULES;
	if (!TacticalRules.VisibilityMgr.GetVisibilityInfo(SourceUnit.ObjectID, TargetUnit.ObjectID, VisInfo))
		return ELR_NoInterrupt;
	
	if (!VisInfo.bClearLOS)
		return ELR_NoInterrupt;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Battlelord Interrupt Initiative");
	SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));

	SourceUnit.GetUnitValue('BattlelordInterrupts', BattlelordInterrupts);
	SourceUnit.SetUnitFloatValue('BattlelordInterrupts', BattlelordInterrupts.fValue + 1, eCleanup_BeginTactical);

	// Set the cooldown to the number of actions taken every time so the player can easily track it
	// and predict the cooldown
	AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
	AbilityState.iCooldown = BattlelordInterrupts.fValue + 1;

	TacticalRules.InterruptInitiativeTurn(NewGameState, SourceUnit.GetGroupMembership().GetReference());
	TacticalRules.SubmitGameState(NewGameState);
	
	return ELR_NoInterrupt;
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