#include <amxmodx>
#include <fakemeta>
#include <zombie_plague_special>
#include <zpsp_xp_system>

// Enables Parachute Model
//#define USE_MODEL

// Parachute
new const parachute_up_name[] = "UPGRADE_PARACHUTE_NAME"
new const parachute_up_description[] = "UPGRADE_PARACHUTE_DESC"
const parachute_up_max_level = 1
new const parachute_up_prices[parachute_up_max_level] = { 1000 }
new const parachute_up_sell_values[parachute_up_max_level] = { 500 }
new const parachute_up_vault_name[] = "zpsp_upgrade_parachute"

// Parachute Fall Speed
new const fall_up_name[] = "UPGRADE_PARA_FALLSPD_NAME"
new const fall_up_description[] = "UPGRADE_PARA_FALLSPD_DESC"
const fall_up_max_level = 5
new const fall_up_prices[fall_up_max_level] = { 100, 200, 300, 400, 500 }
new const fall_up_sell_values[fall_up_max_level] = { 50, 100, 150, 200, 250 }
new const fall_up_vault_name[] = "zpsp_upgrade_par_fallspd"
new const Float:SpeedFall[fall_up_max_level+1] = { 
	90.0,	// Level 0
	75.0,	// Level 1
	60.0,	// Level 2
	50.0,	// Level 3
	40.0,	// Level 4
	30.0	// Level 5
}

// Parachute Wind Resistance
new const wind_up_name[] = "UPGRADE_PARA_WIND_NAME"
new const wind_up_description[] = "UPGRADE_PARA_WIND_DESC"
const wind_up_max_level = 3
new const wind_up_prices[wind_up_max_level] = { 500, 1000, 1500 }
new const wind_up_sell_values[wind_up_max_level] = { 250, 500, 750 }
new const wind_up_vault_name[] = "zpsp_upgrade_par_windres"
new const Float:ParMaxSpeed[wind_up_max_level+1] = { 
	300.0,	// Level 0
	400.0,	// Level 1
	450.0,	// Level 2
	500.0	// Level 3
}

#if defined USE_MODEL
#include <hamsandwich>
#define PARACHUTE_MODEL "models/parachute.mdl"
#define MarkUserHasParachute(%0)	g_bitHasParachute |= (1<<(%0&31))
#define ClearUserHasParachute(%0)	g_bitHasParachute &= ~(1<<(%0&31))
#define HasUserParachute(%0)		g_bitHasParachute & (1<<(%0&31))

new g_bitHasParachute, g_iUserParachute[33], Float:g_flEntityFrame[33]
new g_iModelIndex
new const PARACHUTE_CLASS[] = "parachute"
enum {
	deploy,
	idle,
	detach
}
#endif

new g_UpParachute, g_UpFallSpd, g_UpWindResistance
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Parachute", "1.0", "H.RED.ZONE | Perf. Scrash")
	register_forward( FM_CmdStart, "fw_Start" )
	
	#if defined USE_MODEL
	RegisterHam(Ham_Spawn, "player", "Ham_CBasePlayer_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "Ham_CBasePlayer_Killed_Post", 1)
	#endif

	g_UpParachute = zp_register_upgrade(parachute_up_name, parachute_up_description, parachute_up_prices, parachute_up_sell_values, parachute_up_max_level, parachute_up_vault_name, 1);
	g_UpFallSpd = zp_register_upgrade(fall_up_name, fall_up_description, fall_up_prices, fall_up_sell_values, fall_up_max_level, fall_up_vault_name, 1);
	g_UpWindResistance = zp_register_upgrade(wind_up_name, wind_up_description, wind_up_prices, wind_up_sell_values, wind_up_max_level, wind_up_vault_name, 1);
}

public zp_upgrade_menu_open(id, Up_ID) {
	if(Up_ID != g_UpWindResistance && Up_ID != g_UpFallSpd)
		return PLUGIN_CONTINUE

	if(zp_get_user_upgrade_lvl(id, g_UpParachute) < 1) {
		client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_XP_NEEDED_PARACHUTE")
		return ZP_PLUGIN_HANDLED;
	}

	static level
	level = zp_get_user_upgrade_lvl(id, Up_ID)

	if(Up_ID == g_UpFallSpd)
		zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_FALLSPD_NOTE", floatround(SpeedFall[level])))

	if(Up_ID == g_UpWindResistance)
		zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_WIND_RES_NOTE", floatround(ParMaxSpeed[level])))

	return PLUGIN_CONTINUE
	
}

