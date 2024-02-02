class X2Effect_PredatorStrike extends X2Effect_ApplyWeaponDamage;

// Visualize only misses and only against units that can't play the skulljack animation.
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XGUnit TargetUnit;
	local XComUnitPawn TargetPawn;

	TargetUnit = XGUnit(ActionMetadata.VisualizeActor);
	if (TargetUnit != none && TargetUnit.IsDead())
	{
		TargetPawn = TargetUnit.GetPawn();
		if (TargetPawn != none)
		{
			if (TargetPawn.GetAnimTreeController().CanPlayAnimation('FF_SkulljackedStart') && EffectApplyResult == 'AA_Success')
			{
				// Do nothing.
				return;
			}
		}		
		
	}

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}
