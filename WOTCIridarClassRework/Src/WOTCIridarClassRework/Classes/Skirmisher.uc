class Skirmisher extends Common;

var localized string strReflexSpent;
var localized string strReflexThisTurnFlyover;

static final function PatchAbilities()
{
	PatchSkirmisherReflex();
	PatchSkirmisherPostAbilityMelee();
	PatchJustice();
	PatchSkirmisherMelee();
	PatchZeroIn();
	PatchWhiplash();
	PatchSkirmisherInterrupt();
	PatchCombatPresence();
	PatchFullThrottle();
	PatchSkirmisherAmbush();
	PatchBattlelord();
	PatchSkirmisherReturnFire();
	PatchParkour();

	//PatchRetributionAttack();
	//PatchManualOverride();

	UpdateShotHUDPrioritiesForClass('Skirmisher');
}

// Necessary for some visualization fixes for the execute animations to line up properly.
static private function PatchJustice()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_GetOverHere_Fixed		GetOverHereEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Justice');
	if (AbilityTemplate == none)	
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_GetOverHere(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			GetOverHereEffect = new class'X2Effect_GetOverHere_Fixed';
 			GetOverHereEffect.OverrideStartAnimName = 'NO_GrapplePullStart';
 			GetOverHereEffect.OverrideStopAnimName = 'NO_GrapplePullStop';
			GetOverHereEffect.RequireVisibleTile = true;
			AbilityTemplate.AbilityTargetEffects.InsertItem(0, GetOverHereEffect);
			break;
		}
	}
}



static private function PatchSkirmisherAmbush()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ModifyReactionFire       ReactionFire;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherAmbush');
	if (AbilityTemplate == none)	
		return;

	ReactionFire = new class'X2Effect_ModifyReactionFire';
	ReactionFire.bAllowCrit = true;
	ReactionFire.BuildPersistentEffect(1, true, true, true);
	AbilityTemplate.AddTargetEffect(ReactionFire);
}

static private function PatchSkirmisherPostAbilityMelee()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_OverrideDeathAction		OverrideDeathAction;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherPostAbilityMelee');
	if (AbilityTemplate == none)	
		return;

	// Firaxis forgot (?) to change the icon, so it looks like slash.
	AbilityTemplate.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Reckoning";

	// Use skulljack animations for ripjack melee kill strikes when possible
	AbilityTemplate.BuildVisualizationFn = PredatorStrike_BuildVisualization;

	// Animations for this fire action are loaded by Perk Content for this ability.
	AbilityTemplate.ActionFireClass = class'X2Action_PredatorStrike';
	AbilityTemplate.CinescriptCameraType = "IRI_PredatorStrike_Camera";
	AbilityTemplate.bOverrideMeleeDeath = false;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_ApplyWeaponDamage(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			OverrideDeathAction = new class'X2Effect_OverrideDeathAction';
			OverrideDeathAction.DeathActionClass = class'X2Action_PredatorStrike_Death';
			OverrideDeathAction.EffectName = 'IRI_SK_PredatorStrike_DeathActionEffect';
			AbilityTemplate.AddTargetEffect(OverrideDeathAction);

			AbilityTemplate.AddTargetEffect(new class'X2Effect_PredatorStrike');

			break;
		}
	}
}

