class Reaper extends Common;

static final function PatchAbilities()
{
	PatchSting();
	PatchBloodTrail();
	PatchImprovisedSilencer();
	PatchExecutioner();
	PatchSoulReaper();
	PatchPaleHorse();

	MakeInterruptible('ThrowClaymore');
	MakeInterruptible('ThrowShrapnel');
	MakeInterruptible('HomingMine');
	MakeInterruptible('RemoteStart');

	UpdateShotHUDPrioritiesForClass('Reaper');
}

static private function PatchPaleHorse()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_PaleHorse_Fixed		Effect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('PaleHorse');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_PaleHorse(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			//X2Effect_PaleHorse(AbilityTemplate.AbilityTargetEffects[i]).GameStateEffectClass = class'XComGameState_Effect_PaleHorse_Fixed';

			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
			
			Effect = new class'X2Effect_PaleHorse_Fixed';
			Effect.BuildPersistentEffect(1, true, false, false);
			Effect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			Effect.CritBoostPerKill = class'X2Ability_ReaperAbilitySet'.default.PaleHorseCritBoost;
			Effect.MaxCritBoost = class'X2Ability_ReaperAbilitySet'.default.PaleHorseMax;
			AbilityTemplate.AddTargetEffect(Effect);
			break;
		}
	}

	
}

static private function PatchSoulReaper()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SoulReaper');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.AddTargetEffect(default.WeaponUpgradeMissDamage);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SoulReaperContinue');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;	

	for (i=0; i < AbilityTemplate.AbilityTriggers.length; i++)
	{
		if (X2AbilityTrigger_EventListener(AbilityTemplate.AbilityTriggers[i]) != none)
		{
			X2AbilityTrigger_EventListener(AbilityTemplate.AbilityTriggers[i]).ListenerData.EventFn = SoulReaperListener;
			break;
		}
	}
}

// Copied from MrNice's Ability Interaction Fixes and restyled a bit.
static private function EventListenerReturn SoulReaperListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateHistory			History;
	local XComGameState_Ability			AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;
	local array<StateObjectReference>	PossibleTargets;
	local StateObjectReference			BestTargetRef;
	local int							BestTargetHP;
	local bool							bAbilityTriggered;
	local int i;
	
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	bAbilityTriggered = AbilityState.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);

	if (!bAbilityTriggered && SourceUnit.HasSoldierAbility('SoulHarvester'))
	{
		//	find all possible new targets and select one with the highest HP to fire against
		History = `XCOMHISTORY;
		
		class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(SourceUnit.ObjectID, PossibleTargets, AbilityState.GetMyTemplate().AbilityTargetConditions);
		BestTargetHP = -1;

		for (i = 0; i < PossibleTargets.Length; ++i)
		{
			TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(PossibleTargets[i].ObjectID));
			if (TargetUnit.GetCurrentStat(eStat_HP) > BestTargetHP)
			{
				BestTargetHP = TargetUnit.GetCurrentStat(eStat_HP);
				BestTargetRef = PossibleTargets[i];
			}
		}
		if (BestTargetRef.ObjectID > 0)
		{
			bAbilityTriggered = AbilityState.AbilityTriggerAgainstSingleTarget(BestTargetRef, false);
		}
	}

	if (!bAbilityTriggered)
	{
		SourceUnit.BreakConcealment();
	}
	
	return ELR_NoInterrupt;
}

static private function PatchExecutioner()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_RP_Executioner		Effect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Executioner');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Executioner(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
		}
	}

	Effect = new class'X2Effect_RP_Executioner';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(Effect);
}

static private function PatchBloodTrail()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_RP_BloodTrail		Effect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('BloodTrail');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_BloodTrail(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
		}
	}

	Effect = new class'X2Effect_RP_BloodTrail';
	Effect.BonusDamage = class'X2Ability_ReaperAbilitySet'.default.BloodTrailDamage;
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(Effect);
}



static private function PatchSting()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim	StandardAim;
	//local X2Effect_Charges					SetCharges;
	//local X2Effect_Charges					SetClaymoreCharges;
	//local X2Condition_AbilityProperty		AbilityProperty;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Sting');
	if (AbilityTemplate == none)	
		return;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bHitsAreCrits = true;
	StandardAim.BuiltInCritMod = 100;
	AbilityTemplate.AbilityToHitCalc = StandardAim;

	RemoveChargeCost(AbilityTemplate);
	
	// Sting already has cooldown in vanilla.
	//AddCooldown(AbilityTemplate, `GetConfigInt("Sting_Cooldown"));

	// SetCharges = new class'X2Effect_Charges';
	// SetCharges.AbilityNames.AddItem('Sting');
	// SetCharges.Charges = class'X2Ability_ReaperAbilitySet'.default.StingCharges;
	// SetCharges.bSetCharges = true;
	// 
	// 
	// SetClaymoreCharges = new class'X2Effect_Charges';
	// SetClaymoreCharges.AbilityNames.AddItem('ThrowClaymore');
	// SetClaymoreCharges.AbilityNames.AddItem('ThrowShrapnel');
	// SetClaymoreCharges.AbilityNames.AddItem('HomingMine');
	// SetClaymoreCharges.AbilityNames.AddItem('IRI_RP_Takedown');
	// SetClaymoreCharges.Charges = 1;
	// SetClaymoreCharges.bRespectInitialCharges = true;
	// 
	// AbilityProperty = new class'X2Condition_AbilityProperty';
	// AbilityProperty.OwnerHasSoldierAbilities.AddItem('IRI_RP_MakeshiftExplosives');
	// SetClaymoreCharges.TargetConditions.AddItem(AbilityProperty);
	// 
	// AbilityTemplate = AbilityMgr.FindAbilityTemplate('Shadow');
	// if (AbilityTemplate != none)	
	// {
	// 	AbilityTemplate.AddTargetEffect(SetCharges);
	// 	AbilityTemplate.AddTargetEffect(SetClaymoreCharges);
	// }
	// 
	// AbilityTemplate = AbilityMgr.FindAbilityTemplate('DistractionShadow');
	// if (AbilityTemplate != none)	
	// {
	// 	AbilityTemplate.AddTargetEffect(SetCharges);
	// 	AbilityTemplate.AddTargetEffect(SetClaymoreCharges);
	// }
}

static private function PatchImprovisedSilencer()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ImprovisedSilencer');
	if (AbilityTemplate == none)	
		return;

	AbilityTemplate.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_improvisedsilencer";
}
