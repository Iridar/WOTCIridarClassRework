class Templar extends Common;

static final function PatchAbilities()
{
	PatchRend();
	PatchAmplify();
	PatchVolt();
	PatchTemplarBladestorm();
	PatchVoidConduit();
	PatchTemplarExchange();
	PatchTemplarInvert();
	PatchPillar();
	PatchStunStrike();
	PatchArcWave();
	PatchParryActivate();
	PatchDeflect();
	PatchReflectShot();
	PatchGhost();

	UpdateShotHUDPrioritiesForClass('Templar');
}

static private function PatchGhost()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				Template;
	local X2Effect_SpawnGhost_Fixed		GhostEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Ghost');
	if (Template == none)	
		return;

	RemoveChargeCost(Template);
	AddCooldown(Template, `GetConfigInt("IRI_TM_Ghost_Cooldown"));
	MakeNotEndTurn(Template);
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	
	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_SpawnGhost(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);

			GhostEffect = new class'X2Effect_SpawnGhost_Fixed';
			GhostEffect.BuildPersistentEffect(1, true, true);
			Template.AddTargetEffect(GhostEffect);
			break;
		}
	}
}

static private function PatchPillar()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				Template;
	local X2Effect_Pillar				PillarEffect;
	local X2Effect						Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Pillar');
	if (Template == none)	
		return;

	MakeFreeActionCost(Template);

	// Set cast range to 18 tiles = Templar's vision range.
	X2AbilityTarget_Cursor(Template.AbilityTargetStyle).FixedAbilityRange = `TILESTOMETERS(`GetConfigInt("IRI_TM_Pillar_CastRange_Tiles"));

	// Pillar has a bug where it doesn't provide cover to units if summoned on an adjacent tile to them. Some code floating around the community that's supposed to fix it - doesn't.
	// After much headbanging I wasn't able to figure out how to fix it.
	// So as a workaround, I just forbid summoning Pillar near units.
	Template.TargetingMethod = class'X2TargetingMethod_Pillar_Fixed';

	// Show Pillar's duration on the shooter
	foreach Template.AbilityShooterEffects(Effect)
	{
		PillarEffect = X2Effect_Pillar(Effect);
		if (PillarEffect == none)
			continue;

		PillarEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
		break;
	}

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
}

static private function PatchAmplify()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				Template;
	local X2AbilityTag					AbilityTag;
	local X2Effect_Amplify_Fixed		AmplifyEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Amplify');
	if (Template == none)	
		return;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Amplify(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);

			AmplifyEffect = new class'X2Effect_Amplify_Fixed';
			AmplifyEffect.BuildPersistentEffect(1, true, true);
			AmplifyEffect.bRemoveWhenTargetDies = true;
			AmplifyEffect.BonusDamageMult = class'X2Ability_TemplarAbilitySet'.default.AmplifyBonusDamageMult;
			AmplifyEffect.MinBonusDamage = class'X2Ability_TemplarAbilitySet'.default.AmplifyMinBonusDamage;
	
			AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
			AbilityTag.ParseObj = AmplifyEffect;
			AmplifyEffect.SetDisplayInfo(ePerkBuff_Penalty, class'X2Ability_TemplarAbilitySet'.default.AmplifyEffectName, `XEXPAND.ExpandString(class'X2Ability_TemplarAbilitySet'.default.AmplifyEffectDesc), Template.IconImage, true, , Template.AbilitySourceName);
			AbilityTag.ParseObj = none;

			Template.AddTargetEffect(AmplifyEffect);
			break;
		}
	}
}


static private function PatchRend()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Rend');
	if (Template == none)	
		return;

	Template.IconImage = "img:///IRIClassReworkUI.UIPerk_Rend_New";
}

static private function PatchArcWave()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('ArcWave');
	if (Template == none)	
		return;

	Template.bSkipMoveStop = true;
}

static private function PatchTemplarInvert()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('TemplarInvert');
	if (Template == none)	
		return;

	RemoveFocusCost(Template);
	AddActionPointNameToActionCost(Template, class'X2CharacterTemplateManager'.default.MomentumActionPoint);
}
static private function PatchTemplarExchange()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Condition						Condition;
	local X2Condition_UnitProperty			SquadmateCondition;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('TemplarExchange');
	if (Template == none)	
		return;

	foreach Template.AbilityTargetConditions(Condition)
	{
		SquadmateCondition = X2Condition_UnitProperty(Condition);
		if (SquadmateCondition == none)
			continue;

		SquadmateCondition.ExcludeTurret = true;
	}

	RemoveFocusCost(Template);
	AddActionPointNameToActionCost(Template, class'X2CharacterTemplateManager'.default.MomentumActionPoint);
}

