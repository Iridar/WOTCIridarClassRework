class X2Effect_SH_DeathFromAbove extends X2Effect_DeathFromAbove;

var private name ValueName;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local XComGameStateHistory		History;
	local XComGameState_Unit		TargetUnit;
	local XComGameState_Unit		PrevTargetUnit;
	local X2EventManager			EventMgr;
	local XComGameState_Ability		AbilityState;
	local UnitValue					UV;

	//  if under the effect of Serial, let that handle restoring the full action cost
	if (SourceUnit.IsUnitAffectedByEffectName(class'X2Effect_Serial'.default.EffectName))
		return false;

	if (SourceUnit.GetUnitValue(ValueName, UV))
		return false;

	History = `XCOMHISTORY;
	//  check for a direct kill shot with height advantage
	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit != None)
	{
		PrevTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));      //  get the most recent version from the history rather than our modified (attacked) version
		if (TargetUnit.IsDead() && PrevTargetUnit != None && SourceUnit.HasHeightAdvantageOver(PrevTargetUnit, true))
		{
			//  Check if the attack cost us action points.
			if (!AbilityArraysMatch(SourceUnit.ActionPoints, PreCostActionPoints))
			{
				AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
				if (AbilityState != none)
				{
					SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);

					EventMgr = `XEVENTMGR;
					EventMgr.TriggerEvent('DeathFromAbove', AbilityState, SourceUnit, NewGameState);

					SourceUnit.SetUnitFloatValue(ValueName, 1.0f, eCleanup_BeginTurn);

					return false; // return false to allow further processing by other abilities
				}
			}
		}
	}

	return false;
}

static private function bool AbilityArraysMatch(array<name> ArrayA, array<name> ArrayB)
{
	local int i;
	local int Index;

	for (i = ArrayA.Length - 1; i >= 0; i--)
	{
		Index = ArrayB.Find(ArrayA[i]);
		if (Index == INDEX_NONE)
			return false;

		ArrayA.Remove(i, 1);
		ArrayB.Remove(Index, 1);
	}
	return ArrayA.Length == 0 && ArrayB.Length == 0;
}

defaultproperties
{
	ValueName = "IRI_SH_DeathFromAbove_Value"
}