class X2Condition_CombatPresenceInterrupt extends X2Condition;

var bool bReverse;

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local XComGameState_Unit SourceUnit;
	local XComGameState_Unit TargetUnit;
	
	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);
	
	if (SourceUnit != none && TargetUnit != none)
	{
		if (SourceUnit.GetTeam() == TargetUnit.GetTeam())
		{
			if (SourceUnit.IsUnitAffectedByEffectName(class'X2Effect_SkirmisherInterrupt'.default.EffectName))
			{
				if (bReverse)
				{
					return 'AA_AbilityUnavailable';
				}
				return 'AA_Success'; 
			}
		}
	}
	
	if (bReverse)
	{
		return 'AA_Success';
	}
	return 'AA_AbilityUnavailable';
}
