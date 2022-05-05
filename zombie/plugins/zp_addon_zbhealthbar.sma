#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>

#define PLUGIN "[ZP] Addon: Show Zombie Health"
#define VERSION "1.0"
#define AUTHOR "Dias : BlackCat (bug fix)"

new const healthbar_spr[] = "sprites/zb_healthbar.spr"
new g_playerbar[33] , g_isAlive[33]
new g_playerMaxHealth[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHam(Ham_Spawn, "player", "ham_spawn_post", 1)
	register_forward(FM_AddToFullPack, "fm_addtofullpack_post", 1)

	register_event("ResetHUD", "event_resethud", "be")
	register_event("DeathMsg", "event_death", "a")
	register_event("Health", "event_health", "be")

	make_healthbar()
}

public make_healthbar()
{
	static playerBar, allocString
	allocString = engfunc(EngFunc_AllocString, "env_sprite")

	for( new id = 1; id <= get_maxplayers(); id ++ )
	{
		g_playerbar[id] = engfunc(EngFunc_CreateNamedEntity, allocString)
		playerBar = g_playerbar[id]

		if(pev_valid(playerBar))
		{
			set_pev(playerBar, pev_scale, 0.25)
			engfunc(EngFunc_SetModel, playerBar, healthbar_spr)
			set_pev(playerBar, pev_effects, pev(playerBar, pev_effects ) | EF_NODRAW)
		}
	}
}

public plugin_precache() engfunc(EngFunc_PrecacheModel, healthbar_spr)

public ham_spawn_post(id)
{
	if(is_user_alive(id))
	{
		g_isAlive[id] = 1
	}
}

public zp_user_infected_post(id)
{
	g_playerMaxHealth[id] = get_user_health(id)
}

public zp_user_humanized_post(id)
{
	set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
}

public client_disconnected(id)
{
	set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
}

public event_resethud(id)
{
	set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
}

public event_death()
{
	new id = read_data(2)

	g_isAlive[id] = 0
	set_pev(g_playerbar[id], pev_effects, pev(g_playerbar[id], pev_effects) | EF_NODRAW)
}

public event_health(id)
{
	new hp = get_user_health(id)

	if(g_playerMaxHealth[id] < hp)
	{
		g_playerMaxHealth[id] = hp
		set_pev(g_playerbar[id], pev_frame, 99.0)
	}
	else
	{
		set_pev(g_playerbar[id], pev_frame, 0.0 + (((hp - 1) * 100) / g_playerMaxHealth[id]))
	}
}

public fm_addtofullpack_post(es, e, user, host, host_flags, player, p_set)
{
	if(!player)
		return FMRES_IGNORED

	if(!is_user_alive(host) || !is_user_alive(user))
		return FMRES_IGNORED

	if(!zp_get_user_zombie(user))
		return FMRES_IGNORED

	if(host == user)
		return FMRES_IGNORED

	new Float:PlayerOrigin[3]
	pev(user, pev_origin, PlayerOrigin)

	PlayerOrigin[2] += 60.0

	engfunc(EngFunc_SetOrigin, g_playerbar[user], PlayerOrigin)
	set_pev(g_playerbar[user], pev_effects, pev(g_playerbar[user], pev_effects) & ~EF_NODRAW)

	return FMRES_HANDLED
}
