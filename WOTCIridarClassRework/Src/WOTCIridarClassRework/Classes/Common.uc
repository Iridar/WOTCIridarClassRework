class Common extends Object abstract;

static final protected function RemoveChargeCost(out X2AbilityTemplate AbilityTemplate)
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

static final protected function RemoveActionCost(out X2AbilityTemplate AbilityTemplate)
{
	local int i;

	AbilityTemplate.AbilityCharges = none;

	for (i = AbilityTemplate.AbilityCosts.Length - 1; i >= 0; i--)
	{
		if (X2AbilityCost_ActionPoints(AbilityTemplate.AbilityCosts[i]) != none)
		{
			AbilityTemplate.AbilityCosts.Remove(i, 1);
		}
	}
}

static final protected function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}

static final protected function AddFreeActionCost(out X2AbilityTemplate Template)
{
	local X2AbilityCost_ActionPoints ActionPointCost;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
}
