class X2Condition_RevivalProtocol_Fixed extends X2Condition_RevivalProtocol;

// Same as original, but allows targeting stunned units and any friendly units, not just XCOM soldiers.

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (!TargetUnit.GetMyTemplate().bCanBeRevived || TargetUnit.IsBeingCarried() )
		return 'AA_UnitIsImmune';

	if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDisoriented() || TargetUnit.IsDazed() || TargetUnit.IsStunned()) // RM/Iridar - allow stunned units.
		return 'AA_Success';

	return 'AA_UnitIsNotImpaired';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);

	if (SourceUnit == none || TargetUnit == none)
		return 'AA_NotAUnit';

	//if (SourceUnit.ControllingPlayer == TargetUnit.ControllingPlayer)
	//	return 'AA_Success';
	
	if (SourceUnit.IsFriendlyUnit(TargetUnit)) //RM/Iridar: this will catch eTeam_Resistance in addition to XCOM
		return 'AA_Success';

	return 'AA_UnitIsHostile';
}