public fw_Start(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_user_zombie(id))
		return;

	if(zp_get_user_upgrade_lvl(id, g_UpParachute) < 1)
		return

	static FallSpdLvl, WindResLvl
	FallSpdLvl = zp_get_user_upgrade_lvl(id, g_UpFallSpd)
	WindResLvl = zp_get_user_upgrade_lvl(id, g_UpWindResistance)

	#if defined USE_MODEL
	if( ~HasUserParachute(id)) {
		return
	}
	new Float:flFrame
	new iEnt = g_iUserParachute[id]
	if(iEnt > 0 && pev(id, pev_flags) & FL_ONGROUND) {
		if( pev(iEnt, pev_sequence) != detach ) {
			set_pev(iEnt, pev_sequence, detach)
			set_pev(iEnt, pev_gaitsequence, 1)
			set_pev(iEnt, pev_frame, 0.0)
			g_flEntityFrame[id] = 0.0
			set_pev(iEnt, pev_animtime, 0.0)
			set_pev(iEnt, pev_framerate, 0.0)
			return
		}
		pev(iEnt, pev_frame, flFrame)
		if( flFrame > 252.0 ) {
			RemoveUserParachute(id, iEnt)
			return
		}
		flFrame += 2.0
		g_flEntityFrame[id] = flFrame
		set_pev(iEnt, pev_frame, flFrame)
		return
	}
	if( pev(id, pev_button) & IN_USE ) {
		new Float:fVecVelocity[3], Float:fVelocity_z
		pev(id, pev_velocity, fVecVelocity)
		fVelocity_z = fVecVelocity[2]

		// Wind Force - Can not strafe very well without upgrade
		while(fVecVelocity[0] > ParMaxSpeed[WindResLvl] || fVecVelocity[1] > ParMaxSpeed[WindResLvl] ) {
			fVecVelocity[0] *= 0.7
			fVecVelocity[1] *= 0.7
		}
		//-----------------

		if( fVelocity_z < 0.0 ) {
			if(iEnt <= 0) {
				iEnt = CreateParachute(id)
			}

			fVelocity_z = floatmin(fVelocity_z + 15.0, -1.0 * SpeedFall[FallSpdLvl])
			fVecVelocity[2] = fVelocity_z
			set_pev(id, pev_velocity, fVecVelocity)

			if( pev(iEnt, pev_sequence) == deploy ) {
				flFrame = g_flEntityFrame[id]++

				if( flFrame > 100.0 ) {
					set_pev(iEnt, pev_animtime, 0.0)
					set_pev(iEnt, pev_framerate, 0.4)
					set_pev(iEnt, pev_sequence, idle)
					set_pev(iEnt, pev_gaitsequence, 1)
					set_pev(iEnt, pev_frame, 0.0)
					g_flEntityFrame[id] = 0.0
				}
				else {
					set_pev(iEnt, pev_frame, flFrame)
				}
			}
		}
		else if(iEnt > 0) {
			RemoveUserParachute(id, iEnt)
		}
	}
	else if( iEnt > 0 && pev(id, pev_oldbuttons) & IN_USE ) {
		RemoveUserParachute(id, iEnt)
	}
	#else 
	if(pev(id, pev_button) & IN_USE ) {
		static Float:fVecVelocity[3], Float:fVelocity_z
		pev(id, pev_velocity, fVecVelocity)
		fVelocity_z = fVecVelocity[2]

		// Wind Force - Can not strafe very well without upgrade
		while(fVecVelocity[0] > ParMaxSpeed[WindResLvl] || fVecVelocity[1] > ParMaxSpeed[WindResLvl] ) {
			fVecVelocity[0] *= 0.7
			fVecVelocity[1] *= 0.7
		}
		//-----------------

		if( fVelocity_z < 0.0 ) {
			fVelocity_z = floatmin(fVelocity_z + 15.0, -1.0 * SpeedFall[FallSpdLvl])
			fVecVelocity[2] = fVelocity_z
			set_pev(id, pev_velocity, fVecVelocity)
		}
	}
	#endif
}

#if defined USE_MODEL
public plugin_precache() {
	g_iModelIndex = precache_model(PARACHUTE_MODEL)
}

public client_putinserver(id) {
	if( HasUserParachute(id) ) {
		new iEnt = g_iUserParachute[id]
		if( iEnt ) {
			RemoveUserParachute(id, iEnt)
		}
		ClearUserHasParachute(id)
	}
}

public client_disconnected(id) {
	if( HasUserParachute(id) ) {
		new iEnt = g_iUserParachute[id]
		if( iEnt ) {
			RemoveUserParachute(id, iEnt)
		}
		ClearUserHasParachute(id)
	}
}

public Ham_CBasePlayer_Killed_Post( id ) {
	if( HasUserParachute(id) ) {
		new iEnt = g_iUserParachute[id]
		if( iEnt ) {
			RemoveUserParachute(id, iEnt)
		}
		ClearUserHasParachute(id)
	}
}

public Ham_CBasePlayer_Spawn_Post(id) {
	if( is_user_alive(id) ) {
		if( HasUserParachute(id) ) {
			new iEnt = g_iUserParachute[id]
			if( iEnt ) {
				RemoveUserParachute(id, iEnt)
			}
		}
		MarkUserHasParachute(id)
	}
}

RemoveUserParachute(id, iEnt) {
	engfunc(EngFunc_RemoveEntity, iEnt)
	g_iUserParachute[id] = 0
}

CreateParachute(id) {
	static iszInfoTarget
	if( !iszInfoTarget ) {
		iszInfoTarget = engfunc(EngFunc_AllocString, "info_target")
	}

	new iEnt = engfunc(EngFunc_CreateNamedEntity, iszInfoTarget)
	if( iEnt > 0) {
		static iszClass = 0
		if( !iszClass ) {
			iszClass = engfunc(EngFunc_AllocString, PARACHUTE_CLASS)
		}
		set_pev_string(iEnt, pev_classname, iszClass)
		set_pev(iEnt, pev_aiment, id)
		set_pev(iEnt, pev_owner, id)
		set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW)

		static iszModel = 0
		if( !iszModel ) {
			iszModel = engfunc(EngFunc_AllocString, PARACHUTE_MODEL)
		}
		set_pev_string(iEnt, pev_model, iszModel)
		set_pev(iEnt, pev_modelindex, g_iModelIndex)

		set_pev(iEnt, pev_sequence, deploy)
		set_pev(iEnt, pev_gaitsequence, 1)
		set_pev(iEnt, pev_frame, 0.0)
		g_flEntityFrame[id] = 0.0
		g_iUserParachute[id] = iEnt
		MarkUserHasParachute(id)
		new Float:fVecOrigin[3]
		pev(id, pev_origin, fVecOrigin)
		
		return iEnt
	}
	return 0
}
#endif