static private function PredatorStrike_BuildVisualization(XComGameState VisualizeGameState)
{	
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action						FireAction;
	local XComGameStateContext_Ability	AbilityContext;
	local X2Action_SnapTurn				MoveTurnAction;
	local VisualizationActionMetadata   ActionMetadata;
	local VisualizationActionMetadata   EmptyTrack;
	local XComGameStateHistory			History;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;
	local X2Action_PlayAnimation		PlayAnimation;
	//local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	//local X2Action						DeathAction;
	local TTile							TurnTileLocation;

	class'X2Ability'.static.TypicalAbility_BuildVisualization(VisualizeGameState);

	History = `XCOMHISTORY;
	VisMgr = `XCOMVISUALIZATIONMGR;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	TargetUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit == none)
		return;
	SourceUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (SourceUnit == none)
		return;

	FireAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_PredatorStrike',, AbilityContext.InputContext.SourceObject.ObjectID);
	if (FireAction == none)
		return;

	//	Make the shooter rotate towards the target. This doesn't always happen automatically in time.
	ActionMetadata = FireAction.Metadata;
	MoveTurnAction = X2Action_SnapTurn(class'X2Action_SnapTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, true, FireAction.ParentActions[0]));
	MoveTurnAction.m_vFacePoint =  `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
	//MoveTurnAction.UpdateAimTarget = true;

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(TargetUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = TargetUnit;
	ActionMetadata.VisualizeActor = History.GetVisualizer(TargetUnit.ObjectID);
		
	// Make target rotate towards the shooter, but on the same Z as the target, for better animation alignment.
	TurnTileLocation = SourceUnit.TileLocation;
	TurnTileLocation.Z = TargetUnit.TileLocation.Z;

	MoveTurnAction = X2Action_SnapTurn(class'X2Action_SnapTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, FireAction.ParentActions[0]));
	MoveTurnAction.m_vFacePoint =  `XWORLD.GetPositionFromTileCoordinates(TurnTileLocation);
	//MoveTurnAction.SyncZ = true;
	//MoveTurnAction.UpdateAimTarget = true;

	//	Make the target play its idle animation to prevent it from turning back to their original facing direction right away.
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, MoveTurnAction));
	PlayAnimation.Params.AnimName = 'HL_Idle';
	PlayAnimation.Params.BlendTime = 0.3f;		

	if (AbilityContext.IsResultContextMiss())
	{
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, FireAction.ParentActions[0]));
		PlayAnimation.Params.AnimName = 'FF_SkulljackedMiss';
		return;
	}

	//DeathAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_PredatorStrike_Death',, TargetUnit.ObjectID);
	//if (DeathAction != none)
	//{
	//	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, DeathAction));
	//	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'X2Effect_Executed'.default.UnitExecutedFlyover, '', eColor_Bad);
	//}
}

static private function PatchSkirmisherMelee()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherMelee');
	if (AbilityTemplate == none)	
		return;

	// Firaxis forgot (?) to change the icon, so it looks like slash.
	AbilityTemplate.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Reckoning";

	// Reset Cooldown
	AbilityTemplate.AbilityCooldown = none;
	AddCooldown(AbilityTemplate, `GetConfigInt("Reckoning_Cooldown"));

	// Replace action cost
	RemoveActionAndChargeCost(AbilityTemplate);

	// Fixed moving melee cost for abilities that don't end turn
	AbilityTemplate.AbilityCosts.AddItem(new class'X2AbilityCost_RN_SlashActionPoints');
}

static private function PatchFullThrottle()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ReduceCooldown			ReduceCooldown;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('FullThrottle');
	if (AbilityTemplate == none)
		return;

	ReduceCooldown = new class'X2Effect_ReduceCooldown';
	ReduceCooldown.AbilityName = 'SkirmisherGrapple';
	ReduceCooldown.ReduceCooldown = `GetConfigInt("FullThrottle_CooldownReduction");;
	AbilityTemplate.AddTargetEffect(ReduceCooldown);
}

