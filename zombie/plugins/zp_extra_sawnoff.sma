/*================================================================================

	[ZP] Extra Item: Sawn-Off Shotgun
	Copyright (C) 2009 by meTaLiCroSS
	Request maded by Clear

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	In addition, as a special exception, the author gives permission to
	link the code of this program with the Half-Life Game Engine ("HL
	Engine") and Modified Game Libraries ("MODs") developed by Valve,
	L.L.C ("Valve"). You must obey the GNU General Public License in all
	respects for all of the code used other than the HL Engine and MODs
	from Valve. If you modify this file, you may extend this exception
	to your version of the file, but you are not obligated to do so. If
	you do not wish to do so, delete this exception statement from your
	version.

=================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <xs>
#include <zombie_plague_special>

/*================================================================================
 [Customization]
=================================================================================*/

// Item Cost
new const g_SawnOff_Cost = 30

// Models
new const sawnoff_model_v[] = "models/v_sawn_off_shotgun.mdl"
new const sawnoff_model_p[] = "models/p_sawn_off_shotgun.mdl"
new const sawnoff_model_w[] = "models/w_sawn_off_shotgun.mdl"

// ---------------------------------------------------------------
// ------------------ Customization ends here!! ------------------
// ---------------------------------------------------------------

// Offsets
#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_LASTPRIMARYITEM = 368

// Version
#define VERSION "0.4.5"

// Arrays
new g_sawnoff_shotgun[33], g_currentweapon[33]

// Variables
new g_SawnOff, g_MaxPlayers

// Cvar Pointers
new cvar_enable, cvar_oneround, cvar_knockback, cvar_knockbackpower, cvar_uclip, cvar_damage

/*================================================================================
 [Init and Precache]
=================================================================================*/

