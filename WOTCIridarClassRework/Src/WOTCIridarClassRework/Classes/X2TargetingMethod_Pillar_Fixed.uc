class X2TargetingMethod_Pillar_Fixed extends X2TargetingMethod_Pillar;

var private TTile TeleportTile;

function Update(float DeltaTime)
{
	local vector		NewTargetLocation;
	local array<vector>	TargetLocations;
	local array<TTile>	Tiles;
	local XComWorldData	World;
	local TTile			AdjacentTile;
	local array<Actor>	CurrentlyMarkedTargets;
	
	NewTargetLocation = Cursor.GetCursorFeetLocation();

	if (NewTargetLocation != CachedTargetLocation)
	{
		TargetLocations.AddItem(Cursor.GetCursorFeetLocation());
		if (ValidateTargetLocations(TargetLocations) == 'AA_Success')
		{
			// The current tile the cursor is on is a valid tile
			// Show the ExplosionEmitter
			//ExplosionEmitter.ParticleSystemComponent.ActivateSystem();
			//InvalidTileActor.SetHidden(true);

			World = `XWORLD;
		
			TeleportTile = World.GetTileCoordinatesFromPosition(TargetLocations[0]);
			Tiles.AddItem(TeleportTile);

			//if (DoesTargetTileHasUnitsOnAdjacentTiles())
			//{
			//	DrawInvalidTile();
			//	super(X2TargetingMethod_Teleport).UpdateTargetLocation(DeltaTime);
			//	return;
			//}


			AdjacentTile = TeleportTile;
			AdjacentTile.X++;
			Tiles.AddItem(AdjacentTile);

			AdjacentTile = TeleportTile;
			AdjacentTile.X--;
			Tiles.AddItem(AdjacentTile);

			AdjacentTile = TeleportTile;
			AdjacentTile.Y++;
			Tiles.AddItem(AdjacentTile);

			AdjacentTile = TeleportTile;
			AdjacentTile.Y--;
			Tiles.AddItem(AdjacentTile);

			GetTargetedActorsInTiles(Tiles, CurrentlyMarkedTargets, true);
			MarkTargetedActors(CurrentlyMarkedTargets, eTeam_None);

			DrawAOETiles(Tiles);
			//IconManager.UpdateCursorLocation(, true);
		}
		else
		{
			DrawInvalidTile();
		}
	}

	super(X2TargetingMethod_Teleport).UpdateTargetLocation(DeltaTime);
}

function bool VerifyTargetableFromIndividualMethod(delegate<ConfirmAbilityCallback> fnCallback)
{
	if (DoesTargetTileHasUnitsOnAdjacentTiles())
	{
		`PRES.PlayUISound(eSUISound_MenuClickNegative);
		return false;
	}
	return true;
}

private function bool DoesTargetTileHasUnitsOnAdjacentTiles()
{
	local TTile							AdjacentTile;
	local XComWorldData					World;
	local array<StateObjectReference>	UnitRefs;

	World = `XWORLD;

	AdjacentTile = TeleportTile;
	AdjacentTile.X++;
	UnitRefs = World.GetUnitsOnTile(AdjacentTile);
	if (UnitRefs.Length > 0)
	{
		return true;
	}

	AdjacentTile = TeleportTile;
	AdjacentTile.X--;
	UnitRefs = World.GetUnitsOnTile(AdjacentTile);
	if (UnitRefs.Length > 0)
	{
		return true;
	}

	AdjacentTile = TeleportTile;
	AdjacentTile.Y++;
	UnitRefs = World.GetUnitsOnTile(AdjacentTile);
	if (UnitRefs.Length > 0)
	{
		return true;
	}

	AdjacentTile = TeleportTile;
	AdjacentTile.Y--;
	UnitRefs = World.GetUnitsOnTile(AdjacentTile);
	if (UnitRefs.Length > 0)
	{
		return true;
	}
	return false;
}
