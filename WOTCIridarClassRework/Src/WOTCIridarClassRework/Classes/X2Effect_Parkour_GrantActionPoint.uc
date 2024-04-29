class X2Effect_Parkour_GrantActionPoint extends X2Effect_Persistent;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	if (AbilityContext.InputContext.AbilityTemplateName == 'SkirmisherGrapple')
	{
		SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
	}
	return false;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_SK_X2Effect_Parkour_GrantActionPoint_Effect"
}