static private function PatchZeroIn()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			AbilityTemplate;
	local X2Effect_ZeroIn_Fixed		ZeroInEffect;
	local X2Effect_Persistent		PersistentEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ZeroIn');
	if (AbilityTemplate == none)
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_ZeroIn(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			// Functionality and buff icon
			ZeroInEffect = new class'X2Effect_ZeroIn_Fixed';
			ZeroInEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnEnd);
			ZeroInEffect.SetDisplayInfo(ePerkBuff_Bonus, AbilityTemplate.LocFriendlyName, `GetLocalizedString("ZeroIn_Buff_Description"), AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(ZeroInEffect);

			// Passive icon
			PersistentEffect = new class'X2Effect_Persistent';
			PersistentEffect.BuildPersistentEffect(1, true);
			PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocHelpText, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(PersistentEffect);

			break;
		}
	}
}



static private function PatchSkirmisherInterrupt()
{
	local X2AbilityTemplateManager					AbilityMgr;
	local X2AbilityTemplate							AbilityTemplate;
	//local X2Effect_ReserveOverwatchPoints_NoCost	ReserveOverwatchPoints;
	local X2Effect_SkirmisherInterrupt_Fixed		InterruptEffect;
	local X2Condition_UnitEffects					EffectCondition;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherInterruptInput');
	if (AbilityTemplate == none)
		return;

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Interrupt_Cooldown"));

	// Disallow Interrupting while Battlelord is active
	EffectCondition = new class'X2Condition_UnitEffects';
	EffectCondition.AddExcludeEffect(class'X2Effect_Battlelord'.default.EffectName, 'AA_DuplicateEffectIgnored');
	AbilityTemplate.AbilityShooterConditions.AddItem(EffectCondition);

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherInterrupt');
	if (AbilityTemplate == none)
		return;

	// Replace the Interrupt Effect with an improved version that allows multiple units to interrupt at the same time.
	for (i = AbilityTemplate.AbilityShooterEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_SkirmisherInterrupt(AbilityTemplate.AbilityShooterEffects[i]) != none)
		{
			AbilityTemplate.AbilityShooterEffects.Remove(i, 1);

			InterruptEffect = new class'X2Effect_SkirmisherInterrupt_Fixed';
			InterruptEffect.BuildPersistentEffect(1, false, , , eGameRule_PlayerTurnBegin);
			AbilityTemplate.AddShooterEffect(InterruptEffect);

			break;
		}
	}
}

static private function PatchCombatPresence()
{
	local X2AbilityTemplateManager					AbilityMgr;
	local X2AbilityTemplate							AbilityTemplate;
	local X2Effect_SkirmisherInterrupt_Fixed		InterruptEffect;
	local X2Effect_GrantActionPoints				ActionPointEffect;
	local X2Condition_UnitEffectsOnSource			UnitEffects;
	local X2Effect_Battlelord_CombatPresence		BattlelordEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('CombatPresence');
	if (AbilityTemplate == none)
		return;

	// Allow using Combat Presence with Interrupt AP
	AddActionPointNameToActionCost(AbilityTemplate, class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);

	// Make the original action point effect work only while NOT interrupting.
	// (Still gives it while Battlelording)
	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_GrantActionPoints(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			UnitEffects = new class'X2Condition_UnitEffectsOnSource';
			UnitEffects.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');

			AbilityTemplate.AbilityTargetEffects[i].TargetConditions.AddItem(UnitEffects);
			break;
		}
	}

	// When used while Battlelording, make the target unit enter Battlelord for one action too.
	BattlelordEffect = new class'X2Effect_Battlelord_CombatPresence';
	BattlelordEffect.BuildPersistentEffect(1, false, , , eGameRule_PlayerTurnBegin);

	UnitEffects = new class'X2Condition_UnitEffectsOnSource';
	UnitEffects.AddRequireEffect(class'X2Effect_Battlelord'.default.EffectName, 'AA_AbilityUnavailable');
	BattlelordEffect.TargetConditions.AddItem(UnitEffects);
	AbilityTemplate.AbilityTargetEffects.InsertItem(0, BattlelordEffect);

	// When used while Interrupting, make the target unit Interrupt too.
	InterruptEffect = new class'X2Effect_SkirmisherInterrupt_Fixed';
	InterruptEffect.BuildPersistentEffect(1, false, , , eGameRule_PlayerTurnBegin);

	UnitEffects = new class'X2Condition_UnitEffectsOnSource';
	UnitEffects.AddRequireEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	InterruptEffect.TargetConditions.AddItem(UnitEffects);
	AbilityTemplate.AbilityTargetEffects.InsertItem(0, InterruptEffect);

	// Give the Interrupt point while Interrupting, doh
	ActionPointEffect = new class'X2Effect_GrantActionPoints';
	ActionPointEffect.NumActionPoints = 1;
	ActionPointEffect.PointType = class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint;
	ActionPointEffect.bSelectUnit = true;
	ActionPointEffect.TargetConditions.AddItem(UnitEffects);
	AbilityTemplate.AddTargetEffect(ActionPointEffect);
}

static private function PatchSkirmisherReflex()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_SkirmisherReflex_Fixed	ReflexEffect;
	local X2Effect_SkirmisherReflex_Tracker	TrackerEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherReflex');
	if (AbilityTemplate == none)
		return;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_SkirmisherReflex(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			ReflexEffect = new class'X2Effect_SkirmisherReflex_Fixed';
			ReflexEffect.BuildPersistentEffect(1, true, false, false);
			ReflexEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(ReflexEffect);

			TrackerEffect = new class'X2Effect_SkirmisherReflex_Tracker';
			TrackerEffect.BuildPersistentEffect(1, true, false, false);
			TrackerEffect.SetDisplayInfo(ePerkBuff_Penalty, AbilityTemplate.LocFriendlyName, default.strReflexSpent, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(TrackerEffect);

			break;
		}
	}
}

static private function PatchRetributionAttack()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('RetributionAttack');
	if (AbilityTemplate == none)
		return;

	AddCooldown(AbilityTemplate, `GetConfigInt("Retribution_Cooldown"));
}


