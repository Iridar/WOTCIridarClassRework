class X2Effect_Amplify_Fixed extends X2Effect_Amplify;

// Same as original, just use post default function to calculate bonus damage.
function float GetPostDefaultDefendingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local XComGameState_Effect_Amplify AmplifyState;
	local int DamageMod;

	if (ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID > 0 && class'XComGameStateContext_Ability'.static.IsHitResultHit(ApplyEffectParameters.AbilityResultContext.HitResult) && CurrentDamage != 0)
	{
		DamageMod = BonusDamageMult * CurrentDamage;
		if (DamageMod < MinBonusDamage)
			DamageMod = MinBonusDamage;

		//	if NewGameState was passed in, we are really applying damage, so update our counter or remove the effect if it's worn off
		if (NewGameState != none)
		{
			AmplifyState = XComGameState_Effect_Amplify(EffectState);
			if (AmplifyState == none)
				return 0;

			if (AmplifyState.ShotsRemaining == 1)
			{
				AmplifyState.RemoveEffect(NewGameState, NewGameState);
			}
			else
			{
				AmplifyState = XComGameState_Effect_Amplify(NewGameState.ModifyStateObject(AmplifyState.Class, AmplifyState.ObjectID));
				AmplifyState.ShotsRemaining -= 1;
			}
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(AmplifyDecrement_PostBuildVisualization);
		}
	}
	return DamageMod;
}
// End Issue #923