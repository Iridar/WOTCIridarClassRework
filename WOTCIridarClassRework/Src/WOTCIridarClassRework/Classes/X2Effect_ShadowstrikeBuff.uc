class X2Effect_ShadowstrikeBuff extends X2Effect_Persistent;

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	return TargetUnit.IsConcealed(); 
}

defaultproperties
{
	iNumTurns = 1
	bInfiniteDuration = true
	bRemoveWhenSourceDies = false
	bIgnorePlayerCheckOnTick = false

	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_RN_X2Effect_ShadowstrikeBuff_Effect"
}
