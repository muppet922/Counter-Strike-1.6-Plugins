/*	Copyright © 2008, ConnorMcLeod

	Custom Flashlight is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Custom Flashligh; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

/*
* v0.3.1 (06/29/08)
* - fixed bug when you could have seen normal flashlight
*
* v0.3.0 (06/21/08)
* - some code optimizations (thanks to simon logic and jim_yang)
* - changes cvars flashlight_drainfreq and flashlight_chargefreq to
*  flashlight_fulldrain_time and flashlight_fullcharge_time
*  (simon logic suggestion)
* - moved random colors into $CONFIGSDIR/flashlight_colors.ini
*
* v0.2.0
* First public release
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <xs>
#tryinclude <biohazard>

#if !defined _biohazard_included
        #assert Biohazard functions file required!
#endif

#define PLUGIN "Custom Flashlight"
#define AUTHOR "ConnorMcLeod"
#define VERSION "0.3.1"

/* **************************** CUSTOMIZATION AREA ******************************** */

new const SOUND_FLASHLIGHT_ON[] = "items/flashlight1.wav"
new const SOUND_FLASHLIGHT_OFF[] = "items/flashlight1.wav"

#define LIFE	1	// try 2 if light is flickering

/* ******************************************************************************** */

#define MAX_PLAYERS	32
#define OFFSET_TEAM	114
#define fm_cs_get_user_team(%1) get_pdata_int(%1,OFFSET_TEAM)
#define write_coord_f(%1) engfunc(EngFunc_WriteCoord,%1)

enum {
	Red,
	Green,
	Blue
}

new Array:g_aColors
new g_iColorsNum

new g_iMaxPlayers

new bool:g_bFlashLight[MAX_PLAYERS+1]
new g_iFlashBattery[MAX_PLAYERS+1]
new Float:g_flFlashLightTime[MAX_PLAYERS+1]
new g_iColor[MAX_PLAYERS+1][3]

new g_msgidFlashlight, g_msgidFlashBat

new g_pcvarCustomFlashLight, g_pcvarShowAll,
	g_pcvarFlashDrain, g_pcvarFlashCharge,
	g_pcvarColorType, g_pcvarFlashColorTe, g_pcvarFlashColorCt,
	g_pcvarFlashRadius, g_pcvarFlashMaxDist, g_pcvarFlashAttn

public plugin_precache()
{
	if(is_biomod_active())
	{
		precache_sound(SOUND_FLASHLIGHT_ON)
		precache_sound(SOUND_FLASHLIGHT_OFF)
	}
}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR )
	is_biomod_active() ? plugin_init2() : pause("ad")
}

public plugin_init2()
{
	g_pcvarCustomFlashLight = register_cvar("flashlight_custom", "1")

	g_pcvarShowAll = register_cvar("flashlight_show_all", "1")

	g_pcvarFlashDrain = register_cvar("flashlight_fulldrain_time", "120") // def : 120 (0 for no drain)
	g_pcvarFlashCharge = register_cvar("flashlight_fullcharge_time", "20") // def : 20

	g_pcvarColorType = register_cvar("flashlight_color_type", "1") // 0:random , 1:teamcolor
	g_pcvarFlashColorCt = register_cvar("flashlight_color_ct", "255255255") // RRRGGGBBB
	g_pcvarFlashColorTe = register_cvar("flashlight_color_te", "255255255") // RRRGGGBBB

	g_pcvarFlashRadius = register_cvar("flashlight_radius", "9")

	g_pcvarFlashMaxDist = register_cvar("flashlight_distance_max", "2000")
	g_pcvarFlashAttn = register_cvar("flashlight_attenuation", "5")


	register_forward(FM_PlayerPreThink, "PlayerPreThink")
	register_forward(FM_CmdStart, "CmdStart")

	register_event("HLTV", "Event_HLTV_newround", "a", "1=0", "2=0")
	register_event("DeathMsg", "Event_DeathMsg", "a")

	plugin_precfg()
}

plugin_precfg()
{
	g_msgidFlashlight = get_user_msgid("Flashlight")
	g_msgidFlashBat = get_user_msgid("FlashBat")

	g_iMaxPlayers = get_maxplayers()

	new szConfigFile[64]
	get_configsdir(szConfigFile, 63)
	format(szConfigFile, 63, "%s/flashlight_colors.ini", szConfigFile)

	new iFile = fopen(szConfigFile, "rt")
	if(!iFile)
	{
		return
	}

	g_aColors = ArrayCreate(3)

	new szColors[12], szRed[4], szGreen[4], szBlue[4], iColor[3]
	while(!feof(iFile))
	{
		fgets(iFile, szColors, 11)
		trim(szColors)
		if(!szColors[0] || szColors[0] == ';' || (szColors[0] == '/' && szColors[1] == '/'))
			continue
		parse(szColors, szRed, 3, szGreen, 3, szBlue, 3)
		iColor[Red] = str_to_num(szRed)
		iColor[Green] = str_to_num(szGreen)
		iColor[Blue] = str_to_num(szBlue)
		ArrayPushArray(g_aColors, iColor)
	}
	fclose(iFile)

	g_iColorsNum = ArraySize(g_aColors)
}

public client_putinserver(id)
{
	reset(id)
}

public event_infect(victim, attacker)
{
	if(g_bFlashLight[victim])
		FlashlightTurnOff(victim)
}

public Event_HLTV_newround()
{
	for(new id=1; id<=g_iMaxPlayers; id++)
	{
		reset(id)
	}
}

public Event_DeathMsg()
{
	reset(read_data(2))
}

