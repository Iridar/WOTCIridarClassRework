class X2DLCInfo_WOTCIridarClassRework extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	local CHHelpers CHHelpersObj;

	CHHelpersObj = class'CHHelpers'.static.GetCDO();
	if (CHHelpersObj != none)
	{
		CHHelpersObj.AddPrioritizeRightClickMeleeCallback(PrioritizeRightClickMelee);
	}

	class'Skirmisher'.static.PatchAbilities();
	class'Ranger'.static.PatchAbilities();
	class'Sharpshooter'.static.PatchAbilities();
	class'Grenadier'.static.PatchAbilities();
	class'Specialist'.static.PatchAbilities();
}

// --------------------------


// To avoid crashes associated with garbage collection failure when transitioning between Tactical and Strategy,
// this function must be bound to the ClassDefaultObject of your class. Having this function in a class that 
// `extends X2DownloadableContentInfo` is the easiest way to ensure that.
static private function EHLDelegateReturn PrioritizeRightClickMelee(XComGameState_Unit UnitState, out XComGameState_Ability PrioritizedMeleeAbility, optional XComGameState_BaseObject TargetObject)
{
	local XComGameStateHistory  History;
	local GameRulesCache_Unit   UnitCache;
	local XComGameState_Ability AbilityState;
	local AvailableAction       AvAction;

	`LOG(UnitState.GetFullName() @ "originally selected:" @ PrioritizedMeleeAbility.GetMyTemplateName() @ "Target unit is:" @ XComGameState_Unit(TargetObject).GetFullName(),, 'IRITEST');

	// Otherwise use the original logic for selecting the ability
	if (`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))
	{
		History = `XCOMHISTORY;

		// Issue #1138 - optimization: replaced for() with faster foreach()
		foreach UnitCache.AvailableActions(AvAction)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AvAction.AbilityObjectRef.ObjectID));
			if (AbilityState != none && class'X2AbilityTrigger_EndOfMove'.static.AbilityHasEndOfMoveTrigger(AbilityState.GetMyTemplate()))
			{
				`LOG(UnitState.GetFullName() @ AbilityState.GetMyTemplateName(),, 'IRITEST');
				if (AbilityState.GetMyTemplateName() == 'SwordSlice')
					PrioritizedMeleeAbility = AbilityState;
			}
		}
	}

    return EHLDR_NoInterrupt;
}



static function bool AbilityTagExpandHandler_CH(string InString, out string OutString, Object ParseObj, Object StrategyParseOb, XComGameState GameState)
{	// 	`AMLOG(ParseObj.Class.Name @ StrategyParseOb.Class.Name);
	// In strategy (ability description): WOTCIridarPerkPack: AbilityTagExpandHandler_CH X2AbilityTemplate XComGameState_Unit
	// In tactical (ability description): WOTCIridarPerkPack: AbilityTagExpandHandler_CH X2AbilityTemplate none (big oof)
	switch (InString)
	{

	case "IRI_BoundWeaponName":
		OutString = GetBoundWeaponName(ParseObj, StrategyParseOb, GameState);
		return true;
	
	// ======================================================================================================================
	//												SKIRMISHER TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	case "FullThrottle_CooldownReduction":
		OutString = SKColor(`GetConfigInt(InString));
		return true;

	case "Whiplash_Cooldown":
		OutString = SKColor(`GetConfigInt(InString) - 1);
		return true;

	case "ManualOverride_Cooldown":
		OutString = SKColor(`GetConfigInt(InString) - 1);
		return true;
	
	case "Interrupt_Cooldown":
		OutString = SKColor(`GetConfigInt(InString) - 1);
		return true;

	//case "Battlelord_Cooldown":
	//	OutString = SKColor(`GetConfigInt(InString) - 1);
	//	return true;
		
	case "Interrupt_NumPoints":
		OutString = SKColor(`GetConfigInt(InString));
		return true;

	case "IRI_ZeroIn_Aim":
		OutString = SKColor(GetZeroInAimBonus(ParseObj, StrategyParseOb, GameState));
		return true;

	case "IRI_ZeroIn_Crit":
		OutString = SKColor(GetZeroInCritBonus(ParseObj, StrategyParseOb, GameState));
		return true;

	// ======================================================================================================================
	//												RANGER TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	case "IRI_Conceal_DetectionRadiusModifier":
		OutString = string(int(`GetConfigFloat("IRI_Conceal_DetectionRadiusModifier") * 100));
		return true;
		
	// ======================================================================================================================
	//												SHARPSHOOTER TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	
	case "IRI_SH_DeadEye_AimPenalty":
		OutString = string(`GetConfigInt(InString));
		return true;

	case "IRI_SH_Serial_DamagePenaltyPerShot":
		OutString = string(`GetConfigInt(InString));
		return true;

	case "IRI_SH_Serial_DamagePenalty":
		OutString = string(int(GetUnitValue(class'X2Effect_Serial_AimPenalty'.default.EffectName, ParseObj, StrategyParseOb, GameState)) * `GetConfigInt("IRI_SH_Serial_DamagePenaltyPerShot"));
		return true;
		
		
	// ======================================================================================================================
	//												SPECIALIST TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	case "IRI_SP_MedicalProtocol_InitialCharges":
	case "IRI_SP_MedicalProtocol_BonusChargesPerMedikit":
		OutString = string(`GetConfigInt(InString));
		return true;


	// ======================================================================================================================
	//												TEMPLAR TAGS
	// ----------------------------------------------------------------------------------------------------------------------

		

	// ----------------------------------------------------------------------------------------------------------------------
	default:
		break;
	}

	return false;
}