public plugin_init()
{
	// Plugin Info
	register_plugin("[ZP] Extra Item: Sawn-Off Shotgun", VERSION, "meTaLiCroSS")

	// Ham Forwards
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	// Fakemeta Forwards
	register_forward(FM_SetModel, "fw_SetModel")

	// Event: Round Start
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	// Message: Cur Weapon
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")

	// CVARS
	register_cvar("zp_extra_sawnoff", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	cvar_enable = register_cvar("zp_sawnoff_enable", "1")
	cvar_uclip = register_cvar("zp_sawnoff_unlimited_clip", "0")
	cvar_damage = register_cvar("zp_sawnoff_damage_mult", "4.0")
	cvar_oneround = register_cvar("zp_sawnoff_oneround", "0")
	cvar_knockback = register_cvar("zp_sawnoff_knockback", "1")
	cvar_knockbackpower = register_cvar("zp_sawnoff_kbackpower", "10.0")

	// Variables
	g_MaxPlayers = get_maxplayers()
	g_SawnOff = zp_register_extra_item("\r[\yZP\r]\ySawn-Off Shotgun", g_SawnOff_Cost, ZP_TEAM_HUMAN)

}

public plugin_precache()
{
	// Precaching models
	precache_model(sawnoff_model_v)
	precache_model(sawnoff_model_p)
	precache_model(sawnoff_model_w)
}

/*================================================================================
 [Main Functions]
=================================================================================*/

// Round Start Event
public event_round_start()
{
	// Get all the players
	for(new id = 1; id <= g_MaxPlayers; id++)
	{
		// Check
		if(get_pcvar_num(cvar_oneround) || !get_pcvar_num(cvar_enable))
		{
			// Striping Sawn Off
			if(g_sawnoff_shotgun[id])
			{
				g_sawnoff_shotgun[id] = false;
				ham_strip_weapon(id, "weapon_m3")
			}
		}
	}
}

// Message Current Weapon
public message_cur_weapon(msg_id, msg_dest, id)
{
	// Doesn't have a Sawn Off
	if (!g_sawnoff_shotgun[id])
		return PLUGIN_CONTINUE

	// Isn't alive / not active weapon
	if (!is_user_alive(id) || get_msg_arg_int(1) != 1)
		return PLUGIN_CONTINUE

	// Get Weapon Clip
	new clip = get_msg_arg_int(3)

	// Update Weapon Array
	g_currentweapon[id] = get_msg_arg_int(2) // get weapon ID

	// Weapon isn't M3
	if(g_currentweapon[id] != CSW_M3)
		return PLUGIN_CONTINUE;

	// Replace Models
	entity_set_string(id, EV_SZ_viewmodel, sawnoff_model_v)
	entity_set_string(id, EV_SZ_weaponmodel, sawnoff_model_p)

	// Check cvar
	if(get_pcvar_num(cvar_uclip))
	{
		// Set Ammo HUD in 8
		set_msg_arg_int(3, get_msg_argtype(3), 8)

		// Check clip if more than 2
		if (clip < 2)
		{
			// Update weapon ammo
			fm_set_weapon_ammo(find_ent_by_owner(-1, "weapon_m3", id), 8)
		}
	}

	return PLUGIN_CONTINUE;
}

// Touch fix (when user drop the Sawn off, already has the Sawn off.
public touch_fix(id)
{
	if(g_sawnoff_shotgun[id])
		g_sawnoff_shotgun[id] = false;
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Victim has a Sawn off
	if(g_sawnoff_shotgun[victim])
		g_sawnoff_shotgun[victim] = false;
}

public fw_SetModel(entity, model[])
{
	// Entity is not valid
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;

	// Entity model is not a M3
	if(!equali(model, "models/w_m3.mdl"))
		return FMRES_IGNORED;

	// Get owner and entity classname
	new owner = entity_get_edict(entity, EV_ENT_owner)
	new classname[33]
	entity_get_string(entity, EV_SZ_classname, classname, charsmax(classname))

	// Entity classname is a weaponbox
	if(equal(classname, "weaponbox"))
	{
		// The weapon owner has a Sawn Off
		if(g_sawnoff_shotgun[owner])
		{
			// Striping Sawn off and set New Model
			g_sawnoff_shotgun[owner] = false;
			entity_set_model(entity, sawnoff_model_w)
			set_task(0.1, "touch_fix", owner)

			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED

}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Attacker isn't a Player (1 in 32)
	if(!(1 <= attacker <= g_MaxPlayers))
		return HAM_IGNORED;

	// Attacker's weapon isn't a M3
	if(g_currentweapon[attacker] != CSW_M3)
		return HAM_IGNORED;

	// User doesn't have a Sawn Off
	if(!g_sawnoff_shotgun[attacker])
		return HAM_IGNORED;

	SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage) )

	return HAM_IGNORED;
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Player is allowed to make a Knockback
	if(!allowed_knockback(victim, attacker))
		return HAM_IGNORED;

	// Check damage type
	if(!(damage_type & DMG_BULLET))
		return HAM_IGNORED;

	// Make Knockback...
	new Float:velocity[3]; pev(victim, pev_velocity, velocity)
	xs_vec_mul_scalar(direction, get_pcvar_float(cvar_knockbackpower), direction)
	xs_vec_add(velocity, direction, direction)
	entity_set_vector(victim, EV_VEC_velocity, direction)

	return HAM_IGNORED;

}

public pfn_touch(entity, toucher)
{
	new model[33], toucherclass[33], entityclass[33]

	// Get toucher Classname
	if((toucher > 0) && is_valid_ent(toucher)) entity_get_string(toucher, EV_SZ_classname, toucherclass, charsmax(toucherclass))

	// Get entity Classname
	if((entity > 0) && is_valid_ent(entity)) entity_get_string(entity, EV_SZ_classname, entityclass, charsmax(entityclass))

	// Now check if is a Weapon and is a Player
	if(equali(toucherclass, "player") && equali(entityclass, "weaponbox"))
	{
		// Get Model
		entity_get_string(entity, EV_SZ_model, model, charsmax(model))

		// Check Model
		if(equali(model, sawnoff_model_w))
			if(allowed_touch(toucher)) // Player is allowed to pickup the weapon
				g_sawnoff_shotgun[toucher] = true // Set Weapon
	}
}

