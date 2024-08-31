class X2Effect_SH_ReturnFire extends X2Effect_ReturnFire;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', EffectGameState.CoveringFireCheck, ELD_OnStateSubmitted, 40); // Reduced priority to make it trigger after covering fire overwatch.
}