static private function string GetZeroInAimBonus(Object ParseObj, Object StrategyParseObj, XComGameState GameState)
{
	return string(int(GetUnitValue(class'X2Effect_ZeroIn_Fixed'.default.UnitValueName, ParseObj, StrategyParseObj, GameState)) * class'X2Effect_ZeroIn'.default.LockedInAimPerShot);
}
static private function string GetZeroInCritBonus(Object ParseObj, Object StrategyParseObj, XComGameState GameState)
{
	return string(int(GetUnitValue(class'X2Effect_ZeroIn_Fixed'.default.UnitValueName, ParseObj, StrategyParseObj, GameState)) * class'X2Effect_ZeroIn'.default.CritPerShot);
}
static private function float GetUnitValue(const name ValueName, Object ParseObj, Object StrategyParseObj, XComGameState GameState)
{
	local XComGameState_Effect	EffectState;
	local XComGameState_Ability	AbilityState;
	local XComGameState_Unit	UnitState;
	local UnitValue				UV;

	if (StrategyParseObj != none)
	{
		UnitState = XComGameState_Unit(StrategyParseObj);
		if (UnitState != none)
		{
			if (UnitState.GetUnitValue(ValueName, UV))
			{
				return UV.fValue;
			}
		}
	}
	else
	{
		EffectState = XComGameState_Effect(ParseObj);
		if (EffectState != none)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
			if (UnitState != none)
			{
				if (UnitState.GetUnitValue(ValueName, UV))
				{
					return UV.fValue;
				}
			}
		}
		else
		{
			AbilityState = XComGameState_Ability(ParseObj);
			if (AbilityState != none)
			{
				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
				if (UnitState != none)
				{
					if (UnitState.GetUnitValue(ValueName, UV))
					{
						return UV.fValue;
					}
				}
			}
		}
	}
	return 0;
}

static private function string GetBoundWeaponName(Object ParseObj, Object StrategyParseObj, XComGameState GameState)
{
	local X2AbilityTemplate		AbilityTemplate;
	local X2ItemTemplate		ItemTemplate;
	local XComGameState_Effect	EffectState;
	local XComGameState_Ability	AbilityState;
	local XComGameState_Item	ItemState;

	AbilityTemplate = X2AbilityTemplate(ParseObj);
	if (StrategyParseObj != none && AbilityTemplate != none)
	{
		ItemTemplate = GetItemBoundToAbilityFromUnit(XComGameState_Unit(StrategyParseObj), AbilityTemplate.DataName, GameState);
	}
	else
	{
		EffectState = XComGameState_Effect(ParseObj);
		if (EffectState != none)
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		}
		else
		{
			AbilityState = XComGameState_Ability(ParseObj);
		}

		if (AbilityState != none)
		{
			ItemState = AbilityState.GetSourceWeapon();

			if (ItemState != none)
				ItemTemplate = ItemState.GetMyTemplate();
		}
	}

	if (ItemTemplate != none)
	{
		return ItemTemplate.GetItemAbilityDescName();
	}
	return AbilityTemplate.LocDefaultPrimaryWeapon;
}

static private function X2ItemTemplate GetItemBoundToAbilityFromUnit(XComGameState_Unit UnitState, name AbilityName, XComGameState GameState)
{
	local SCATProgression		Progression;
	local XComGameState_Item	ItemState;
	local EInventorySlot		Slot;

	if (UnitState == none)
		return none;

	Progression = UnitState.GetSCATProgressionForAbility(AbilityName);
	if (Progression.iRank == INDEX_NONE || Progression.iBranch == INDEX_NONE)
		return none;

	Slot = UnitState.AbilityTree[Progression.iRank].Abilities[Progression.iBranch].ApplyToWeaponSlot;
	if (Slot == eInvSlot_Unknown)
		return none;

	ItemState = UnitState.GetItemInSlot(Slot, GameState);
	if (ItemState != none)
	{
		return ItemState.GetMyTemplate();
	}

	return none;
}


static private function string TMColor(coerce string strInput)
{
	return "<font color='#b6b5d4'>" $ strInput $ "</font>"; // light purple
}

static private function string SKColor(coerce string strInput)
{
	return "<font color='#e50000'>" $ strInput $ "</font>"; // deep red
}

static private function string GetPercentValue(string ConfigName)
{
	local int PercentValue;

	PercentValue = `GetConfigFloat(ConfigName) * 100;

	return string(PercentValue);
}