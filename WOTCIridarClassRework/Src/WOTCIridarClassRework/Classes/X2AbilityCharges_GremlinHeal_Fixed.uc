class X2AbilityCharges_GremlinHeal_Fixed extends X2AbilityCharges_GremlinHeal;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	local array<XComGameState_Item> UtilityItems;
	local XComGameState_Item ItemIter;
	local int TotalCharges;

	TotalCharges = InitialCharges;
	UtilityItems = Unit.GetAllInventoryItems(); // Iridar - get all inventory items instead of only utility items.

	foreach UtilityItems(ItemIter)
	{
		if (ItemIter.bMergedOut)
			continue;

		if (ItemIter.GetWeaponCategory() == class'X2Item_DefaultUtilityItems'.default.MedikitCat)
		{
			TotalCharges += ItemIter.Ammo;
		}
	}
	if (bStabilize)
	{
		TotalCharges /= class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_STABILIZE_AMMO;
	}

	return TotalCharges;
}
