class Grenadier extends Common;

static final function PatchAbilities()
{
	PatchBlastPadding();
	PatchSaturationFire();
	PatchChainShot();
	PatchDemolition();
	PatchSuppression();
	PatchSuppressionShot();
	//PatchRupture();

	PatchBulletShred();
	PatchHailOfBullets();

	PatchFlashbangForVolatileMix();

	UpdateShotHUDPrioritiesForClass('Grenadier');
}

static private function PatchFlashbangForVolatileMix()
{
	local X2ItemTemplateManager	ItemMgr;
	local X2GrenadeTemplate		Template;

	ItemMgr = class'X2AbilityTemplateManager'.static.GetItemTemplateManager();
	Template = X2GrenadeTemplate(ItemMgr.FindAbilityTemplate('FlashbangGrenade'));
	if (Template == none)	
		return;

	Template.bAllowVolatileMix = false;
}

static private function PatchHailOfBullets()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('HailOfBullets');
	if (Template == none)	
		return;

	Template.bAllowFreeFireWeaponUpgrade = true;
}

static private function PatchBulletShred()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate				Template;
	local X2Condition_UnitEffects	UnitEffects;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('BulletShred');
	if (Template == none)	
		return;

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	// For some reason Firaxis decided to allow using Rupture while disoriented.
	UnitEffects = new class'X2Condition_UnitEffects';
	UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.DisorientedName, 'AA_UnitIsDisoriented');
	Template.AbilityShooterConditions.AddItem(UnitEffects);
}

static private function PatchRupture()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('BulletShred');
	if (Template == none)
		return;

	// Template.AddTargetEffect(new class'X2Effect_RuptureDamagePreview');
	// 
	// StandardAim = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
	// if (StandardAim == none)
	// 	return;
	// //StandardAim.bHitsAreCrits = true;
	// StandardAim.BuiltInCritMod = 100;

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchDemolition()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;
	//local X2AbilityToHitCalc_StandardAim	StandardAim;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Demolition');
	if (Template == none)
		return;

	//Template.bLimitTargetIcons = false;
	Template.DisplayTargetHitChance = false;
	//StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	//StandardAim.bGuaranteedHit = true;
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
}

static private function PatchSuppression()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Suppression');
	if (Template == none)	
		return;

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchSuppressionShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2AbilityToHitCalc_StandardAim	ToHitCalc;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_ApplyWeaponDamage		StockEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('SuppressionShot');
	if (Template == none)	
		return;

	// Ensure weapon upgrade compat
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = true;

	StockEffect = new class'X2Effect_ApplyWeaponDamage';
	StockEffect.bApplyOnHit = false;
	StockEffect.bApplyOnMiss = true;
	StockEffect.bIgnoreBaseDamage = true;
	StockEffect.DamageTag = 'Miss';
	StockEffect.bAllowWeaponUpgrade = true;
	StockEffect.bAllowFreeKill = false;
	StockEffect.TargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());
	Template.AddTargetEffect(StockEffect);

	Template.AbilityTriggers.Length = 0;

	// Trigger = new class'X2AbilityTrigger_EventListener';
	// Trigger.ListenerData.EventID = 'ObjectMoved';
	// Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	// Trigger.ListenerData.Filter = eFilter_None;
	// Trigger.ListenerData.EventFn = Suppression_ObjectMovedListener;
	// Template.AbilityTriggers.AddItem(Trigger);

	// Trigger on ability activation too
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = Suppression_EventListenerTrigger;
	Template.AbilityTriggers.AddItem(Trigger);

	ToHitCalc = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
	if (ToHitCalc == none)
		return;

	ToHitCalc.bIgnoreCoverBonus = true;
}

