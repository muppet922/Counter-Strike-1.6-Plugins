#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <fakemeta_util>
#include <engine>
#include <fun>
#include <zombieplague>
#include <cstrike>

#define PLUGIN "Bonus der Killed"
#define VERSION "1.1"
#define AUTHOR "Ene[r]gy132/North"

new Bonus[] = "models/supplybox/supplybox_zbs.mdl"

new const g_szClassName[] = "KillBonus"
//new const g_sound[] = "energy132/bonus_fz.wav"

new Float:g_vecOrigin[33][3]

new Entity

new rndm

new cvar_rend

new set_money = 0

public plugin_precache()
{
	precache_model(Bonus)
	//precache_sound(g_sound)
}

public plugin_init()
{
	register_plugin( PLUGIN, PLUGIN, PLUGIN )

	register_event("HLTV", "eventHLTV", "a", "1=0", "2=0")
	RegisterHam(Ham_Killed, "player", "CBasePlayer__Killed_Post", .Post = true)
	RegisterHam(Ham_Touch, "info_target", "CBaseEntity__Touch_Pre", .Post = false)
	
	cvar_rend = register_cvar("rend", "100")
	
	rndm = random_num(1, 3)
}

public eventHLTV()	
{
	new entity = -1;
	
	while((entity = find_ent_by_class(entity, g_szClassName))) remove_entity(entity)
}

public CBasePlayer__Killed_Post(pevVictim)
{
	if(zp_get_user_zombie(pevVictim))
	{
		new rdm = random_num(1, 30)
		
		switch(rdm)
		{
			case 9:
			{
				pev(pevVictim, pev_origin, g_vecOrigin[pevVictim])
				CreateBBox(g_vecOrigin[pevVictim])
			}
		}
	}

	return HAM_IGNORED;
}

public CreateBBox(Float:vOrigin[3])
{
	Entity = engfunc(EngFunc_CreateNamedEntity , engfunc(EngFunc_AllocString,"info_target"))

	if(!pev_valid(Entity)) return;
	
	set_pev(Entity, pev_classname, g_szClassName)
	set_pev(Entity, pev_model, Bonus)
	
	set_rendering(Entity, kRenderFxGlowShell, random(255), random(255), random(255), kRenderTransAlpha, get_pcvar_num(cvar_rend))

	engfunc(EngFunc_SetModel, Entity, Bonus)
	engfunc(EngFunc_SetSize, Entity, Float:{-1.0, -1.0, -1.0}, Float:{ 2.5,  2.5,  2.5})
	engfunc(EngFunc_SetOrigin, Entity, vOrigin)	
	
	set_pev(Entity, pev_solid, SOLID_BBOX)
	set_pev(Entity, pev_movetype, MOVETYPE_TOSS)

	set_pev(Entity, pev_nextthink, get_gametime() + 0.2)
}

public CBaseEntity__Touch_Pre(pEntity, pPlayer)
{
	if(!pev_valid(pEntity) || !is_user_alive(pPlayer) || !UTIL_get_user_human(pPlayer)) 
	return HAM_IGNORED
	
	static zsClassname[32]
	pev(pEntity, pev_classname, zsClassname, charsmax(zsClassname));

	if(!equal(zsClassname, g_szClassName)) 
	return HAM_IGNORED
	
	new name[32]
	get_user_name(pPlayer, name, 31)
	
	rndm = random_num(1, 3)
	
	switch(rndm)
	{
		case 1: 
		{
			if(set_money == 1)
			{
				new money = random(10000)
				cs_set_user_money(pPlayer, cs_get_user_money(pPlayer) + money)
				chat_color(pPlayer, "!g[ZP]!y Ты получил !g%d !yAmmo Packs", money)
			}
			else
			{
				new money = random(250)
				zp_set_user_ammo_packs(pPlayer, zp_get_user_ammo_packs(pPlayer) + money)
				chat_color(pPlayer, "!g[ZP]!y Ты получил !g%d !yAmmo Packs", money)
				//client_cmd(0, "spk sound/%s", g_sound)
			}
		}
		case 2: 
		{ 
			chat_color(pPlayer, "!g[ZP]!y Ты получил !gHP", name)
			new Float:hp
			pev(pPlayer, pev_health, hp)
			set_pev(pPlayer, pev_health, hp + 25.0)
			//client_cmd(0, "spk sound/%s", g_sound)
		}
		case 3: 
		{ 
			set_user_armor(pPlayer, get_user_armor(pPlayer) + 50)
			chat_color(pPlayer, "!g[ZP]!y Ты получил !gБроню", name)
			//client_cmd(0, "spk sound/%s", g_sound)
		}	 
	}

	engfunc( EngFunc_RemoveEntity , pEntity );

	return HAM_IGNORED;
}	

stock UTIL_get_user_human( pPlayer )
{
	return ( !zp_get_user_zombie( pPlayer ) && !zp_get_user_nemesis( pPlayer ) && !zp_get_user_survivor( pPlayer ) )
}

stock chat_color(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	replace_all(msg, 190, "!g", "^4")	//Green Color
	replace_all(msg, 190, "!y", "^1")	//Default Color
	replace_all(msg, 190, "!t", "^3")	//Team Color
	if(id)
		players[0] = id
	else
		get_players(players, count, "ch")
	for(new i=0; i<count; i++)
	{
		if(is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
			write_byte(players[i])
			write_string(msg)
			message_end()
		}
	}
}
