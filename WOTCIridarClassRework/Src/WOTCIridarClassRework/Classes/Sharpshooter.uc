class Sharpshooter extends Common;

var localized string strSerialAimPenaltyEffectDesc;
var localized string SharpshooterAimBonusDesc;

static final function PatchAbilities()
{
	PatchSerial();
	PatchFanFire();
	PatchDeadeye();
	PatchDeadeyeDuncan();
	PatchDeathFromAbove();
	PatchSharpshooterAim();
	PatchReturnFire();

	//PatchKillZoneShot();

	MakeInterruptible('LightningHands');
	MakeInterruptible('Faceoff');

	UpdateShotHUDPrioritiesForClass('Sharpshooter');
}

static private function PatchKillZoneShot()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('KillZoneShot');
	if (AbilityTemplate == none)
		return;

	//AbilityTemplate.AddTargetEffect(default.WeaponUpgradeMissDamage);
}

static private function PatchReturnFire()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect						Effect;
	local X2Effect_ReturnFire			FireEffect;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ReturnFire');
	if (AbilityTemplate == none)
		return;

	foreach AbilityTemplate.AbilityTargetEffects(Effect)
	{
		FireEffect = X2Effect_ReturnFire(Effect);
		if (X2Effect_ReturnFire(Effect) == none)
			continue;

		FireEffect.bPreEmptiveFire = true;
		break;
	}
	
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('PistolReturnFire');
	if (AbilityTemplate == none)
		return;

	// Highlander sets this to SPT_AfterSequential to make it properly visualize after Covering Fire overwatch, but this causes a visualization bug if return fire is preemptive.
	AbilityTemplate.AssociatedPlayTiming = SPT_None;

	// After unsuccessfully experimenting with different SPT values,
	// AbilityTemplate.AssociatedPlayTiming = SPT_None;
	// AbilityTemplate.AssociatedPlayTiming = SPT_BeforeParallel;
	// AbilityTemplate.AssociatedPlayTiming = SPT_BeforeSequential;
	// Covering Fire visualizes correctly before the enemy attack. Then if Return Fire doesn't kill the target, it plays after enemy attack (wrong). If it kills the target, the shot doesn't visualize, target dies instantly after taking covering fire overwatch.
	
	// AbilityTemplate.AssociatedPlayTiming = SPT_AfterParallel;
	// AbilityTemplate.AssociatedPlayTiming = SPT_AfterSequential;
	// If Return Fire kills the target, the shot doesn't even visualize.

	// ... ended up having to make a custom Merge Vis function.
	// By default the shot seems to be put in parallel to the covering fire overwatch shot, causing it to fail to visualize.
	AbilityTemplate.MergeVisualizationFn = PistolReturnFire_MergeVisualization;
	
	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if (ToHitCalc == none)
		return;

	ToHitCalc.bIgnoreCoverBonus = true;
}

