class X2DLCInfo_WOTCIridarClassRework extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	if (`GetConfigBool("Skirmisher"))	class'Skirmisher'.static.PatchAbilities();
	if (`GetConfigBool("Templar"))		class'Templar'.static.PatchAbilities();
	if (`GetConfigBool("Ranger"))		class'Ranger'.static.PatchAbilities();
	if (`GetConfigBool("Sharpshooter"))	class'Sharpshooter'.static.PatchAbilities();
	if (`GetConfigBool("Grenadier"))	class'Grenadier'.static.PatchAbilities();
	if (`GetConfigBool("Specialist"))	class'Specialist'.static.PatchAbilities();
	if (`GetConfigBool("SPARK"))		class'SPARK'.static.PatchAbilities();
	if (`GetConfigBool("Reaper"))		class'Reaper'.static.PatchAbilities();

	//CheckClassAbilities();
}

static private function CheckClassAbilities()
{
	local X2SoldierClassTemplateManager ClassMgr;
	local X2SoldierClassTemplate ClassTemplate;
	local array<name> ClassNames;
	local name ClassName;
	local SoldierClassRank SoldierRank;
	local SoldierClassAbilitySlot AbilitySlot;

	ClassNames.AddItem('Ranger');
	ClassNames.AddItem('Sharpshooter');
	ClassNames.AddItem('Grenadier');
	ClassNames.AddItem('Specialist');
	ClassNames.AddItem('PsiOperative');
	ClassNames.AddItem('Skirmisher');
	ClassNames.AddItem('Reaper');
	ClassNames.AddItem('Templar');

	ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach ClassNames(ClassName)
	{
		ClassTemplate = ClassMgr.FindSoldierClassTemplate(ClassName);

		foreach ClassTemplate.SoldierRanks(SoldierRank)
		{
			foreach SoldierRank.AbilitySlots(AbilitySlot)
			{
				CheckAbility(AbilitySlot.AbilityType.AbilityName);
			}
		}
	}
}

static final protected function CheckAbility(const name AbilityName)
{
	local X2AbilityTemplate				AbilityTemplate;
	local X2AbilityTemplateManager		AbilityMgr;
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local X2Effect						Effect;
	local bool							bEffectFound;
	local int							iNumIssuesFound;
	local name							AdditionalAbility;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityName);

	foreach AbilityTemplate.AdditionalAbilities(AdditionalAbility)
	{
		CheckAbility(AdditionalAbility);
	}

	if (AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Self'))
		return;

	`AMLOG("### Begin checking ability:" @ AbilityName);

	if (!AbilityTemplate.bAllowAmmoEffects)
	{
		iNumIssuesFound++;
		`AMLOG("Does not apply ammo effects!");
	}
	if (!AbilityTemplate.bAllowBonusWeaponEffects)
	{
		iNumIssuesFound++;
		`AMLOG("Does not apply bonus effects!");
	}
	if (!AbilityTemplate.bAllowFreeFireWeaponUpgrade)
	{
		iNumIssuesFound++;
		`AMLOG("Does not allow Hair Trigger!");
	}

	if (AbilityTemplate.AbilityTargetEffects.Length > 0)
	{	
		// Add Stock Damage effect
		bEffectFound = false;
		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			DamageEffect = X2Effect_ApplyWeaponDamage(Effect);
			if (DamageEffect == none)
				continue;

			if (DamageEffect.DamageTag == 'Miss' && !DamageEffect.bApplyOnHit && DamageEffect.bApplyOnMiss && DamageEffect.bIgnoreBaseDamage)
			{
				bEffectFound = true;
				break;
			}
		}
		if (!bEffectFound)
		{
			iNumIssuesFound++;
			`AMLOG("Does not apply Stock Miss Damage!");
		}

		// Add Holo Targeting effect
		bEffectFound = false;
		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			if (X2Effect_HoloTarget(Effect) != none)
			{
				bEffectFound = true;
				break;
			}			
		}
		if (!bEffectFound)
		{
			iNumIssuesFound++;
			`AMLOG("Does not apply Holo Targeting!");
		}
	}
	
	if (AbilityTemplate.AbilityMultiTargetEffects.Length > 0 && AbilityTemplate.AbilityMultiTargetStyle != none)
	{
		// Add Stock Damage effect
		bEffectFound = false;
		foreach AbilityTemplate.AbilityMultiTargetEffects(Effect)
		{
			DamageEffect = X2Effect_ApplyWeaponDamage(Effect);
			if (DamageEffect == none)
				continue;

			if (DamageEffect.DamageTag == 'Miss' && !DamageEffect.bApplyOnHit && DamageEffect.bApplyOnMiss && DamageEffect.bIgnoreBaseDamage)
			{
				bEffectFound = true;
				break;
			}
		}
		if (!bEffectFound)
		{
			iNumIssuesFound++;
			`AMLOG("Does not apply Stock damage to multi targets!");
		}
	}

	if (iNumIssuesFound > 0)
	{
		`AMLOG("+++ WARNING, Found issues:" @ iNumIssuesFound);
	}
	else
	{
		`AMLOG("--- ALL CLEAR");
	}
}

// --------------------------


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

	//case "ManualOverride_Cooldown":
	//	OutString = SKColor(`GetConfigInt(InString) - 1);
	//	return true;
	
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

	case "IRI_DeepCover_ArmorBonus":
		OutString = string(`GetConfigInt(InString));
		return true;

	// ======================================================================================================================
	//												REAPER TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	case "IRI_RP_StingCharges":
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.StingCharges);
		return true;
		
		
	// ======================================================================================================================
	//												SHARPSHOOTER TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	
	case "IRI_SH_DeadEye_AimPenalty":
		OutString = string(`GetConfigInt(InString));
		return true;

	case "IRI_SH_Serial_CritChancePenaltyPerShot":
		OutString = string(`GetConfigInt(InString));
		return true;

	case "IRI_SH_Serial_CritChancePenalty":
		OutString = string(int(GetUnitValue(class'X2Effect_Serial_AimPenalty'.default.EffectName, ParseObj, StrategyParseOb, GameState)) * `GetConfigInt("IRI_SH_Serial_CritChancePenaltyPerShot"));
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

	case "IRI_TM_VoidConduit_HPDrain":
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage * 2);
		return true;

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

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState = none)
{
    if (ItemState == none) 
	{	
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponArchetype.ObjectID));
	}
	if (ItemState == none)
		return;

	// Add FanFire animations to autopistols.
	if (ItemState.GetWeaponCategory() == 'sidearm')
	{
		Weapon.CustomUnitPawnAnimsets.AddItem(AnimSet(`CONTENT.RequestGameArchetype("IRIClassRework_Templar.AS_Autopistol_FanFire")));
	}
}
