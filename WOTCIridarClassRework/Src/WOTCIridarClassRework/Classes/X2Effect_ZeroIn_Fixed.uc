class X2Effect_ZeroIn_Fixed extends X2Effect_ZeroIn;

var const name UnitValueName;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_BaseObject TargetUnit;
	local X2EventManager EventMgr;
	local Object EffectObj;

	TargetUnit = `XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);
	if (TargetUnit == none)
		return;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', ZeroInListener, ELD_OnStateSubmitted,, TargetUnit,, EffectObj);
}

static private function EventListenerReturn ZeroInListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Effect	EffectGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState			NewGameState;
	local XComGameState_Unit	UnitState;
	//local XComGameState_Item	SourceWeapon;
	local UnitValue				UValue;
	local X2AbilityTemplate		AbilityTemplate;
	local XComGameState_Unit	TargetUnit;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	// Only unit-targeted abilities
	//if (AbilityContext.InputContext.PrimaryTarget.ObjectID <= 0)
	//	return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none || AbilityTemplate.Hostility != eHostility_Offensive)
		return ELR_NoInterrupt;

	// Only weapon abilities
	//SourceWeapon = AbilityState.GetSourceWeapon();
	//if (SourceWeapon == none)
	//	return ELR_NoInterrupt;

	//if (X2WeaponTemplate(SourceWeapon.GetMyTemplate()) == none)
	//	return ELR_NoInterrupt;

	EffectGameState = XComGameState_Effect(CallbackData);
	if (EffectGameState == none)
		return ELR_NoInterrupt;

	// Only primary weapon or melee abilities
	if (EffectGameState.ApplyEffectParameters.ItemStateObjectRef.ObjectID != AbilityState.SourceWeapon.ObjectID && !AbilityState.IsMeleeAbility())
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	// Only against enemy units
	TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit == none || !UnitState.IsEnemyUnit(UnitState))
		return ELR_NoInterrupt;

	// Only damaging abilities
	if (!AbilityState.GetMyTemplate().TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState))
		return ELR_NoInterrupt;
		
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ZeroIn Increment");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.GetUnitValue(default.UnitValueName, UValue);
	UnitState.SetUnitFloatValue(default.UnitValueName, UValue.fValue + 1, eCleanup_BeginTactical); // Unit Value cleansed at the end of turn by EffectTickedFn

	//	show flyover for boost, but only if they have actions left to potentially use them
	if (UnitState.ActionPoints.Length > 0 || AbilityHasReserveActionCost(AbilityTemplate))
	{
		NewGameState.ModifyStateObject(class'XComGameState_Ability', EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID);		//	create this for the vis function
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = EffectGameState.TriggerAbilityFlyoverVisualizationFn;
	}
	SubmitNewGameState(NewGameState);
	
	return ELR_NoInterrupt;
}

static private function bool AbilityHasReserveActionCost(const X2AbilityTemplate Template)
{
	local X2AbilityCost Cost;
	local X2AbilityCost_ReserveActionPoints	ActionPointCost;

	foreach Template.AbilityCosts(Cost)
	{
		ActionPointCost = X2AbilityCost_ReserveActionPoints(Cost);
		if (ActionPointCost == none || ActionPointCost.bFreeCost)
			continue;

		return true;
	}
	return false;
}

static private function SubmitNewGameState(out XComGameState NewGameState)
{
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		TacticalRules = `TACTICALRULES;
		TacticalRules.SubmitGameState(NewGameState);
	}
	else
	{
		History = `XCOMHISTORY;
		History.CleanupPendingGameState(NewGameState);
	}
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;
	local UnitValue ShotsValue;

	if (bIndirectFire)
		return;

	Attacker.GetUnitValue(UnitValueName, ShotsValue);
		
	if (ShotsValue.fValue > 0)
	{
		ShotMod.ModType = eHit_Crit;
		ShotMod.Reason = FriendlyName;
		ShotMod.Value = ShotsValue.fValue * default.CritPerShot;
		ShotModifiers.AddItem(ShotMod);

		ShotMod.ModType = eHit_Success;
		ShotMod.Reason = FriendlyName;
		ShotMod.Value = ShotsValue.fValue * default.LockedInAimPerShot;
		ShotModifiers.AddItem(ShotMod);
	}
}

function bool AllowReactionFireCrit(XComGameState_Unit UnitState, XComGameState_Unit TargetState) 
{ 
	return true; 
}

// So that the buff chevron shows up only if there are any stacks on the unit
function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{ 
	local UnitValue UV;

	return TargetUnit.GetUnitValue(UnitValueName, UV);
}

// Remove the unit value when the effect ticks at the end of turn.
// This is done so that the Zero In stacks from Overwatch shots can last into the next turn.
private function bool ZeroInEffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.ClearUnitValue(UnitValueName);
	}
	return false;
}

defaultproperties
{
	UnitValueName = "ZeroInShots"
	EffectTickedFn = ZeroInEffectTicked
}