static private function PatchVolt()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect							Effect;
	local X2Effect_ToHitModifier			ToHitModifier;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Volt');
	if (Template == none)	
		return;

	// Prevent Aftershock from stacking with itself.
	foreach Template.AbilityTargetEffects(Effect)
	{
		ToHitModifier = X2Effect_ToHitModifier(Effect);
		if (ToHitModifier == none)
			continue;

		ToHitModifier.DuplicateResponse = eDupe_Refresh;
	}

	MakeNotEndTurn(Template);
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	// The original delegate passes 'false' in "as primary target" parameter, which makes the damage preview disregard effects applied to the target.
	// Pretty bizarre design decision tbh.
	Template.DamagePreviewFn = VoltDamagePreview_Fixed;

	//Template.AddTargetEffect(GetSealEffect());
}

static private function bool VoltDamagePreview_Fixed(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
	if (TargetUnit != none)
	{
		if (TargetUnit.IsPsionic())
		{
			AbilityState.GetMyTemplate().AbilityTargetEffects[1].GetDamagePreview(TargetRef, AbilityState, true, MinDamagePreview, MaxDamagePreview, AllowsShield);
		}
		else
		{
			AbilityState.GetMyTemplate().AbilityTargetEffects[0].GetDamagePreview(TargetRef, AbilityState, true, MinDamagePreview, MaxDamagePreview, AllowsShield);
		}		
		return true;
	}
	return false;
}

static private function PatchTemplarBladestorm()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect							Effect;
	local X2Effect_Persistent				PersistentEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('TemplarBladestorm');
	if (Template == none)	
		return;

	Template.IconImage = "img:///IRIClassReworkUI.UIPerk_Zeal";

	foreach Template.AbilityTargetEffects(Effect)
	{
		PersistentEffect = X2Effect_Persistent(Effect);
		if (PersistentEffect == none)
			continue;

		PersistentEffect.IconImage = "img:///IRIClassReworkUI.UIPerk_Zeal";
	}

	Template = AbilityMgr.FindAbilityTemplate('TemplarBladestormAttack');
	if (Template == none)	
		return;

	Template.IconImage = "img:///IRIClassReworkUI.UIPerk_Zeal";

	//Template.AddTargetEffect(GetSealEffect());
}

static private function PatchStunStrike()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2Effect_Persistent				PersistentEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('StunStrike');
	if (Template == none)	
		return;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		//if (X2Effect_Knockback(Template.AbilityTargetEffects[i]) != none)
		//{
		//	Template.AbilityTargetEffects.Remove(i, 1);
		//}

		PersistentEffect = X2Effect_Persistent(Template.AbilityTargetEffects[i]);

		if (PersistentEffect != none && PersistentEffect.EffectName == class'X2AbilityTemplateManager'.default.DisorientedName)
		{
			Template.AbilityTargetEffects.Remove(i, 1);
			Template.AddTargetEffect(class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, false));
			break;
		}
	}

	Template.AbilityToHitCalc = default.DeadEye;

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;	

	//Template.AddTargetEffect(new class'X2Effect_ReliableKnockback');
	//Template.AddTargetEffect(GetSealEffect());
}

// Seal effect doesn't exist in the Class Rework, only in the perk pack, so copy it from the new Rend ability template.
static private function X2Effect GetSealEffect()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					RendTemplate;
	local X2Effect							SealEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	RendTemplate = AbilityMgr.FindAbilityTemplate('IRI_TM_Rend');
	if (RendTemplate == none)
		return none;

	for (i = RendTemplate.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Persistent(RendTemplate.AbilityTargetEffects[i]).EffectName == 'IRI_TM_Seal_Effect')
		{
			SealEffect = RendTemplate.AbilityTargetEffects[i];

			return SealEffect;
		}
	}

	return none;
}

// Patch Parry to be uninterruptble and not offensive
static private function PatchParryActivate()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;
	local X2Effect_Parry_Fixed		Effect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('ParryActivate');
	if (Template == none)	
		return;

	Template.Hostility = eHostility_Defensive;
	Template.BuildInterruptGameStateFn = none;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Parry(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);

			Effect = new class'X2Effect_Parry_Fixed';
			Effect.BuildPersistentEffect(1, true, false);
			Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
			Template.AddTargetEffect(Effect);

			break;
		}
	}
}
// // New rules:
// If soldier has Reflect and Focus at 2 or greater, it will roll a chance to Reflect.
// If the roll fails or soldier has no Reflect and soldier is at 1 Focus or above, it will roll a chance to Deflect.
// If both rolls fail, Templar will Parry. Deflect and Reflect don't happen on misses, but Parry will always be expended even if the attack naturally missed.
// Reflected attack will use Templar's Aim to hit and ignore target's cover Defense bonus.
static private function PatchDeflect()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local X2AbilityTemplate			Template;
	local X2Effect_Deflect_Fixed	Effect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('Deflect');
	if (Template == none)	
		return;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_Deflect(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);

			Effect = new class'X2Effect_Deflect_Fixed';
			Effect.BuildPersistentEffect(1, true, false);
			Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
			Template.AddTargetEffect(Effect);

			break;
		}
	}
}
static private function PatchReflectShot()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					Template;
	local X2AbilityToHitCalc_StandardAim	StandardAim;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('ReflectShot');
	if (Template == none)	
		return;

	Template.BuildInterruptGameStateFn = none; // This shouldn't be interruptible.

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIgnoreCoverBonus = true;
	Template.AbilityToHitCalc = StandardAim;
}


