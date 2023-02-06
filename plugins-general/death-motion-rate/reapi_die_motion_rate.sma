// Copyright © 2016 Vaqtincha

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG START ■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#define ONLY_HEADSHOT_KILL

#define VOICE_PITCH		70		// fast ~120
#define MOTION_RATE 	0.17	// fast ~2.17

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG END ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#include <amxmodx>
#include <reapi>

#if defined VOICE_PITCH
	#include <fakemeta>
	new g_iFwdEmitSound
#endif

new HookChain:g_hSetAnimation

public plugin_init()
{	
	register_plugin("Die Motion Rate", "0.0.2", "Vaqtincha")
 
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", .post = 0)
#if defined VOICE_PITCH
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_KilledP", .post = 1)
#endif
	DisableHookChain(g_hSetAnimation = RegisterHookChain(RG_CBasePlayer_SetAnimation, "CBasePlayer_SetAnimation", .post = 1))
}

public CBasePlayer_Killed(const index, const pevAttacker, iGib)
{
	if(!pevAttacker || index == pevAttacker)
		return HC_CONTINUE

#if defined ONLY_HEADSHOT_KILL
	if(get_member(index, m_LastHitGroup) != HITGROUP_HEAD)
		return HC_CONTINUE
#endif
	EnableHookChain(g_hSetAnimation)

#if defined VOICE_PITCH
	g_iFwdEmitSound = register_forward(FM_EmitSound, "EmitSound_Pre", ._post = 0)
#endif
	return HC_CONTINUE
}

public CBasePlayer_SetAnimation(const index, const PLAYER_ANIM:playerAnim)
{
	DisableHookChain(g_hSetAnimation)
	if(playerAnim == PLAYER_DIE)
		set_entvar(index, var_framerate, MOTION_RATE)

	return HC_CONTINUE
}

#if defined VOICE_PITCH
public CBasePlayer_KilledP(const index, const pevAttacker, iGib)
{
	if(g_iFwdEmitSound)
	{
		unregister_forward(FM_EmitSound, g_iFwdEmitSound, .post = 0)
		g_iFwdEmitSound = 0
	}
}

public EmitSound_Pre(const iEntity, iChannel, const szSample[], Float:fVol, Float:fAttn, iFlags, iPitch)
{
	if(iChannel == CHAN_VOICE)
	{
		emit_sound(iEntity, iChannel, szSample, fVol, fAttn, iFlags, VOICE_PITCH)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}
#endif



