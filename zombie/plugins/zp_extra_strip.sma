#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

new const NADE_TYPE_STRIPBOMB= 7777
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const sprite_grenade_ring[] = "sprites/shockwave.spr"
new const model_grenade_infect[] = "models/v_grenade_astrip.mdl"
new const bcost = 5;

new g_trailSpr, g_exploSpr, item_id, cvar_enabled, cvar_mode, cvar_radius, cvar_max
new has_bomb[33],had_bombs[33];

public plugin_init()
{
	register_plugin("[ZP] Extra Item: Strip Bomb", "1.6", "Hezerf")

	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")

	register_forward(FM_SetModel, "fw_SetModel")

	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")

	register_event("HLTV","Event_New_Round","a", "1=0", "2=0")

	cvar_enabled = register_cvar("zp_strip_bomb", "1")
	cvar_mode = register_cvar("zp_strip_mode", "0")
	cvar_radius = register_cvar("zp_strip_radius", "250.0")
	cvar_max = register_cvar("zp_strip_max","5")
}

public plugin_precache()
{
	g_trailSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_trail)
	g_exploSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_ring)

	engfunc(EngFunc_PrecacheModel, model_grenade_infect)

	item_id = zp_register_extra_item("\r[\yZP\r]\yStrip Bomb", bcost, ZP_TEAM_ZOMBIE)
}

public client_disconnected(id)
{
	has_bomb[id] = 0;
	had_bombs[id] = 0;
}

public Event_New_Round()
{
	arrayset(had_bombs,0,32);
	arrayset(has_bomb,0,32);
}
public zp_extra_item_selected(player, itemid)
{
	if(itemid != item_id)
		return;
	if(get_pcvar_num(cvar_max) == had_bombs[player])
	{
		zp_set_user_ammo_packs(player,zp_get_user_ammo_packs(player) + bcost)
		client_print(player, print_chat, "[ZP] You can't buy Strip Bomb !")
		return;
	}

	has_bomb[player] = 1
	had_bombs[player]++;
	fm_strip_user_gun(player, 9)
	fm_give_item(player, "weapon_smokegrenade")
}

public fw_PlayerKilled(victim, attacker, shouldgib)
	has_bomb[victim] = 0;

public fw_ThinkGrenade(entity)
{
	if(!pev_valid(entity))
		return HAM_IGNORED

	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)

	if (dmgtime > get_gametime())
		return HAM_IGNORED

	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_STRIPBOMB)
	{
		stripbomb_explode(entity)

		return HAM_SUPERCEDE
	}

	return HAM_IGNORED
}

public fw_SetModel(entity, const model[])
{
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)

	new owner = pev(entity, pev_owner)

	if(!get_pcvar_num(cvar_enabled) || !dmgtime || !(equal(model[7], "w_sm", 4)) || !zp_get_user_zombie(owner) || !has_bomb[owner])
		return;

	fm_set_rendering(entity, kRenderFxGlowShell, 255, 128, 0, kRenderNormal, 16)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(entity) // entity
	write_short(g_trailSpr) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(255) // r
	write_byte(128) // g
	write_byte(0) // b
	write_byte(200) // brightness
	message_end()

	set_pev(entity, pev_flTimeStepSound, NADE_TYPE_STRIPBOMB)
}

public stripbomb_explode(ent)
{
	if (!zp_has_round_started())
		return;

	static Float:originF[3]
	pev(ent, pev_origin, originF)

	create_blast(originF)

	//engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, grenade_infect[random_num(0, sizeof grenade_infect - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)

	static attacker
	attacker = pev(ent, pev_owner)

	has_bomb[attacker] = 0

	static victim
	victim = -1
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, get_pcvar_float(cvar_radius))) != 0)
	{
		if (!is_user_alive(victim) || zp_get_user_zombie(victim))
			continue;

		switch(get_pcvar_num(cvar_mode))
		{
			case 0 :
			{
				if (pev(victim, pev_armorvalue) <= 0)
					continue;

				set_pev(victim, pev_armorvalue, 0);
			}
			case 1 :
			{
				fm_strip_user_weapons(victim)
				fm_give_item(victim, "weapon_knife")
			}
			case 2 :
			{
				if (pev(victim, pev_armorvalue) > 0)
					set_pev(victim, pev_armorvalue, 0)

				fm_strip_user_weapons(victim)
				fm_give_item(victim, "weapon_knife")
			}
		}
	}

	engfunc(EngFunc_RemoveEntity, ent)
}

public create_blast(const Float:originF[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(128) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(164) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

public replace_models(id)
{
	if (!is_user_alive(id) || get_user_weapon(id) != CSW_SMOKEGRENADE || !has_bomb[id])
		return

	set_pev(id, pev_viewmodel2, model_grenade_infect)
}

public message_cur_weapon(msg_id, msg_dest, msg_entity)
	replace_models(msg_entity);

// Stocks from fakemeta_util
stock bool:fm_strip_user_gun(index, wid = 0, const wname[] = "")
{
	new ent_class[32];
	if (!wid && wname[0])
		copy(ent_class, sizeof ent_class - 1, wname);
	else
	{
		new weapon = wid, clip, ammo;
		if (!weapon && !(weapon = get_user_weapon(index, clip, ammo)))
			return false;

		get_weaponname(weapon, ent_class, sizeof ent_class - 1);
	}

	new ent_weap = fm_find_ent_by_owner(-1, ent_class, index);
	if (!ent_weap)
		return false;

	engclient_cmd(index, "drop", ent_class);

	new ent_box = pev(ent_weap, pev_owner);
	if (!ent_box || ent_box == index)
		return false;

	dllfunc(DLLFunc_Think, ent_box);

	return true;
}

stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = fm_create_entity(item);
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}

stock fm_strip_user_weapons(index)
{
	new ent = fm_create_entity("player_weaponstrip");
	if (!pev_valid(ent))
		return 0;

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0)
{
	new strtype[11] = "classname", ent = index;
	switch (jghgtype)
	{
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}
