class X2Effect_GetOverHere_Fixed extends X2Effect_GetOverHere;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComGameState_Unit TargetUnitState;
	local vector NewUnitLoc;
	local X2Action_ViperGetOverHereTarget_Fixed GetOverHereTarget; // Iridar: use fixed action class.
	local X2Action_ApplyWeaponDamageToUnit UnitAction;

	TargetUnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if( TargetUnitState != None )
	{
		// Move the target to this space
		if( EffectApplyResult == 'AA_Success' )
		{
			GetOverHereTarget = X2Action_ViperGetOverHereTarget_Fixed(class'X2Action_ViperGetOverHereTarget_Fixed'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));//auto-parent to damage initiating action
			NewUnitLoc = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
			GetOverHereTarget.SetDesiredLocation(NewUnitLoc, XGUnit(ActionMetadata.VisualizeActor));

			if( OverrideStartAnimName != '' )
			{
				GetOverHereTarget.StartAnimName = OverrideStartAnimName;
			}

			if( OverrideStopAnimName != '' )
			{
				GetOverHereTarget.StopAnimName = OverrideStopAnimName;
			}
		}
		else
		{
			UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));//auto-parent to damage initiating action
			UnitAction.OriginatingEffect = self;
		}
	}
} 