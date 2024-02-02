class X2Action_ViperGetOverHereTarget_Fixed extends X2Action_ViperGetOverHereTarget;

var private transient XComGameState_Unit TargetUnit;

function SetDesiredLocation(Vector NewDesiredLocation, XGUnit NeededForZ)
{
	DesiredLocation = NewDesiredLocation;

	// Iridar: not sure what the point of this is, because the function responsible for finding the valid tile
	// wouldn't give you a tile on the "exploded floor". There might be some exceptions, like idk triggering
	// an environmental explosive which will blow up the floor, but overall it seems very niche.
	// This causes a specific bug when the dragged unit is killed during the event chain,
	// it will make the pawn float above the floor if it's dragged into high cover by Justice.
	// Doesn't seem to happen with Viper Tongue Pull.

	// Dev comment:
	//Don't get the floor Z because by the time this is called the floor might have exploded. Trust that the tile requested is correct
	//DesiredLocation.Z = NeededForZ.GetDesiredZForLocation(DesiredLocation, false); 
}

/*
simulated state Executing
{
Begin:

	// Iridar: call vanilla set location method to do whatever it was supposed to, but only if the unit isn't dead.
	// EDIT: Even if it's gonna be killed later, it's still not dead at this point. 
	TargetUnit = XComGameState_Unit(Metadata.StateObject_NewState);
	`AMLOG("Running for:" @ TargetUnit.GetFullName() @ "is dead:" @ TargetUnit.IsDead());
	if (TargetUnit == none || !TargetUnit.IsDead())
	{
		`AMLOG("Updating Z from:" @ DesiredLocation.Z);
		super.SetDesiredLocation(DesiredLocation, Unit);
		`AMLOG("Updating Z to:" @ DesiredLocation.Z);
	}

	StoredAllowNewAnimations = UnitPawn.GetAnimTreeController().GetAllowNewAnimations();
	if( StoredAllowNewAnimations )
	{
		//Wait for our turn to complete... and then set our rotation to face the destination exactly
		while( UnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance() )
		{
			Sleep(0.01f);
		}
	}
	else
	{
		UnitPawn.SetRotation(Rotator(Normal(DesiredLocation - UnitPawn.Location)));
	}

	UnitPawn.EnableRMA(true,true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	Params.AnimName = StartAnimName;
	DesiredRotation = Rotator(Normal(DesiredLocation - UnitPawn.Location));
	StartingAtom.Rotation = QuatFromRotator(DesiredRotation);
	StartingAtom.Translation = UnitPawn.Location;
	StartingAtom.Scale = 1.0f;
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(Params, StartingAtom);
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// hide the targeting icon
	Unit.SetDiscState(eDS_None);

	StopDistanceSquared = Square(VSize(DesiredLocation - StartingAtom.Translation) - UnitPawn.fStrangleStopDistance);

	// to protect against overshoot, rather than check the distance to the target, we check the distance from the source.
	// Otherwise it is possible to go from too far away in front of the target, to too far away on the other side
	DistanceFromStartSquared = 0;
	while( DistanceFromStartSquared < StopDistanceSquared )
	{
		if( !PlayingSequence.bRelevant || !PlayingSequence.bPlaying || PlayingSequence.AnimSeq == None )
		{
			if( DistanceFromStartSquared < StopDistanceSquared )
			{
				`RedScreen("Get Over Here Target never made it to the destination");
			}
			break;
		}

		Sleep(0.0f);
		DistanceFromStartSquared = VSizeSq(UnitPawn.Location - StartingAtom.Translation);
	}
	
	UnitPawn.bSkipIK = false;
	Params = default.Params;
	Params.AnimName = StopAnimName;
	Params.DesiredEndingAtoms.Add(1);
	Params.DesiredEndingAtoms[0].Scale = 1.0f;
	Params.DesiredEndingAtoms[0].Translation = DesiredLocation;
	DesiredRotation = UnitPawn.Rotation;
	DesiredRotation.Pitch = 0.0f;
	DesiredRotation.Roll = 0.0f;
	Params.DesiredEndingAtoms[0].Rotation = QuatFromRotator(DesiredRotation);
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(StoredAllowNewAnimations);

	CompleteAction();
}*/