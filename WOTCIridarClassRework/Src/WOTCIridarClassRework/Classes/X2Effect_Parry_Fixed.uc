class X2Effect_Parry_Fixed extends X2Effect_Parry;

function bool ChangeHitResultForTarget(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, bool bIsPrimaryTarget, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult)
{
	local UnitValue ParryUnitValue;
	local bool bDeflectReflect;

	if (!TargetUnit.IsAbleToAct())
		return false;

	`log("X2Effect_Parry::ChangeHitResultForTarget", , 'XCom_HitRolls');

	bDeflectReflect = ChangeHitResultForTarget_DeflectReflect(EffectState, Attacker, TargetUnit, AbilityState, bIsPrimaryTarget, CurrentResult, NewHitResult);
	if (bDeflectReflect)
		return false;

	//	check for parry if deflect or reflect didn't happen - if the unit value is set, then a parry is guaranteed
	if (TargetUnit.GetUnitValue('Parry', ParryUnitValue))
	{
		if (ParryUnitValue.fValue > 0)
		{
			`log("Parry available - using!", , 'XCom_HitRolls');
			NewHitResult = eHit_Parry;
			TargetUnit.SetUnitFloatValue('Parry', ParryUnitValue.fValue - 1);
			return true;
		}
	}
	
	`log("Parry not available.", , 'XCom_HitRolls');
	return false;
}

function bool ChangeHitResultForTarget_DeflectReflect(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, bool bIsPrimaryTarget, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult)
{
	local int FocusLevel, Chance, RandRoll;
	local X2AbilityToHitCalc_StandardAim AttackToHit;

	//	don't respond to reaction fire
	AttackToHit = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);
	if (AttackToHit != none && AttackToHit.bReactionFire)
		return false;

	`log("X2Effect_Deflect::ChangeHitResultForTarget", , 'XCom_HitRolls');
	//	//	check for parry first - if the unit value is set, then a parry effect will process deflect and reflect.
	//	if (TargetUnit.HasSoldierAbility('Parry') && TargetUnit.GetUnitValue('Parry', ParryUnitValue))
	//	{
	//		if (ParryUnitValue.fValue > 0)
	//		{
	//			`log("Parry is available - not triggering deflect or reflect!", , 'XCom_HitRolls');
	//			return false;
	//		}		
	//	}

	//	only parry can block melee abilities, so only check non-melee abilities
	if (AbilityState.IsMeleeAbility() || !bIsPrimaryTarget)
	{
		`log("Ability is a melee attack or an AOE attack - cannot be Reflected or Deflected.", , 'XCom_HitRolls');
		return false;
	}
	
	FocusLevel = TargetUnit.GetTemplarFocusLevel();

	//	check reflect first
	if (TargetUnit.HasSoldierAbility('Reflect') && FocusLevel >= class'X2Effect_Deflect'.default.ReflectMinFocus)
	{
		Chance = class'X2Effect_Deflect'.default.ReflectBaseChance + ((FocusLevel - 1) * class'X2Effect_Deflect'.default.DeflectPerFocusChance);
		RandRoll = `SYNC_RAND(100);
		if (RandRoll <= Chance)
		{
			`log("Reflect chance was" @ Chance @ "rolled" @ RandRoll @ "- success!", , 'XCom_HitRolls');
			NewHitResult = eHit_Reflect;
			return true;
		}
		`log("Reflect chance was" @ Chance @ "rolled" @ RandRoll @ "- failed. Cannot Reflect.", , 'XCom_HitRolls');
	}
	`log("Unit does not have Reflect, or not enough Focus to trigger it.", , 'XCom_HitRolls');


	//	if reflect didn't happen, check for deflect
	if (FocusLevel >= class'X2Effect_Deflect'.default.DeflectMinFocus)
	{
		Chance = class'X2Effect_Deflect'.default.DeflectBaseChance + ((FocusLevel - 1) * class'X2Effect_Deflect'.default.DeflectPerFocusChance);
		RandRoll = `SYNC_RAND(100);
		if (RandRoll <= Chance)
		{
			`log("Deflect chance was" @ Chance @ "rolled" @ RandRoll @ "- success!", , 'XCom_HitRolls');
			NewHitResult = eHit_Deflect;
			return true;
		}
		`log("Deflect chance was" @ Chance @ "rolled" @ RandRoll @ "- failed.", , 'XCom_HitRolls');
	}
	else
	{
		`log("Unit does not have enough focus for Deflect.", , 'XCom_HitRolls');
	}
	

	return false;
}
