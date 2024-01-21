class Ranger extends Common;

static final function PatchAbilities()
{
	//PatchSwordSlice();
	PatchPhantom();
	PatchRapidFire();
	PatchGuardianForIntercept();
	PatchShadowstrike();
	PatchUntouchable();
	PatchDeepCover();
}

// Necessary only in a scenario where Slash doesn't end turn.
//static private function PatchSwordSlice()
//{
//	local X2AbilityTemplateManager			AbilityMgr;
//	local X2AbilityTemplate					AbilityTemplate;
//
//	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
//	AbilityTemplate = AbilityMgr.FindAbilityTemplate('SwordSlice');
//	if (AbilityTemplate == none)	
//		return;
//
//	RemoveActionAndChargeCost(AbilityTemplate);
//
//	AbilityTemplate.AbilityCosts.AddItem(new class'X2AbilityCost_RN_SlashActionPoints');
//}

static private function PatchDeepCover()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2AbilityTemplate					HunkerDownAbility;
	local X2AbilityTemplate					DeepCoverAbility;
	local X2Effect_UntouchableBuff			UntouchableBuff;
	local string							strEffectDesc;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	DeepCoverAbility = AbilityMgr.FindAbilityTemplate('DeepCover');
	if (DeepCoverAbility == none)	
		return;

	DeepCoverAbility.AdditionalAbilities.AddItem('IRI_RN_DeepCover_ArmorBonus');
	
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('IRI_RN_DeepCover_ArmorBonus');
	if (AbilityTemplate == none)	
		return;
	
	// Easer to add this effect in OPTC so I can use Hunker Down's original localization.
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.EffectName = 'IRI_RN_DeepCover_ArmorBonus';
	PersistentStatChangeEffect.BuildPersistentEffect(1,,,, eGameRule_PlayerTurnBegin);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Bonus, DeepCoverAbility.LocFriendlyName, DeepCoverAbility.GetMyHelpText(), DeepCoverAbility.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, `GetConfigInt("IRI_DeepCover_ArmorBonus"));
	PersistentStatChangeEffect.DuplicateResponse = eDupe_Refresh;
	AbilityTemplate.AddTargetEffect(PersistentStatChangeEffect);
}


static private function PatchUntouchable()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_UntouchableBuff			UntouchableBuff;
	local string							strEffectDesc;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Untouchable');
	if (AbilityTemplate == none)	
		return;

	if (GetLanguage() == "INT")
	{
		strEffectDesc = `GetLocalizedString("Untouchable_Buff_Description");
	}
	else
	{
		strEffectDesc = AbilityTemplate.GetMyLongDescription();
	}
	UntouchableBuff = new class'X2Effect_UntouchableBuff';
	
	UntouchableBuff.SetDisplayInfo(ePerkBuff_Bonus, AbilityTemplate.LocFriendlyName, strEffectDesc, AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(UntouchableBuff);
}

static private function PatchShadowstrike()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_ToHitModifier			ToHitModifier;
	local X2Effect							TargetEffect;
	local X2Effect_ShadowstrikeBuff			ShadowstrikeBuff;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Shadowstrike');
	if (AbilityTemplate == none)	
		return;

	foreach AbilityTemplate.AbilityTargetEffects(TargetEffect)
	{
		ToHitModifier = X2Effect_ToHitModifier(TargetEffect);
		if (ToHitModifier == none)
			continue;

		//ToHitModifier.bDisplayInSpecialDamageMessageUI = true; // Works only when modifying damage.

		for (i = ToHitModifier.ToHitConditions.Length - 1; i >= 0; i--)
		{
			if (X2Condition_Visibility(ToHitModifier.ToHitConditions[i]) != none)
			{
				ToHitModifier.ToHitConditions.Remove(i, 1);

				ToHitModifier.ToHitConditions.AddItem(new class'X2Condition_SourceIsConcealed');
				break;
			}
		}
		//break;
	}

	ShadowstrikeBuff = new class'X2Effect_ShadowstrikeBuff';
	ShadowstrikeBuff.SetDisplayInfo(ePerkBuff_Bonus, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, true, , AbilityTemplate.AbilitySourceName);
	AbilityTemplate.AddTargetEffect(ShadowstrikeBuff);

	AbilityTemplate.AdditionalAbilities.AddItem('IRI_RN_Shadowstrike_OnBreakConcealment');
}

static private function PatchGuardianForIntercept()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_Guardian					GuardianEffect;
	local X2DataTemplate					DataTemplate;
	local X2Effect							Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach AbilityMgr.IterateTemplates(DataTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(DataTemplate);
		if (AbilityTemplate == none)
			continue;

		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			GuardianEffect = X2Effect_Guardian(Effect);
			if (GuardianEffect == none)
				continue;

			GuardianEffect.AllowedAbilities.AddItem('IRI_RN_Intercept_Attack');
		}

		foreach AbilityTemplate.AbilityShooterEffects(Effect)
		{
			GuardianEffect = X2Effect_Guardian(Effect);
			if (GuardianEffect == none)
				continue;

			GuardianEffect.AllowedAbilities.AddItem('IRI_RN_Intercept_Attack');
		}

		foreach AbilityTemplate.AbilityMultiTargetEffects(Effect)
		{
			GuardianEffect = X2Effect_Guardian(Effect);
			if (GuardianEffect == none)
				continue;

			GuardianEffect.AllowedAbilities.AddItem('IRI_RN_Intercept_Attack');
		}
	}
}

static private function PatchPhantom()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_PersistentStatChange		Effect;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Phantom');
	if (AbilityTemplate == none)	
		return;

	//AbilityTemplate.AdditionalAbilities.AddItem('IRI_RN_ConcealDetectionRadiusReduction');

	Effect = new class'X2Effect_PersistentStatChange';
	Effect.AddPersistentStatChange(eStat_DetectionModifier, `GetConfigFloat("IRI_Conceal_DetectionRadiusModifier")); // MODOP_PostMultiplication doesn't work.
	Effect.SetDisplayInfo(ePerkBuff_Passive, AbilityTemplate.LocFriendlyName, AbilityTemplate.GetMyLongDescription(), AbilityTemplate.IconImage, false, , AbilityTemplate.AbilitySourceName);
	Effect.BuildPersistentEffect(1, true);
	AbilityTemplate.AddTargetEffect(Effect);
}

static private function PatchRapidFire()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('RapidFire');
	if (AbilityTemplate == none)	
		return;

	AddCooldown(AbilityTemplate, `GetConfigFloat("IRI_RapidFire_Cooldown"));
}