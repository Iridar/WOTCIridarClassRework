class X2AbilityCharges_GremlinHeal_Fixed extends X2AbilityCharges_GremlinHeal;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	local array<XComGameState_Item> UtilityItems;
	local XComGameState_Item ItemIter;
	local int TotalCharges;
	local int MedikitBonusCharges;

	TotalCharges = InitialCharges;
	UtilityItems = Unit.GetAllInventoryItems(); // Iridar - get all inventory items instead of only utility items.

	MedikitBonusCharges = `GetConfigInt("IRI_SP_MedicalProtocol_BonusChargesPerMedikit");

	foreach UtilityItems(ItemIter)
	{
		if (ItemIter.bMergedOut)
			continue;

		if (ItemIter.GetWeaponCategory() == class'X2Item_DefaultUtilityItems'.default.MedikitCat)
		{
			TotalCharges += MedikitBonusCharges;
		}
	}

	return TotalCharges;
}
