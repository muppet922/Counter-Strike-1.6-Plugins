#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombie_plague_special>

#define is_valid_player(%1) (1 <= %1 <= 32)

new awp_V_MODEL[64] = "models/zombie_plague/weapons/v_awp.mdl"
new awp_P_MODEL[64] = "models/zombie_plague/weapons/p_awp.mdl"
new awp_W_MODEL[64] = "models/zombie_plague/weapons/w_awp.mdl"

/* Pcvars */

new cvar_dmgmultiplier, cvar_goldbullets,  cvar_custommodel, cvar_uclip

// Item ID
new g_itemid
new bool:g_Hasawp[33]
new bullets[ 33 ]

// Sprit
new m_spriteTexture
const Wep_awp = ((1<<CSW_AWP))

public plugin_init()

{

/* CVARS */
cvar_dmgmultiplier = register_cvar("zp_awp_dmg_multiplier", "10")
cvar_custommodel = register_cvar("zp_awp_custom_model", "1")
cvar_goldbullets = register_cvar("zp_awp_gold_bullets", "1")
cvar_uclip = register_cvar("zp_awp_unlimited_clip", "0")

// Register The Plugin

register_plugin("[ZP] Extra: Golden AWP", "1.0", "Pervade")

// Register Zombie Plague extra item
g_itemid = zp_register_extra_item("\r[\yZP\r]\yGolden AWP(High Damage)", 35, ZP_TEAM_HUMAN)

// Death Msg
register_event("DeathMsg", "Death", "a")

// Weapon Pick Up
register_event("WeapPickup","checkModel","b","1=18")

// Current Weapon Event
register_event("CurWeapon","checkWeapon","be","1=1")
register_event("CurWeapon", "make_tracer", "be", "1=1", "3>0")

// Ham TakeDamage

RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
register_forward( FM_CmdStart, "fw_CmdStart" )
RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
}


public client_connect(id)

{
	g_Hasawp[id] = false
}


public client_disconnected(id)

{
	g_Hasawp[id] = false
}

public Death()

{
	g_Hasawp[read_data(2)] = false
}


public fwHamPlayerSpawnPost(id)

{
	g_Hasawp[id] = false
}

public plugin_precache()

{
	precache_model(awp_V_MODEL)
  precache_model(awp_P_MODEL)
  precache_model(awp_W_MODEL)
	m_spriteTexture = precache_model("sprites/dot.spr")
	precache_sound("weapons/zoom.wav")
}

public zp_user_infected_post(id)

{
	if (zp_get_user_zombie(id))

	{
		g_Hasawp[id] = false
	}
}



public checkModel(id)

{

	if ( zp_get_user_zombie(id) )

	return PLUGIN_HANDLED
	new szWeapID = read_data(2)

	if ( szWeapID == CSW_AWP && g_Hasawp[id] == true && get_pcvar_num(cvar_custommodel) )

	{
		set_pev(id, pev_viewmodel2, awp_V_MODEL)
	}

	return PLUGIN_HANDLED
}


public checkWeapon(id)

{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId


	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)

	if (plrWeapId == CSW_AWP && g_Hasawp[id])

	{
		checkModel(id)
	}

	else

	{
		return PLUGIN_CONTINUE
	}


	if (plrClip == 0 && get_pcvar_num(cvar_uclip))

	{
		// If the user is out of ammo..
		get_weaponname(plrWeapId, plrWeap, 31)

		// Get the name of their weapon
		give_item(id, plrWeap)

		engclient_cmd(id, plrWeap)
		engclient_cmd(id, plrWeap)
		engclient_cmd(id, plrWeap)
	}

	return PLUGIN_HANDLED

}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage)

{
    if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_AWP && g_Hasawp[attacker] )

    {
        SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) )
    }
}

public make_tracer(id)

{
	if (get_pcvar_num(cvar_goldbullets))

	{
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)
		new pteam[16]

		get_user_team(id, pteam, 15)

		if ((bullets[id] > clip) && (wpnid == CSW_AWP) && g_Hasawp[id])

		{
			new vec1[3], vec2[3]

			get_user_origin(id, vec1, 1) // origin; your camera point.

			get_user_origin(id, vec2, 4) // termina; where your bullet goes (4 is cs-only)


			//BEAMENTPOINTS

			message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte (0)     //TE_BEAMENTPOINTS 0
			write_coord(vec1[0])
			write_coord(vec1[1])
			write_coord(vec1[2])
			write_coord(vec2[0])
			write_coord(vec2[1])
			write_coord(vec2[2])
			write_short( m_spriteTexture )
			write_byte(1) // framestart
			write_byte(5) // framerate
			write_byte(2) // life
			write_byte(10) // width
			write_byte(0) // noise
			write_byte( 255 )     // r, g, b
			write_byte( 215 )       // r, g, b
			write_byte( 0 )       // r, g, b
			write_byte(200) // brightness
			write_byte(150) // speed
			message_end()
		}

		bullets[id] = clip
	}
}



public zp_extra_item_selected(player, itemid)

{
	if ( itemid == g_itemid )

	{
		if ( user_has_weapon(player, CSW_AWP) )

		{
			drop_prim(player)
		}

		give_item(player, "weapon_awp")
		cs_set_user_bpammo(player, CSW_AWP, 30) //Give them 30 BPAmmo
		client_print(player, print_chat, "[ZP] You bought Golden AWP")
		g_Hasawp[player] = true;
	}
}


stock drop_prim(id)

{
	new weapons[32], num
	get_user_weapons(id, weapons, num)

	for (new i = 0; i < num; i++) {

		if (Wep_awp & (1<<weapons[i]))

		{
			static wname[32]

			get_weaponname(weapons[i], wname, sizeof wname - 1)

			engclient_cmd(id, "drop", wname)
		}
	}
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE

*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1034\\ f0\\ fs16 \n\\ par }

*/
