class X2Effect_BlastPaddingExtended extends X2Effect_Persistent;

// Copied from More Effective Blast Padding by RealityMachina
// https://steamcommunity.com/sharedfiles/filedetails/?id=1379047477

var float ExplosiveDamageReduction;

function int ModifyDamageFromDestructible(XComGameState_Destructible DestructibleState, int IncomingDamage, XComGameState_Unit TargetUnit, XComGameState_Effect EffectState)
{
	//	destructible damage is always considered to be explosive
	local int DamageMod;

	DamageMod = int(float(IncomingDamage) * ExplosiveDamageReduction);

	return -DamageMod;
}


defaultproperties
{
	bDisplayInSpecialDamageMessageUI = true
}
