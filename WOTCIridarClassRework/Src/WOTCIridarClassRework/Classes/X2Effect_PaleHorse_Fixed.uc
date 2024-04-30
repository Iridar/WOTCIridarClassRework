class X2Effect_PaleHorse_Fixed extends X2Effect_PaleHorse;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager	EventMgr;
	//local XComGameState_Unit UnitState;
	local Object			EffectObj;

	super.RegisterForEvents(EffectGameState);

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	//UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	// Done in the super.
	// EventMgr.RegisterForEvent(EffectObj, 'OnAPaleHorse', EffectState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	// EventMgr.RegisterForEvent(EffectObj, 'KillMail', EffectState.KillMailListener, ELD_OnStateSubmitted, , UnitState);

	EventMgr.RegisterForEvent(EffectObj, 'KilledByDestructible', DeathByBoomBoom, ELD_OnStateSubmitted,, ,, EffectGameState);
}

static private function EventListenerReturn DeathByBoomBoom(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Destructible		DestructibleState;
	local XComGameState_Effect_PaleHorse	EffectState;
	local XComGameState_Unit				OwnerUnit;
	local StateObjectReference				EffectIter;
	local XComGameStateHistory				History;
	local XComGameState_Effect				CheckEffect;

	`AMLOG("Running");

	EffectState = XComGameState_Effect_PaleHorse(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	`AMLOG("Have effect state");

	History = `XCOMHISTORY;
	OwnerUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (OwnerUnit == none)
	{
		OwnerUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	}
	if (OwnerUnit == none || OwnerUnit.IsDead())
		return ELR_NoInterrupt;

	`AMLOG("OwnerUnit:" @ OwnerUnit.GetFullName());
	
	DestructibleState = XComGameState_Destructible(EventSource);
	if (DestructibleState == none)
		return ELR_NoInterrupt;
		
	`AMLOG("Destructible:" @ DestructibleState.ObjectID);
	
	//  look for the matching Claymore effect
	foreach OwnerUnit.AppliedEffects(EffectIter)
	{
		CheckEffect = XComGameState_Effect(History.GetGameStateForObjectID(EffectIter.ObjectID));
		if (CheckEffect != none && CheckEffect.ApplyEffectParameters.ItemStateObjectRef.ObjectID == DestructibleState.ObjectID)
		{
			`AMLOG("Have matching effect, running KillMail");
			TriggerPaleHorse(EffectState);
			return ELR_NoInterrupt;
		}
	}

	return ELR_NoInterrupt;
}

static private function TriggerPaleHorse(XComGameState_Effect_PaleHorse EffectState)
{
	local X2Effect_PaleHorse	Effect;
	local XComGameState			NewGameState;
	local XComGameState_Ability	AbilityState;
	local XComGameState_Unit	UnitState;
	
	Effect = X2Effect_PaleHorse(EffectState.GetX2Effect());
	if (EffectState.CurrentCritBoost < Effect.MaxCritBoost)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Soul Harvester Crit Increase on Kill");
		EffectState = XComGameState_Effect_PaleHorse(NewGameState.ModifyStateObject(EffectState.Class, EffectState.ObjectID));
		EffectState.CurrentCritBoost += Effect.CritBoostPerKill;

		//	mark unit state and ability state for flyover
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		`XEVENTMGR.TriggerEvent('OnAPaleHorse', AbilityState, UnitState, NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ModInfo;
	local XComGameState_Effect_PaleHorse PaleHorseEffectState;
		
	PaleHorseEffectState = XComGameState_Effect_PaleHorse(EffectState);

	// Iridar: apply crit chance to everything, not just Vektor. Though Reapers don't have anything else that can crit in vanilla.
	// if (AbilityState.SourceWeapon == PaleHorseEffectState.ApplyEffectParameters.ItemStateObjectRef)
	// {
		ModInfo.ModType = eHit_Crit;
		ModInfo.Value = PaleHorseEffectState.CurrentCritBoost;
		ModInfo.Reason = FriendlyName;
		ShotModifiers.AddItem(ModInfo);
	// }
}