static private function EventListenerReturn Suppression_EventListenerTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability					ActivatedAbilityState;
	local X2AbilityTemplate						AbilityTemplate;
	local XComGameState_Ability					AbilityState;
	local XComGameState_Unit					TargetUnit;
	local XComGameState_Unit					ChainStartTargetUnit;
	local XComGameStateHistory					History;
	local int									ChainStartIndex;
	local XComGameState_Effect					EffectState;
	local XComGameState_Effect					SuppressionEffectState;
	local StateObjectReference					EffectRef;
	local bool									bIgnoreReactionFire;
	local XComGameStateContext_EffectRemoved	EffectRemovedContext;
	local XComGameState							NewGameState;
	local XComGameStateContext_Ability			AbilityContext;
	local bool									bTargetAttacking;
	local bool									bTargetMoving;
	local name									EffectName;

	// #1. Check if the target unit is suppressed by us. If it's not, we don't even care.
	TargetUnit = XComGameState_Unit(EventSource);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	ChainStartIndex = History.GetEventChainStartIndex();
	if (ChainStartIndex == INDEX_NONE)
		return ELR_NoInterrupt;
	
	ChainStartTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID,, ChainStartIndex));
	if (ChainStartTargetUnit == none)
	  	return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;
	
	foreach ChainStartTargetUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState == none)
			continue;
		EffectName = EffectState.GetX2Effect().EffectName;

		// While we're at it, check if the target ignores reaction fire.
		if (!bIgnoreReactionFire && class'X2Ability_DefaultAbilitySet'.default.OverwatchExcludeEffects.Find(EffectName) != INDEX_NONE)
		{
			bIgnoreReactionFire = true;
		}

		// Find the suppression effect applied by us, if any.
		if (SuppressionEffectState == none && EffectName == class'X2Effect_Suppression'.default.EffectName && EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == AbilityState.OwnerStateObject.ObjectID)
		{
			SuppressionEffectState = EffectState;
		}

		// Exit early if we already found everything we care about.
		if (SuppressionEffectState != none && bIgnoreReactionFire)
		{
			break;
		}
	}
	if (SuppressionEffectState == none)
		return ELR_NoInterrupt;

	// #2. Find out what triggered the suppression. Movement? Attack?
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;

		`AMLOG("Target Unit:" @ TargetUnit.GetMyTemplateName() @ "Ability:" @ AbilityContext.InputContext.AbilityTemplateName @ "Interrupt:" @ AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt);

	if (!bIgnoreReactionFire && class'X2Ability_DefaultAbilitySet'.default.OverwatchIgnoreAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE)
	{
		bIgnoreReactionFire = true;
	}

	ActivatedAbilityState = XComGameState_Ability(EventData);
	if (ActivatedAbilityState == none)
		return ELR_NoInterrupt;

	AbilityTemplate = ActivatedAbilityState.GetMyTemplate();
	if (AbilityTemplate == none)
		return ELR_NoInterrupt;
	
	if (AbilityTemplate.Hostility == eHostility_Offensive)
	{
		bTargetAttacking = true;
	}
	else if (IsTargetUnitMoving(TargetUnit.ObjectID, AbilityContext.InputContext.MovementPaths))
	{
		// If target is performing a move, do nothing on the first tile of movement, so that the unit has a chance to move outside LoS.
		// This will still trigger properly when moving to a directly adjacent tile.
		if (!bIgnoreReactionFire && ChainStartTargetUnit.TileLocation == TargetUnit.TileLocation)
		{
	 		return ELR_NoInterrupt;
		}

		bTargetMoving = true;
	}

	`AMLOG(`ShowVar(bTargetAttacking) @ `ShowVar(bTargetMoving) @ `ShowVar(bIgnoreReactionFire));
	
	// #3. Respond to attacks or movement.
	if (bTargetAttacking || bTargetMoving)
	{
		// If target isn't immune to reaction fire, attempt to activate suppression shot.
		if (bIgnoreReactionFire && bTargetMoving || !AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false))
		{
			`AMLOG("Activation failed, removing suppression effect.");
			
			// If target is immune, or activation fails for whatever reason (e.g. line of sight loss), remove the suppression effect from the target.
			EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(SuppressionEffectState);
			NewGameState = `XCOMHISTORY.CreateNewGameState(true, EffectRemovedContext);
			SuppressionEffectState.RemoveEffect(NewGameState, NewGameState, true);
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

static private function bool IsTargetUnitMoving(const int ObjectID, const array<PathingInputData> MovementPaths)
{
    local PathingInputData MovementPath;
    local int i;

    foreach MovementPaths(MovementPath, i)
    {
        if (MovementPath.MovingUnitRef.ObjectID == ObjectID && MovementPath.MovementTiles.Length > 0)
        {
			`AMLOG("0th tile:" @ MovementPath.MovementTiles[0].X @ MovementPath.MovementTiles[0].Y @ MovementPath.MovementTiles[0].Z);
            return true;
        }
    }
    return false;
}

