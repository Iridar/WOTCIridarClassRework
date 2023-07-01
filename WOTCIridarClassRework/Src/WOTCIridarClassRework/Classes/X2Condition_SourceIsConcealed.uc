class X2Condition_SourceIsConcealed extends X2Condition;

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local XComGameState_Unit SourceUnit;
	
	SourceUnit = XComGameState_Unit(kSource);
	
	if (SourceUnit != none && SourceUnit.IsConcealed())
	{
		return 'AA_Success'; 
	}
	return 'AA_AbilityUnavailable';
}
