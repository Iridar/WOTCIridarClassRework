class X2Effect_TriggerSuppressionShot extends X2Effect;

var private X2Condition_Visibility VisibilityCondition;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Unit SourceUnit;

	UnitState = XComGameState_Unit(kNewTargetState);
	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	
	if (UnitState != none && (!UnitState.CanTakeCover() || 
								SourceUnit != none &&
								VisibilityCondition.MeetsCondition(UnitState) == 'AA_Success' && 
								VisibilityCondition.MeetsConditionWithSource(UnitState, SourceUnit) == 'AA_Success'))
	{
		`XEVENTMGR.TriggerEvent('IRI_GN_TriggerSuppression', UnitState, UnitState, NewGameState);
	}
}

defaultproperties
{
	Begin Object Class=X2Condition_Visibility Name=DefaultGameplayVisibilityCondition
		//bRequireGameplayVisible = true
		//bRequireBasicVisibility = true
		bRequireMatchCoverType = true
		TargetCover = CT_None
	End Object
	VisibilityCondition = DefaultGameplayVisibilityCondition;
}
