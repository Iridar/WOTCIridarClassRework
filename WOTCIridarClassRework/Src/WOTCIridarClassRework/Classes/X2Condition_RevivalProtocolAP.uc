class X2Condition_RevivalProtocolAP extends X2Condition;

// Checks if Revival Protocol should restore unit's AP.
// Copied from RM who copied it from pledbrook of LWOTC.

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local XComGameState_Unit TargetUnit;

    TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

    // Only allow action points to be restored for units that aren't disoriented
    // (stunned is handled by X2Effect_StunRecover).
	// Iridar addendum: this has no right to work, the effects should've been removed already when these conditions are evaluated. Makes no sense.
	if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDazed())
        return 'AA_Success';

    return 'AA_UnitIsNotImpaired';
}
