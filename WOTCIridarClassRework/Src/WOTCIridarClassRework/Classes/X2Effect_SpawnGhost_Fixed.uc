class X2Effect_SpawnGhost_Fixed extends X2Effect_SpawnGhost;

// Same as original, just remove the obtuse and opaque mechanic of using Focus to determine Ghost's max Focus.
function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit NewUnitState, SourceUnitState;
	local float HealthValue;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', NewUnitRef.ObjectID));
	NewUnitState.GhostSourceUnit = ApplyEffectParameters.SourceStateObjectRef;
	NewUnitState.kAppearance.bGhostPawn = true;

	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	HealthValue = SourceUnitState.GetBaseStat(eStat_HP);

	NewUnitState.SetBaseMaxStat(eStat_HP, HealthValue, ECSMAR_None);
	NewUnitState.SetCurrentStat(eStat_HP, HealthValue);
	NewUnitState.SetCharacterName(default.FirstName, default.LastName, "");

	NewUnitState.SetUnitFloatValue('NewSpawnedUnit', 1, eCleanup_BeginTactical);
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationActionMetadata SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationActionMetadata EffectTargetUnitTrack)
{
	local X2Action_PlayAnimation AnimationAction;
	local X2Action_PlayAdditiveAnim AdditiveAction;
	local XGUnit DeadVisualizer;
	local XComUnitPawn DeadUnitPawn;
	local X2Action_ShowSpawnedUnit ShowSpawnedUnit;
	local Array<X2Action> ParentActions;
	local X2Action_MarkerNamed JoinAction;
	local X2Action_Delay FrameDelay;
	local X2Action LastActionAdded;
	local X2Action_PlayEffect TetherEffect;

	DeadVisualizer = XGUnit(EffectTargetUnitTrack.VisualizeActor);
	if( DeadVisualizer != None )
	{
		DeadUnitPawn = DeadVisualizer.GetPawn();
		if( DeadUnitPawn != None )
		{
			if( DeadUnitPawn.Mesh != None )
			{
				LastActionAdded = SpawnedUnitTrack.LastActionAdded;

				AdditiveAction = X2Action_PlayAdditiveAnim(class'X2Action_PlayAdditiveAnim'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, LastActionAdded));
				AdditiveAction.AdditiveAnimParams.AnimName = 'ADD_StartGhost';
				AdditiveAction.AdditiveAnimParams.BlendTime = 0.0f;
				ParentActions.AddItem(AdditiveAction);

				AnimationAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, LastActionAdded));
				AnimationAction.Params.AnimName = 'HL_GetUp';
				AnimationAction.Params.BlendTime = 0.0f;
				AnimationAction.Params.DesiredEndingAtoms[0].Translation = `XWORLD.GetPositionFromTileCoordinates(SpawnedUnit.TileLocation);
				AnimationAction.Params.DesiredEndingAtoms[0].Rotation = QuatFromRotator(DeadUnitPawn.Rotation);
				AnimationAction.Params.DesiredEndingAtoms[0].Scale = 1.0f;
				ParentActions.AddItem(AnimationAction);

				TetherEffect = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(EffectTargetUnitTrack, Context, false, LastActionAdded));
				TetherEffect.EffectName = "FX_Templar_Ghost.P_Ghost_Summon_Tether";
				TetherEffect.AttachToSocketName = 'FX_Chest';
				TetherEffect.TetherToSocketName = 'Root';
				TetherEffect.TetherToUnit = XGUnit(SpawnedUnitTrack.VisualizeActor);
				TetherEffect.bWaitForCompletion = false; // Iridar: this was set to true, once again holding the visualization.
				ParentActions.AddItem(TetherEffect);

				// Jwats: Give the animation actions a frame delay before showing the unit 
				FrameDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, LastActionAdded));
				FrameDelay.Duration = 0.25;
				
				ShowSpawnedUnit = X2Action_ShowSpawnedUnit(class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, FrameDelay));
				ShowSpawnedUnit.OverrideVisualizationLocation = DeadUnitPawn.Location;
				ShowSpawnedUnit.OverrideFacingRot = DeadUnitPawn.Rotation;
				ShowSpawnedUnit.bPlayIdle = false;
				ParentActions.AddItem(ShowSpawnedUnit);

				// Jwats: Wait for all the leafs for finish
				JoinAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, , ParentActions));
				JoinAction.SetName("Join");
			}
		}
	}
}