class X2Effect_ReturnFireIgnoresCover extends X2Effect_Persistent;

function bool UniqueToHitModifiers() 
{
	return true; 
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{	
	local ShotModifierInfo					ModInfo;
	local GameRulesCache_VisibilityInfo		VisInfo;
	local XComGameState_Ability				AppliedAbility;
	local X2AbilityToHitCalc_StandardAim	StandardAim;

	// Only from the same weapon
	if (EffectState.ApplyEffectParameters.ItemStateObjectRef != AbilityState.SourceWeapon) 
		return;

	// Only for Reaction Fire
	StandardAim = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);
	if (StandardAim == none || !StandardAim.bReactionFire)
		return;

	//	Compensate aim penalty for shooting through cover
	//	This method of getting target cover seems to be most reliable
	if (Target.CanTakeCover() && `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo))
	{	
		//`LOG("Attacker:" @ Attacker.GetFullName() @ "Target:" @ Target.GetFullName() @ "Cover:" @ VisInfo.TargetCover @ "Ability:" @ AbilityState.GetMyTemplateName(),, 'WOTCMoreSparkWeapons');
		switch (VisInfo.TargetCover)
		{
			case CT_MidLevel:
				AppliedAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

				ModInfo.ModType = eHit_Success;
				ModInfo.Reason = AppliedAbility != none ? AppliedAbility.GetMyTemplate().LocFriendlyName : "";
				ModInfo.Value = class'X2AbilityToHitCalc_StandardAim'.default.LOW_COVER_BONUS;
				ShotModifiers.AddItem(ModInfo);
				break;
			case CT_Standing:
				AppliedAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
				
				ModInfo.ModType = eHit_Success;
				ModInfo.Reason = AppliedAbility != none ? AppliedAbility.GetMyTemplate().LocFriendlyName : "";
				ModInfo.Value = class'X2AbilityToHitCalc_StandardAim'.default.HIGH_COVER_BONUS;
				ShotModifiers.AddItem(ModInfo);
				break;
			default:
				break;
		}
	}
}

defaultproperties
{
	iNumTurns = 1
	bInfiniteDuration = true
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_ReturnFireIgnoresCover_Effect"
}