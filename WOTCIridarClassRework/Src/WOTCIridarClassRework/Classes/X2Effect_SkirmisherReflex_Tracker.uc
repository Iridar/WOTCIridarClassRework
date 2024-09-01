class X2Effect_SkirmisherReflex_Tracker extends X2Effect_Persistent;

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	local UnitValue UV;

	return TargetUnit.GetUnitValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, UV);
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_SkirmisherReflex_Tracker_Effect"
}