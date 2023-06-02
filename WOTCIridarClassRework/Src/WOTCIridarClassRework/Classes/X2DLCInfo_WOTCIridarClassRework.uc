class X2DLCInfo_WOTCIridarClassRework extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	PatchFullThrottle();
	PatchZeroIn();
	PatchSkirmisherReflex();
	PatchBattlelord();
	PatchWhiplash();
	PatchParkour();
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
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ZeroIn_Fixed				ZeroInEffect;
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

			ZeroInEffect = new class'X2Effect_ZeroIn_Fixed';
			ZeroInEffect.BuildPersistentEffect(1, true, false, false);
			ZeroInEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyHelpText(), AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(ZeroInEffect);

			break;
		}
	}
}



static private function PatchSkirmisherInterrupt()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherInterruptInput');
	if (AbilityTemplate == none)
		return;

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Interrupt_Cooldown"));
}

static private function PatchSkirmisherReflex()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_SkirmisherReflex_Fixed	ReflexEffect;
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
			ReflexEffect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
			AbilityTemplate.AddTargetEffect(ReflexEffect);

			break;
		}
	}
}

static private function PatchBattlelord()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Battlelord');
	if (AbilityTemplate == none)
		return;

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Battlelord_Cooldown"));
}


static private function PatchParkour()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate; 
	local X2Effect_GrantActionPoints		AddActionPointsEffect;
	local X2AbilityTrigger_EventListener	ActivationTrigger;
	local X2Effect							Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Parkour');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.AbilityTriggers.Length = 0;
	ActivationTrigger = new class'X2AbilityTrigger_EventListener';
	ActivationTrigger.ListenerData.EventID = 'IRI_SkirmisherGrappleActivated';
	ActivationTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	ActivationTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	ActivationTrigger.ListenerData.Filter = eFilter_Unit;
	AbilityTemplate.AbilityTriggers.AddItem(ActivationTrigger);

	foreach AbilityTemplate.AbilityShooterEffects(Effect)
	{
		AddActionPointsEffect = X2Effect_GrantActionPoints(Effect);
		if (AddActionPointsEffect == none)
			continue;

		AddActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.MoveActionPoint;
	}

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SkirmisherGrapple');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.PostActivationEvents.AddItem('IRI_SkirmisherGrappleActivated');
}

static private function PatchWhiplash()
{
	local X2AbilityTemplateManager		AbilityMgr;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local X2Condition_UnitProperty		OnlyOrganic;
	local X2Condition_UnitProperty		OnlyRobotic;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Whiplash');
	if (AbilityTemplate == none)
		return;

	AbilityTemplate.DefaultSourceItemSlot = eInvSlot_SecondaryWeapon;

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

	OnlyOrganic = new class'X2Condition_UnitProperty';
	OnlyOrganic.ExcludeRobotic = true;
	OnlyOrganic.ExcludeOrganic = false;

	OnlyRobotic = new class'X2Condition_UnitProperty';
	OnlyRobotic.ExcludeRobotic = false;
	OnlyRobotic.ExcludeOrganic = true;

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'Whiplash';
	DamageEffect.TargetConditions.AddItem(OnlyOrganic);
	AbilityTemplate.AddTargetEffect(DamageEffect);

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'Whiplash_Robotic';
	DamageEffect.TargetConditions.AddItem(OnlyRobotic);
	AbilityTemplate.AddTargetEffect(DamageEffect);

	RemoveChargeCost(AbilityTemplate);
	AddCooldown(AbilityTemplate, `GetConfigInt("Whiplash_Cooldown"));
	
}

static private function RemoveChargeCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	AbilityTemplate.AbilityCharges = none;

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_Charges(AbilityTemplate.AbilityCosts[i]) != none)
		{
			AbilityTemplate.AbilityCosts.Remove(i, 1);
		}
	}
}

static private function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}