// Void Conduit is a mess in vanilla and sucks for actually disabling the enemy.
// 1 Focus: enemy dealt 3 damage immediately, then ticks for 2 damage/lifesteal, then enemy takes their turn
// 2 Focus: enemy dealt 3 damage immediately, then ticks for 4 damage/lifesteal, then enemy takes their turn
// 3 Focus: enemy dealt 3 damage immediately, then ticks for 4 damage/lifesteal, then enemy skips their turn. At the start of the next enemy turn, enemy ticks for 2 damage/lifesteal, then enemy takes their turn.
// So you need to cast it at 3 Focus to make the enemy skip one turn, otherwise the enemy isn't even disabled.
// How it works now:
// 1 Focus: 2 damage/lifesteal immediately, then enemy skips their turn, then ticks for 2 damage/lifesteal at the start of the player's turn.
// With more Focus behavior is the same, just add additional turn skips / ticks.

static private function PatchVoidConduit()
{
	local X2AbilityTemplateManager				AbilityMgr;
	local X2AbilityTemplate						Template;
	local X2Effect_PersistentVoidConduit_Fixed	PersistentEffect;
	local X2Effect_VoidConduit_Fixed			TickEffect;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('VoidConduit');
	if (Template == none)	
		return;

	Template.IconImage = "img:///IRIClassReworkUI.UIPerk_VoidConduit_New";

	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	{
		if (X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]) != none)
		{
			Template.AbilityTargetEffects.Remove(i, 1);

			PersistentEffect = new class'X2Effect_PersistentVoidConduit_Fixed';
			PersistentEffect.InitialDamage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitInitialDamage;
			PersistentEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin); // Actual duration is determined by a function inside the effect
			PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false, , Template.AbilitySourceName);
			PersistentEffect.bRemoveWhenTargetDies = true;
			PersistentEffect.bUseSourcePlayerState = true; // Makes it tick relative to player's turn, so the enemy unit properly skips their turn
			PersistentEffect.EffectTickedFn = none;

			//	build the per tick damage effect
			TickEffect = new class'X2Effect_VoidConduit_Fixed';
			TickEffect.DamagePerAction = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage;
			TickEffect.HealthReturnMod = class'X2Ability_TemplarAbilitySet'.default.VoidConduitHPMod;
			Template.AddTargetEffect(TickEffect);

			PersistentEffect.ApplyOnTick.AddItem(TickEffect);
			Template.AddTargetEffect(PersistentEffect);
			
			break;
		}
	}

	Template.DamagePreviewFn = VoidConduitDamagePreview;
	


	//// Remove AP cost and increase Focus cost
	//for (i = Template.AbilityCosts.Length - 1; i >= 0; i--)
	//{
	//	if (X2AbilityCost_ActionPoints(Template.AbilityCosts[i]) != none)
	//	{
	//		X2AbilityCost_ActionPoints(Template.AbilityCosts[i]).bFreeCost = true;
	//		X2AbilityCost_ActionPoints(Template.AbilityCosts[i]).AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	//	} 
	//	else if (X2AbilityCost_Focus(Template.AbilityCosts[i]) != none)
	//	{
	//		X2AbilityCost_Focus(Template.AbilityCosts[i]).FocusAmount = `GetConfigInt("IRI_TM_VoidConduit_FocusCost");
	//	}
	//}

	// // Remove cooldown.
	// Template.AbilityCooldown = none;
	// 
	// for (i = Template.AbilityTargetEffects.Length - 1; i >= 0; i--)
	// {
	// 	if (X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]) != none)
	// 	{
	// 		X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).bInfiniteDuration = false;
	// 		X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).WatchRule = eGameRule_PlayerTurnEnd;
	// 		X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).iNumTurns = 1;
	// 		X2Effect_PersistentVoidConduit(Template.AbilityTargetEffects[i]).EffectTickedFn = none;
	// 	}
	// }

	//	build the persistent effect
	//PersistentEffect = new class'X2Effect_PersistentVoidConduit_Fixed';
	//PersistentEffect.InitialDamage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitInitialDamage;
	//PersistentEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	//PersistentEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false, , Template.AbilitySourceName);
	//PersistentEffect.bRemoveWhenTargetDies = true;
	//
	////	build the per tick damage effect
	//TickEffect = new class'X2Effect_VoidConduit';
	//TickEffect.DamagePerAction = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage;
	//TickEffect.HealthReturnMod = class'X2Ability_TemplarAbilitySet'.default.VoidConduitHPMod;
	//PersistentEffect.ApplyOnTick.AddItem(TickEffect);
	//Template.AddTargetEffect(PersistentEffect);
	
	
	//
	//Template.AddTargetEffect(GetSealEffect());
}

static private function bool VoidConduitDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	MinDamagePreview.Damage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage;
	MaxDamagePreview.Damage = class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage;
	return true;
}
