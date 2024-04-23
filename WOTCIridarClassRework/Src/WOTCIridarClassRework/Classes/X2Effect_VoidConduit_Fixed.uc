class X2Effect_VoidConduit_Fixed extends X2Effect_VoidConduit;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit, SourceUnit;
	local int StartingHP, DamagedHP, DifferenceHP;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none)
		return;
	
	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
	{
		SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	}
	if (SourceUnit == none)
		return;

	StartingHP = TargetUnit.GetCurrentStat(eStat_HP);
	TargetUnit.TakeEffectDamage(self, DamagePerAction, 0, 0, ApplyEffectParameters, NewGameState); // Using DamagePerAction as damage per turn here.
	DamagedHP = TargetUnit.GetCurrentStat(eStat_HP);
	DifferenceHP = StartingHP - DamagedHP;
	DifferenceHP *= HealthReturnMod;
	if (DifferenceHP > 0)
	{
		SourceUnit.ModifyCurrentStat(eStat_HP, DifferenceHP);
	}
}

// Same as X2Effect_VoidConduit::AddX2ActionsForVisualization_Tick(), just using ability context instead of the effect state to get the source state object reference.
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_ApplyWeaponDamageToUnit UnitAction;
	local XComGameStateContext Context;
	local X2Action ParentAction;
	local X2Action_PlayEffect EffectAction;
	local XComGameStateVisualizationMgr VisMgr;
	local Array<X2Action> SourceNodes;
	local XGUnit SourceUnit;
	local VisualizationActionMetadata SourceMetadata;
	local XComGameStateHistory History;
	local Array<X2Action> ParentActions;
	local X2Action_Death DeathAction;
	local X2Action_PersistentEffect PersistentAction;
	local X2Action_PlaySoundAndFlyOver HealedFlyover;
	local int HealedAmount;
	local string HealedMsg;
	local XComGameStateContext_Ability AbilityContext;
	local X2Action_TimedWait	TimedWait;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	SourceUnit = XGUnit(`XCOMHISTORY.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID));
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action', SourceNodes, SourceUnit);
	if( SourceNodes.Length > 0 )
	{
		SourceMetadata = SourceNodes[0].Metadata;
	}
	else
	{
		SourceMetadata.StateObjectRef.ObjectID = SourceUnit.ObjectID;
		SourceMetadata.VisualizeActor = SourceUnit;
		SourceMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		SourceMetadata.StateObject_NewState = History.GetGameStateForObjectID(SourceUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	}

	if (ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		Context = VisualizeGameState.GetContext();
		ParentAction = ActionMetadata.LastActionAdded;
		
		// Jwats: If Death happened then we need to move the death/persistent effect to after our visualization
		DeathAction = X2Action_Death(ParentAction);
		if( DeathAction != None && DeathAction.ParentActions.Length != 0 )
		{
			PersistentAction = X2Action_PersistentEffect(DeathAction.ParentActions[0]);
			if( PersistentAction != None )
			{
				ParentAction = PersistentAction;
			}

			DeathAction.bForceMeleeDeath = true;
		}

		// Jwats: If ParentAction is none (or death) we don't want them to auto parent to each other
		//			so create a join so they all start at the same time
		if( ParentAction == None || DeathAction != None )
		{
			ParentActions = ParentAction != None ? ParentAction.ParentActions : None;
			ParentAction = class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, true, None, ParentActions);
			X2Action_MarkerNamed(ParentAction).SetName("Join");
			ParentActions.Length = 0;
		}

		TimedWait =  X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		TimedWait.DelayTimeSec = 2.0f; // Time for particle effects to play

		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain_Tether";
		EffectAction.AttachToSocketName = 'Root';
		EffectAction.TetherToSocketName = 'Root';
		EffectAction.TetherToUnit = SourceUnit;
		EffectAction.bWaitForCompletion = false;
		ParentActions.AddItem(EffectAction);

		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
		EffectAction.bWaitForCompletion = false;
		ParentActions.AddItem(EffectAction);

		UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		UnitAction.OriginatingEffect = self;
		ParentActions.AddItem(UnitAction);

		// Jwats: Now Play an effect on the source
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(SourceMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain_Templar";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
		EffectAction.bWaitForCompletion = false;
		ParentActions.AddItem(EffectAction);

		//	Show flyover for healed HP
		HealedAmount = XComGameState_Unit(SourceMetadata.StateObject_NewState).GetCurrentStat(eStat_HP) - XComGameState_Unit(SourceMetadata.StateObject_OldState).GetCurrentStat(eStat_HP);
		if (HealedAmount > 0)
		{
			HealedMsg = Repl(class'X2Effect_SoulSteal'.default.HealedMessage, "<Heal/>", HealedAmount);
			HealedFlyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(SourceMetadata, Context, false, ParentAction));
			HealedFlyover.SetSoundAndFlyOverParameters(none, HealedMsg, '', eColor_Good, , , true);		
			ParentActions.AddItem(HealedFlyover);
		}

		if( PersistentAction != None )
		{
			// Jwats: Death is now moved and is a single action to end with
			VisMgr.DisconnectAction(PersistentAction);
			VisMgr.ConnectAction(PersistentAction, VisMgr.BuildVisTree, false, None, ParentActions);
		}
		else if( DeathAction != None )
		{
			// Jwats: Death is now moved and is a single action to end with
			VisMgr.DisconnectAction(DeathAction);
			VisMgr.ConnectAction(DeathAction, VisMgr.BuildVisTree, false, None, ParentActions);
		}
		else
		{
			// Jwats: Make sure we end with a single action so nothing interupts
			ParentAction = class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, None, ParentActions);
			X2Action_MarkerNamed(ParentAction).SetName("Join");
		}
	}
}

// Ô
simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
	local X2Action_ApplyWeaponDamageToUnit UnitAction;
	local XComGameStateContext Context;
	local X2Action ParentAction;
	local X2Action_PlayEffect EffectAction;
	local XComGameStateVisualizationMgr VisMgr;
	local Array<X2Action> SourceNodes;
	local XGUnit SourceUnit;
	local VisualizationActionMetadata SourceMetadata;
	local XComGameStateHistory History;
	local Array<X2Action> ParentActions;
	local X2Action_Death DeathAction;
	local X2Action_PersistentEffect PersistentAction;
	local X2Action_PlaySoundAndFlyOver HealedFlyover;
	local int HealedAmount;
	local string HealedMsg;

	local X2Action_TimedWait	TimedWait;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	SourceUnit = XGUnit(`XCOMHISTORY.GetVisualizer(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action', SourceNodes, SourceUnit);
	if( SourceNodes.Length > 0 )
	{
		SourceMetadata = SourceNodes[0].Metadata;
	}
	else
	{
		SourceMetadata.StateObjectRef.ObjectID = SourceUnit.ObjectID;
		SourceMetadata.VisualizeActor = SourceUnit;
		SourceMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		SourceMetadata.StateObject_NewState = History.GetGameStateForObjectID(SourceUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	}

	if (ActionMetadata.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		Context = VisualizeGameState.GetContext();
		ParentAction = ActionMetadata.LastActionAdded;
		
		// Jwats: If Death happened then we need to move the death/persistent effect to after our visualization
		DeathAction = X2Action_Death(ParentAction);
		if( DeathAction != None && DeathAction.ParentActions.Length != 0 )
		{
			PersistentAction = X2Action_PersistentEffect(DeathAction.ParentActions[0]);
			if( PersistentAction != None )
			{
				ParentAction = PersistentAction;
			}

			DeathAction.bForceMeleeDeath = true;
		}

		// Jwats: If ParentAction is none (or death) we don't want them to auto parent to each other
		//			so create a join so they all start at the same time
		if( ParentAction == None || DeathAction != None )
		{
			ParentActions = ParentAction != None ? ParentAction.ParentActions : None;
			ParentAction = class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, true, None, ParentActions);
			X2Action_MarkerNamed(ParentAction).SetName("Join");
			ParentActions.Length = 0;
		}

		// ADDED
		TimedWait =  X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		TimedWait.DelayTimeSec = 2.0f; // Time for particle effects to play
		// END OF ADDED

		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain_Tether";
		EffectAction.AttachToSocketName = 'Root';
		EffectAction.TetherToSocketName = 'Root';
		EffectAction.TetherToUnit = SourceUnit;
		EffectAction.bWaitForCompletion = false; // Iridar: Firaxis set this to "true", but apparently didn't set a specific completion time for the effect, so visualization hangs on these effect actions until they time out.
		ParentActions.AddItem(EffectAction);

		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
		EffectAction.bWaitForCompletion = false;
		ParentActions.AddItem(EffectAction);

		UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ParentAction));
		UnitAction.OriginatingEffect = self;
		ParentActions.AddItem(UnitAction);

		// Jwats: Now Play an effect on the source
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(SourceMetadata, Context, false, ParentAction));
		EffectAction.EffectName = "FX_Templar_Void_Conduit.P_Void_Conduit_Drain_Templar";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
		EffectAction.bWaitForCompletion = false;
		ParentActions.AddItem(EffectAction);

		//	Show flyover for healed HP
		HealedAmount = XComGameState_Unit(SourceMetadata.StateObject_NewState).GetCurrentStat(eStat_HP) - XComGameState_Unit(SourceMetadata.StateObject_OldState).GetCurrentStat(eStat_HP);
		if (HealedAmount > 0)
		{
			HealedMsg = Repl(class'X2Effect_SoulSteal'.default.HealedMessage, "<Heal/>", HealedAmount);
			HealedFlyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(SourceMetadata, Context, false, ParentAction));
			HealedFlyover.SetSoundAndFlyOverParameters(none, HealedMsg, '', eColor_Good, , , true);		
			ParentActions.AddItem(HealedFlyover);
		}

		if( PersistentAction != None )
		{
			// Jwats: Death is now moved and is a single action to end with
			VisMgr.DisconnectAction(PersistentAction);
			VisMgr.ConnectAction(PersistentAction, VisMgr.BuildVisTree, false, None, ParentActions);
		}
		else if( DeathAction != None )
		{
			// Jwats: Death is now moved and is a single action to end with
			VisMgr.DisconnectAction(DeathAction);
			VisMgr.ConnectAction(DeathAction, VisMgr.BuildVisTree, false, None, ParentActions);
		}
		else
		{
			// Jwats: Make sure we end with a single action so nothing interupts
			ParentAction = class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, None, ParentActions);
			X2Action_MarkerNamed(ParentAction).SetName("Join");
		}
	}
}
