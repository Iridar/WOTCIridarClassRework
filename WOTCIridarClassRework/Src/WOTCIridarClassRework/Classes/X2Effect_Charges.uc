class X2Effect_Charges extends X2Effect;

// Currently unused.

var array<name>	AbilityNames;

var int		Charges;
var bool	bSetCharges;
var bool	bRespectInitialCharges;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	UnitState;
	local name					AbilityName;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == none)
		return;

	foreach AbilityNames(AbilityName)
	{
		IncreaseAbilityCharges(UnitState, AbilityName, NewGameState);
	}
}

private function IncreaseAbilityCharges(const XComGameState_Unit UnitState, const name AbilityName, XComGameState NewGameState)
{
	local XComGameState_Ability	AbilityState;
	local StateObjectReference	AbilityRef;
	local X2AbilityTemplate		AbilityTemplate;
	local int					iInitialCharges;

	AbilityRef = UnitState.FindAbility(AbilityName);
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
		return;

	AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
	if (bSetCharges)
	{
		AbilityState.iCharges = Charges;
	}
	else 
	{
		AbilityState.iCharges += Charges;
	}

	if (bRespectInitialCharges)
	{
		AbilityTemplate = AbilityState.GetMyTemplate();
		if (AbilityTemplate != none && AbilityTemplate.AbilityCharges != none)
		{
			iInitialCharges = AbilityTemplate.AbilityCharges.GetInitialCharges(AbilityState, UnitState);
			if (AbilityState.iCharges > iInitialCharges)
			{
				AbilityState.iCharges = iInitialCharges;
			}
		}
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit	UnitState;
	local name					AbilityName;

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
	if (EffectApplyResult != 'AA_Success')
		return;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)	
		return;

	foreach AbilityNames(AbilityName)
	{
		VisualizeAbilityChargesChange(UnitState, AbilityName, ActionMetadata, VisualizeGameState);
	}	
}

private function VisualizeAbilityChargesChange(const XComGameState_Unit UnitState, const name AbilityName, out VisualizationActionMetadata ActionMetadata, XComGameState VisualizeGameState)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameState_Ability			OldAbilityState;
	local XComGameState_Ability			NewAbilityState;
	local string						strFlyover;
	local StateObjectReference			AbilityRef;
	local int							ChargesDiff;

	AbilityRef = UnitState.FindAbility(AbilityName);
	NewAbilityState = XComGameState_Ability(VisualizeGameState.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (NewAbilityState == none)
		return;

	OldAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID,, VisualizeGameState.HistoryIndex - 1));
	if (OldAbilityState == none)	
		return;

	ChargesDiff = NewAbilityState.iCharges - OldAbilityState.iCharges;
	if (ChargesDiff <= 0)
		return;

	AbilityTemplate = NewAbilityState.GetMyTemplate();
	if (AbilityTemplate == none)	
		return;

	strFlyover = AbilityTemplate.LocFriendlyName $ ": +" $ ChargesDiff @ LocsCheckForGermanScharfesS(class'XLocalizedData'.default.Chargeslabel);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, strFlyover, '', eColor_Good, AbilityTemplate.IconImage, `DEFAULTFLYOVERLOOKATTIME, true);
}

static private function string LocsCheckForGermanScharfesS(string str)
{
	If( GetLanguage() == "DEU")
		str = Repl( str, "SS", "ß");

	//`log( "****************************************");
	//`log( "UIUtilities_Text.CapsCheckForGermanScharfesS:");
	//`log( "*** GetLanguage = '" $GetLanguage() $"', str = '" $str $"'");
	//`log( "*** Caps( str ) = '" $Caps( str ) $"'");
				
	// Unreal fail: it doesn't know how to properly convert this character. Adding it here to cover the general rename case. We should really rename this function. 
	// Extra bonus fun: In Russian, this fix is causing [Cyrillic capital backwards R, "Ya"] to display as [Latin capital "Y"]. Let's not do that... 
	If( GetLanguage() != "RUS")
	{
		str = Repl(str, class'UIUtilities_Text'.default.m_strUpperYWithUmlaut, class'UIUtilities_Text'.default.m_strLowerYWithUmlaut);
		//`log( "***  Y replacement SUCCESSFULLY triggered. Caps( str ) = '" $Caps( str ) $"'");
		//`log( "***  class'UIUtilities_Text'.default.m_strLowerYWithUmlaut = '" $class'UIUtilities_Text'.default.m_strLowerYWithUmlaut $"'.");
		//`log( "***  class'UIUtilities_Text'.default.m_strUpperYWithUmlaut = '" $class'UIUtilities_Text'.default.m_strUpperYWithUmlaut $"'.");
	}

	str = Locs(str);

	return str;
}