/*
static private function EventListenerReturn Suppression_ObjectMovedListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability			AbilityState;
	local XComGameState_Unit			TargetUnit;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameStateHistory			History;
	local int							ChainStartIndex;
	local Name							EffectName;
	local XComGameState_Effect			EffectState;
	local StateObjectReference			EffectRef;
	local name							EffectName;
	local bool							bImmuneToReactionFire;
	local XComGameState_Effect			SuppressionEffect;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	if (AbilityContext != none)
	{
		if (class'X2Ability_DefaultAbilitySet'.default.OverwatchIgnoreAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE)
			return ELR_NoInterrupt;
	}

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(EventData);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	// Check effects on target unit at the start of this chain.
	History = `XCOMHISTORY;
	ChainStartIndex = History.GetEventChainStartIndex();
	if (ChainStartIndex == INDEX_NONE)
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID,, ChainStartIndex));
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	// Iterate over all effects on the moving to unit to find out if:
	// 1. Target is immune to reaction fire.
	// 2. Target is suppressed by us. 
	// If both are true, we can't fire the suppression shot, but 

	foreach TargetUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState == none)
			continue;

		EffectName = EffectState.GetX2Effect().EffectName;
		if (!bImmuneToReactionFire && class'X2Ability_DefaultAbilitySet'.default.OverwatchExcludeEffects.Find(EffectName))
		{
			bImmuneToReactionFire = true;
		}

		if (SuppressionEffect == none &&
			EffectName == class'X2Effect_Suppression'.default.EffectName &&
			EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == AbilityState.OwnerStateObject.ObjectID)
		{
			SuppressionEffect = EffectState;
		}

		// Target has moved while being immune to reaction fire. We can't fire the suppression shot, so remove the suppression effect manually.
		if (bImmuneToReactionFire && SuppressionEffect != none)
		{
		}
	}
	
	// Target is moved and is not immune to suppression. Attempt to trigger the suppression. SuppressionShot conditions will make sure we can fire only on the target suppressed by us anyway.
	AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);
	
	return ELR_NoInterrupt;
}*/

static private function PatchChainShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2AbilityTemplate					Template2;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc2;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('ChainShot');
	Template2 = AbilityMgr.FindAbilityTemplate('ChainShot2');
	if (Template == none || Template2 == none)	
		return;

	Template.bAllowFreeFireWeaponUpgrade = true;

	ToHitCalc = X2AbilityToHitCalc_StandardAim(Template.AbilityToHitCalc);
	ToHitCalc2 = X2AbilityToHitCalc_StandardAim(Template2.AbilityToHitCalc);
	if (ToHitCalc == none || ToHitCalc2 == none)	
		return;

	ToHitCalc2.BuiltInHitMod = ToHitCalc.BuiltInHitMod;
	ToHitCalc.BuiltInHitMod = 0;

	Template2.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchSaturationFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect_ReliableWorldDamage		WorldDamage;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('SaturationFire');
	if (Template == none)	
		return;

	WorldDamage = new class'WOTCIridarClassRework.X2Effect_ReliableWorldDamage';
	WorldDamage.DamageAmount = `GetConfigInt("IRI_GN_SaturationFire_Reliable_EnvDamage");

	// Many cover objects occupy more than one tile, and chance is rolled per-tile, so lower it accordingly
	WorldDamage.ApplyChancePerTile = class'X2Ability_GrenadierAbilitySet'.default.SATURATION_DESTRUCTION_CHANCE / 2;
	WorldDamage.bSkipGroundTiles = true;
	Template.AddShooterEffect(WorldDamage);
	Template.bRecordValidTiles = true; // For the world damage effect

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchBlastPadding()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect_BlastPaddingExtended		PaddingEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('BlastPadding');
	if (Template == none)	
		return;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_BlastPadding(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);

			PaddingEffect = new class'X2Effect_BlastPaddingExtended';
			PaddingEffect.ExplosiveDamageReduction = class'X2Ability_GrenadierAbilitySet'.default.BLAST_PADDING_DMG_ADJUST;
			PaddingEffect.BuildPersistentEffect(1, true, false);
			PaddingEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage,,,Template.AbilitySourceName);
			Template.AddTargetEffect(PaddingEffect);
			break;
		}
	}
}