// 1. Trooper that dies to Return Fire: perfect
// 2. Trooper that does not die to Return Fire: perfect
// 3. Trooper that dies to return fire after covering fire overwatch: shots sync well, but enemy freezes when killed by return fire.
// 4. Trooped that does not die to return fire after covering fire overwatch: perfect.
static private function PistolReturnFire_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local X2Action_MarkerTreeInsertBegin	MarkerStart;
	local X2Action_MarkerTreeInsertEnd		MarkerEnd;
	local XComGameStateContext_Ability		Context;
	local X2Action_Fire						FireAction;
	local X2Action							InsertAboveAction;
	local array<X2Action>					FindActions;
	local X2Action							FindAction;
	local int								ClosestHistoryIndex;
	local X2Action_MarkerNamed				MarkerNamed;
	local VisualizationActionMetadata		ActionMetadata;

	VisMgr = `XCOMVISUALIZATIONMGR;
	Context = XComGameStateContext_Ability(BuildTree.StateChangeContext);
	if (Context == none)
		return;

	`LOG("====================== MAIN VIZ TREE =========================");
	PrintActionRecursive(VisualizationTree, 0);
	`LOG("---------------------------------------- END ----------------------------------------");

	`LOG("====================== BUILD TREE =========================");
	PrintActionRecursive(BuildTree, 0);
	`LOG("---------------------------------------- END ----------------------------------------");

	MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	MarkerEnd = X2Action_MarkerTreeInsertEnd(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd'));
	FireAction = X2Action_Fire(VisMgr.GetNodeOfType(BuildTree, class'X2Action_Fire')); 
	if (MarkerStart == none || MarkerEnd == none || FireAction == none)
	{
		Context.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
		return;
	}

	// Find the end of whichever interrupted visualization is playing on the enemy unit that triggered Return Fire.
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerInterruptEnd', FindActions ,, FireAction.PrimaryTargetID); // FireAction.PrimaryTargetID - the enemy we are shooting at = enemy that triggered Return Fire.
	ClosestHistoryIndex = MaxInt;
	foreach FindActions(FindAction)
	{
		if (ClosestHistoryIndex > FireAction.StateChangeContext.AssociatedState.HistoryIndex - FindAction.StateChangeContext.AssociatedState.HistoryIndex)
		{
			InsertAboveAction = FindAction;
			ClosestHistoryIndex = FireAction.StateChangeContext.AssociatedState.HistoryIndex - FindAction.StateChangeContext.AssociatedState.HistoryIndex;
		}
	}

	`AMLOG("Found InsertAboveAction at history index:" @ InsertAboveAction.StateChangeContext.AssociatedState.HistoryIndex);
	
	if (InsertAboveAction == none)
	{
		Context.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
		return;
	}

	// Shove a marker action right above it.
	ActionMetadata = FireAction.Metadata;
	MarkerNamed = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false,, InsertAboveAction.ParentActions));
	MarkerNamed.SetName("Return Fire Marker");

	//VisMgr.InsertSubtree(MarkerStart, MarkerEnd, MarkerNamed);

	// This should wedge the Return Fire visualization between MarkerNamed and InsertAboveAction.
	VisMgr.ConnectAction(MarkerStart, VisualizationTree, false, MarkerNamed);
	VisMgr.ConnectAction(InsertAboveAction, VisualizationTree, false, MarkerEnd);

	`LOG("====================== MAIN VIZ TREE AFTER MERGING =========================");
	PrintActionRecursive(VisualizationTree, 0);
	`LOG("---------------------------------------- END ----------------------------------------");
}