reset(id)
{
	g_iFlashBattery[id] = 100
	g_bFlashLight[id] = false
	g_flFlashLightTime[id] = 0.0
}

public CmdStart(id, uc_handle, seed)
{
	if( !get_pcvar_num(g_pcvarCustomFlashLight) )
		return FMRES_IGNORED

	if(get_uc(uc_handle, UC_Impulse) == 100)
	{
		if(is_user_alive(id))
		{
			if( g_bFlashLight[id] )
			{
				FlashlightTurnOff(id)
			}
			else
			{
				FlashlightTurnOn(id)
			}
		}
		set_uc(uc_handle, UC_Impulse, 0)
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public PlayerPreThink(id)
{
	static Float:flDrain, Float:flTime
	flDrain = get_pcvar_float( g_pcvarFlashDrain ) / 100
	global_get(glb_time, flTime)	
	if(flDrain && g_flFlashLightTime[id] && g_flFlashLightTime[id] <= flTime)
	{
		if(g_bFlashLight[id])
		{
			if(g_iFlashBattery[id])
			{
				g_flFlashLightTime[id] = flDrain + flTime
				g_iFlashBattery[id]--
				
				if(!g_iFlashBattery[id])
					FlashlightTurnOff(id)
			}
		}
		else
		{
			if(g_iFlashBattery[id] < 100)
			{
				g_flFlashLightTime[id] = get_pcvar_float(g_pcvarFlashCharge) / 100 + flTime
				g_iFlashBattery[id]++
			}
			else
				g_flFlashLightTime[id] = 0.0
		}

		message_begin(MSG_ONE_UNRELIABLE, g_msgidFlashBat, _, id)
		write_byte(g_iFlashBattery[id])
		message_end()

	}
	if(g_bFlashLight[id])
	{
		Make_FlashLight(id)
	}
}

Float:Get_StarEndPos(id, Float:flStart[3], Float:flAim[3])
{
	pev(id, pev_origin, flStart)
	pev(id, pev_view_ofs, flAim)
	xs_vec_add(flStart, flAim, flStart)

	pev(id, pev_v_angle, flAim)	
	engfunc(EngFunc_MakeVectors, flAim)
	global_get(glb_v_forward, flAim)
	xs_vec_mul_scalar(flAim, 9999.0, flAim)
	xs_vec_add(flStart, flAim, flAim)
	engfunc(EngFunc_TraceLine, flStart, flAim, 0, id, 0)
	get_tr2(0, TR_vecEndPos, flAim)
}

Make_FlashLight(id)
{
	static Float:flStart[3], Float:flAim[3], Float:flDist, Float:flMaxDist

	Get_StarEndPos(id, flStart, flAim)

	flDist = get_distance_f(flStart, flAim)
	flMaxDist = get_pcvar_float(g_pcvarFlashMaxDist)

	if( flDist > flMaxDist )
		return

	static iDecay, iAttn

	iDecay = floatround( flDist * 255.0 / flMaxDist )
	iAttn = 256 + iDecay * get_pcvar_num(g_pcvarFlashAttn) // barney/dontaskme

	if(get_pcvar_num(g_pcvarShowAll))
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	else
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte( TE_DLIGHT )
	write_coord_f( flAim[0] )
	write_coord_f( flAim[1] )
	write_coord_f( flAim[2] )
	write_byte( get_pcvar_num(g_pcvarFlashRadius) )
	write_byte( (g_iColor[id][Red]<<8) / iAttn )
	write_byte( (g_iColor[id][Green]<<8) / iAttn )
	write_byte( (g_iColor[id][Blue]<<8) / iAttn )
	write_byte( LIFE )
	write_byte( iDecay )
	message_end()
}

FlashlightTurnOff(id)
{
	engfunc( EngFunc_EmitSound, id, CHAN_WEAPON, SOUND_FLASHLIGHT_OFF, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )

	g_bFlashLight[id] = false

	FlashlightHudDraw(id, 0)

	g_flFlashLightTime[id] = get_pcvar_float(g_pcvarFlashCharge) / 100 + get_gametime()
}

FlashlightTurnOn(id)
{
	engfunc( EngFunc_EmitSound, id, CHAN_WEAPON, SOUND_FLASHLIGHT_ON, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )

	g_bFlashLight[id] = true

	FlashlightHudDraw(id, 1)

	if( get_pcvar_num(g_pcvarColorType) || !g_iColorsNum )
	{
		static szColor[10], iColor
		get_pcvar_string( fm_cs_get_user_team(id) == 1 ? 
								g_pcvarFlashColorTe : 
								g_pcvarFlashColorCt,
									szColor, 9 )
		iColor = str_to_num(szColor)
		g_iColor[id][Red] = (iColor / 1000000)
		iColor %= 1000000 
		g_iColor[id][Green] = (iColor / 1000)
		g_iColor[id][Blue] = (iColor % 1000)
	}
	else
	{
		ArrayGetArray(g_aColors, random(g_iColorsNum), g_iColor[id])
	}

	g_flFlashLightTime[id] = get_pcvar_float(g_pcvarFlashDrain) / 100 + get_gametime()
}

FlashlightHudDraw(id, iFlag)
{
	if( get_pcvar_num(g_pcvarShowAll) )
	{
		emessage_begin(MSG_ONE_UNRELIABLE, g_msgidFlashlight, _, id)
		ewrite_byte(iFlag)
		ewrite_byte(g_iFlashBattery[id])
		emessage_end()
	}
	else
	{
		message_begin(MSG_ONE_UNRELIABLE, g_msgidFlashlight, _, id)
		write_byte(iFlag)
		write_byte(g_iFlashBattery[id])
		message_end()
	}
}