static private function PatchBattlelord()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_Battlelord_Fixed		BattlelordEffect;
	local X2Condition_UnitActionPoints	ActionPointCondition;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Battlelord');
	if (AbilityTemplate == none)
		return;

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Battlelord_Cooldown"));

	// When interrupt is activated by the player, it just gives the unit a reserve action point.
	// Actual interrupt effect will be applied when interrupting. So have to check for the action point.
	ActionPointCondition = new class'X2Condition_UnitActionPoints';
	ActionPointCondition.AddActionPointCheck(1, 'ReserveInterrupt', true, eCheck_LessThan, 1);
	AbilityTemplate.AbilityShooterConditions.AddItem(ActionPointCondition);

	// Replace the Battlelord effect with one that allows multiple units to Battlelord now.
	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Battlelord(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			BattlelordEffect = new class'X2Effect_Battlelord_Fixed';
			BattlelordEffect.BuildPersistentEffect(1, false, , , eGameRule_PlayerTurnBegin);
			BattlelordEffect.SetDisplayInfo(ePerkBuff_Bonus, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocLongDescription, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(BattlelordEffect);

			break;
		}
	}
}


static private function PatchParkour()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate; 
	local X2Effect_Parkour_GrantActionPoint	Effect;
	// local X2Effect_GrantActionPoints		AddActionPointsEffect;
	// local X2AbilityTrigger_EventListener	ActivationTrigger;
	// local X2Effect							Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Parkour');
	if (AbilityTemplate == none)
		return;

	Effect = new class'X2Effect_Parkour_GrantActionPoint';
	Effect.BuildPersistentEffect(1, true);
	AbilityTemplate.AddTargetEffect(Effect);

	// AbilityTemplate.AbilityTriggers.Length = 0;
	// ActivationTrigger = new class'X2AbilityTrigger_EventListener';
	// ActivationTrigger.ListenerData.EventID = 'IRI_SkirmisherGrappleActivated';
	// ActivationTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	// ActivationTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	// ActivationTrigger.ListenerData.Filter = eFilter_Unit;
	// AbilityTemplate.AbilityTriggers.AddItem(ActivationTrigger);
	// 
	// foreach AbilityTemplate.AbilityShooterEffects(Effect)
	// {
	// 	AddActionPointsEffect = X2Effect_GrantActionPoints(Effect);
	// 	if (AddActionPointsEffect == none)
	// 		continue;
	// 
	// 	AddActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;
	// }
	// 
	// AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherGrapple');
	// if (AbilityTemplate == none)
	// 	return;
	// 
	// AbilityTemplate.PostActivationEvents.AddItem('IRI_SkirmisherGrappleActivated');
}

static private function PatchWhiplash()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Whiplash');
	if (AbilityTemplate == none)
		return;

	// Assign Whiplash to Ripjack so it can take damage values from it.
	AbilityTemplate.DefaultSourceItemSlot = eInvSlot_SecondaryWeapon;

	// Counteract the Ripjack's built-in Aim bonus.
	X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc).BuiltInHitMod -= 20;

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		DamageEffect = X2Effect_ApplyWeaponDamage(AbilityTemplate.AbilityTargetEffects[i]);
		if (DamageEffect == none)
			continue;

		if (DamageEffect.EffectDamageValue == class'X2Ability_SkirmisherAbilitySet'.default.WHIPLASH_BASEDAMAGE)
		{	
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);
		}
	}

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.bIgnoreArmor = true;
	DamageEffect.DamageTag = 'Whiplash';
	AbilityTemplate.AddTargetEffect(DamageEffect);

	AbilityTemplate.AdditionalAbilities.AddItem('IRI_SK_Whiplash_BonusDamage');
	
	// This ability shouldn't be ever visible to the player, but let's be nice.
	CopyLocalization('IRI_SK_Whiplash_BonusDamage', 'Whiplash');

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Whiplash_Cooldown"));
}

static private function PatchSkirmisherReturnFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ReturnFire				FireEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherReturnFire');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.IconImage = "img:///IRIClassReworkUI.perk_ReturnFire"; // Icon copied from PCP with permission

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		FireEffect = X2Effect_ReturnFire(AbilityTemplate.AbilityTargetEffects[i]);
		if (FireEffect != none)
		{
			FireEffect.MaxPointsPerTurn = 999; 
			break;
		}
	}
}

// Alternative implementation - makes Manual Override temporarily remove cooldowns from all abilities that have them, then restore them next turn.
/*
static private function PatchManualOverride()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_Persistent				PersistentEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('ManualOverride');
	if (AbilityTemplate == none)	
		return;

	RemoveActionAndChargeCost(AbilityTemplate);
	AddFreeActionCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("ManualOverride_Cooldown"));

	for (i = AbilityTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_ManualOverride(AbilityTemplate.AbilityTargetEffects[i]) != none)
		{
			AbilityTemplate.AbilityTargetEffects.Remove(i, 1);

			PersistentEffect = new class'X2Effect_Persistent';
			PersistentEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
			PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.LocHelpText, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			PersistentEffect.EffectAddedFn = ManualOverride_EffectAdded;
			PersistentEffect.EffectRemovedFn = ManualOverride_EffectRemoved;
			AbilityTemplate.AddTargetEffect(PersistentEffect);

			break;
		}
	}
}

static private function ManualOverride_EffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit		UnitState;
	local StateObjectReference		AbilityRef;
	local XComGameState_Ability		AbilityState;
	local XComGameStateHistory		History;
	local name						ValueName;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == none)
		return;

	History = `XCOMHISTORY;

	foreach UnitState.Abilities(AbilityRef)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState == none)
			continue;

		if (!AbilityHasActionCost(AbilityState, UnitState))
			continue;

		ValueName = name(AbilityState.GetMyTemplateName() @ "_IRI_MO_Cooldown");
		UnitState.SetUnitFloatValue(ValueName, AbilityState.iCooldown, eCleanup_BeginTactical);

		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
		AbilityState.iCooldown = 0;
	}
}
static private function bool AbilityHasActionCost(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit)
{
	local X2AbilityCost					Cost;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2AbilityTemplate				Template;

	Template = AbilityState.GetMyTemplate();
	if (Template == none)
		return false;

	foreach Template.AbilityCosts(Cost)
	{
		ActionPointCost = X2AbilityCost_ActionPoints(Cost);
		if (ActionPointCost == none)
			continue;

		if (ActionPointCost.bFreeCost)
			continue;

		if (ActionPointCost.ConsumeAllPoints(AbilityState, SourceUnit) ||
			ActionPointCost.GetPointCost(AbilityState, SourceUnit) > 0)
		{
			return true;
		}
	}
	return false;
}

static private function ManualOverride_EffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit		UnitState;
	local StateObjectReference		AbilityRef;
	local XComGameState_Ability		AbilityState;
	local XComGameStateHistory		History;
	local name						ValueName;	
	local UnitValue					UV;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
		return;

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

	foreach UnitState.Abilities(AbilityRef)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState == none)
			continue;

		ValueName = name(AbilityState.GetMyTemplateName() @ "_IRI_MO_Cooldown");
		if (!UnitState.GetUnitValue(ValueName, UV))
			continue;

		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
		AbilityState.iCooldown = UV.fValue - 1;
		if (AbilityState.iCooldown < 0)
			AbilityState.iCooldown = 0;

		UnitState.ClearUnitValue(ValueName);
	}
}*/