static function PrintActionRecursive(X2Action Action, int iLayer)
{
	local X2Action ChildAction;
	local XComGameState_Unit UnitState;
	local string strMessage;
	local X2Action_MarkerNamed MarkerAction;

	strMessage = "Action layer:" @ iLayer @ ":" @ Action.Class.Name;

	MarkerAction = X2Action_MarkerNamed(Action);
	if (MarkerAction != none)
	{
		strMessage @= MarkerAction.MarkerName;
	}

	UnitState = XComGameState_Unit(Action.Metadata.StateObject_NewState);
	if (UnitState != none)
	{
		strMessage @= UnitState.GetFullName();
	}
	strMessage @= Action.StateChangeContext.AssociatedState.HistoryIndex;
		
	`LOG(strMessage,, 'IRIPISTOLVIZ'); 
	foreach Action.ChildActions(ChildAction)
	{
		PrintActionRecursive(ChildAction, iLayer + 1);
	}
}

static private function PatchSharpshooterAim()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2DataTemplate					DataTemplate;
	local X2Effect_SH_SharpshooterAim		AimEffect;
	local X2Condition_AbilityProperty		AbilityCondition;
	local int i;

	AimEffect = new class'X2Effect_SH_SharpshooterAim';
	AimEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	AimEffect.SetDisplayInfo(ePerkBuff_Bonus, class'X2Ability_SharpshooterAbilitySet'.default.SharpshooterAimBonusName, default.SharpshooterAimBonusDesc, "img:///UILibrary_PerkIcons.UIPerk_aim");
	
	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('SharpshooterAim');
	AimEffect.TargetConditions.AddItem(AbilityCondition);

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach AbilityMgr.IterateTemplates(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if (AbilityTemplate == none)
			continue;

		for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
		{
			if (X2Effect_SharpshooterAim(AbilityTemplate.AbilityTargetEffects[i]) != none)
			{
				AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
				AbilityTemplate.AddTargetEffect(AimEffect);
				break;
			}
		}

		for (i = AbilityTemplate.AbilityShooterEffects.Length - 1; i >= 0; i--)
		{
			if (X2Effect_SharpshooterAim(AbilityTemplate.AbilityShooterEffects[i]) != none)
			{
				AbilityTemplate.AbilityShooterEffects.Remove(i, 1);
				AbilityTemplate.AddShooterEffect(AimEffect);
				break;
			}
		}

		for (i = AbilityTemplate.AbilityMultiTargetEffects.Length - 1; i >= 0; i--)
		{
			if (X2Effect_SharpshooterAim(AbilityTemplate.AbilityMultiTargetEffects[i]) != none)
			{
				AbilityTemplate.AbilityMultiTargetEffects.Remove(i, 1);
				AbilityTemplate.AddMultiTargetEffect(AimEffect);
				break;
			}
		}
	}
}

static private function PatchDeathFromAbove()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_SH_DeathFromAbove		DeathFromAbove;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('DeathFromAbove');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_DeathFromAbove(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			DeathFromAbove = new class'X2Effect_SH_DeathFromAbove';
			DeathFromAbove.BuildPersistentEffect(1, true, false, false);
			DeathFromAbove.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, true,,AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(DeathFromAbove);

			break;
		}
	}
}

static private function PatchDeadeyeDuncan()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_SH_DeadeyeDamage			DamageEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('DeadeyeDamage');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_DeadeyeDamage(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			DamageEffect = new class'X2Effect_SH_DeadeyeDamage';
			DamageEffect.BuildPersistentEffect(1, true, false, false);
			DamageEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, false,,AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(DamageEffect);

			break;
		}
	}
}

static private function PatchDeadeye()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Deadeye');
	if (AbilityTemplate == none)	
		return;

	// Use flat aim penalty instead of percentage based
	ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	ToHitCalc.FinalMultiplier = 1.0f;
	ToHitCalc.BuiltInHitMod = `GetConfigInt("IRI_SH_DeadEye_AimPenalty");

	AbilityTemplate.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	AbilityTemplate.bAllowFreeFireWeaponUpgrade = true;
}

static private function PatchFanFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityCost_ActionPoints		ActionCost;
	local X2AbilityCost						AbilityCost;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('FanFire');
	if (AbilityTemplate == none)	
		return;

	foreach AbilityTemplate.AbilityCosts(AbilityCost)
	{
		ActionCost = X2AbilityCost_ActionPoints(AbilityCost);
		if (ActionCost == none)
			continue;

		// Make it turn-ending
		ActionCost.bConsumeAllPoints = true;
	}

	AbilityTemplate.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchSerial()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_Serial_AimPenalty		AimPenalty;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('InTheZone');
	if (AbilityTemplate == none)	
		return;

	AimPenalty = new class'X2Effect_Serial_AimPenalty';
	//AimPenalty.AimPenaltyPerShot = `GetConfigInt("IRI_SH_Serial_AimPenaltyPerShot");
	AimPenalty.CritChancePenaltyPerShot = `GetConfigInt("IRI_SH_Serial_CritChancePenaltyPerShot");
	AimPenalty.SetDisplayInfo(ePerkBuff_Penalty, AbilityTemplate.LocFriendlyName, default.strSerialAimPenaltyEffectDesc, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(AimPenalty);
}