/*================================================================================
 [Internal Functions]
=================================================================================*/

allowed_knockback(victim, attacker)
{
	// Obviously, doesn't is allowed to be Knockbacked (WTF)
	if(!g_sawnoff_shotgun[attacker] || !get_pcvar_num(cvar_knockback) || g_currentweapon[attacker] != CSW_M3 || !zp_get_user_zombie(victim))
		return false;

	return true;
}

allowed_touch(toucher)
{
	// Can't touch the Weapon
	if(zp_get_user_survivor(toucher) || zp_get_user_zombie(toucher) || fm_get_user_lastprimaryitem(toucher) || g_sawnoff_shotgun[toucher])
		return false;

	return true;
}

/*================================================================================
 [Zombie Plague Forwards]
=================================================================================*/

public zp_extra_item_selected(id, itemid)
{
	// Item is the Sawn-Off
	if(itemid == g_SawnOff)
	{
		if(!get_pcvar_num(cvar_enable))
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_SawnOff_Cost)
			client_print(id, print_chat, "[ZP] The Sawn-Off Shotgun is Disabled")

			return;
		}

		// Already has an M3
		if(g_sawnoff_shotgun[id] && user_has_weapon(id, CSW_M3))
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + g_SawnOff_Cost)
			client_print(id, print_chat, "[ZP] You already have a Sawn-Off Shotgun")

			return;
		}

		// Array
		g_sawnoff_shotgun[id] = true

		// Weapon
		ham_give_weapon(id, "weapon_m3")

		// Message
		client_print(id, print_chat, "[ZP] You now have a Sawn-Off Shotgun")

	}
}

public zp_user_infected_post(infected, infector)
{
	// Infected has a M3
	if(g_sawnoff_shotgun[infected])
		g_sawnoff_shotgun[infected] = false;
}

public zp_user_humanized_post(player)
{
	// Is Survivor
	if(zp_get_user_survivor(player) && g_sawnoff_shotgun[player])
		g_sawnoff_shotgun[player] = false;
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock ham_give_weapon(id, weapon[])
{
	if(!equal(weapon,"weapon_",7))
		return 0

	new wEnt = create_entity(weapon)

	if(!is_valid_ent(wEnt))
		return 0

	entity_set_int(wEnt, EV_INT_spawnflags, SF_NORESPAWN)
	DispatchSpawn(wEnt)

	if(!ExecuteHamB(Ham_AddPlayerItem,id,wEnt))
	{
		if(is_valid_ent(wEnt)) entity_set_int(wEnt, EV_INT_flags, entity_get_int(wEnt, EV_INT_flags) | FL_KILLME)
		return 0
	}

	ExecuteHamB(Ham_Item_AttachToPlayer,wEnt,id)
	return 1
}

stock ham_strip_weapon(id, weapon[])
{
	if(!equal(weapon,"weapon_",7))
		return 0

	new wId = get_weaponid(weapon)

	if(!wId) return 0

	new wEnt

	while((wEnt = find_ent_by_class(wEnt, weapon)) && entity_get_edict(wEnt, EV_ENT_owner) != id) {}

	if(!wEnt) return 0

	if(get_user_weapon(id) == wId)
		ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);

	if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt))
		return 0

	ExecuteHamB(Ham_Item_Kill, wEnt)

	entity_set_int(id, EV_INT_weapons, entity_get_int(id, EV_INT_weapons) & ~(1<<wId))

	return 1
}

stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}

stock fm_get_user_lastprimaryitem(id) // Thanks to joaquimandrade
{
	if(get_pdata_cbase(id, OFFSET_LASTPRIMARYITEM) != -1)
		return 1;

	return 0;
}
