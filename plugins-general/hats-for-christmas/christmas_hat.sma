#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#pragma semicolon 1

enum {
	hat,
	deer
}

enum {
	random_all,
	c4_owner
}

new const MDL_FILE[] = "models/hats.mdl";

const DEER_HAT_FOR = random_all; // modify like you need
const m_iPlayerTeam = 114;
const EXTRAOFFSET = 5;
const m_iId = 43;
const EXTRAOFFSET_WEAPONS = 4;

new g_Ent[33];

public plugin_precache() {
	precache_model(MDL_FILE);
}

public plugin_init() {
	register_plugin("Christmas hat", "0.3", "AMXX.Shop");
	RegisterHam(Ham_Spawn, "player", "FwdSpawnPost", true);
	#if DEER_HAT_FOR == c4_owner
	if(find_ent_by_class(INVALID_HANDLE, "func_bomb_target") || find_ent_by_class(INVALID_HANDLE, "info_bomb_target")) {
		RegisterHam(Ham_AddPlayerItem, "player", "FwdAddPlayerItemPost", true);
		RegisterHam(Ham_RemovePlayerItem, "player", "FwdRemovePlayerItemPost", true);
	}
	#endif
}

public client_putinserver(id) {
	if(is_user_bot(id) || is_user_hltv(id)) {
		return;
	}
	CheckEnt(id);
	if((g_Ent[id] = create_entity("info_target"))) {
		entity_set_string(g_Ent[id], EV_SZ_classname, "_christmas_hat_ent");
		entity_set_model(g_Ent[id], MDL_FILE);
		entity_set_int(g_Ent[id], EV_INT_movetype, MOVETYPE_FOLLOW);
		entity_set_edict(g_Ent[id], EV_ENT_aiment, id);
	}
}

public client_disconnected(id) {
	CheckEnt(id);
}

public FwdSpawnPost(const id) {
	if(is_valid_ent(g_Ent[id]) && is_user_alive(id)) {
		#if DEER_HAT_FOR == c4_owner
		SetEntModel(id, hat, get_pdata_int(id, m_iPlayerTeam, EXTRAOFFSET));
		#else
		SetEntModel(id, random(10) % 2 ? hat : deer, get_pdata_int(id, m_iPlayerTeam, EXTRAOFFSET));
		#endif
	}
}

public FwdAddPlayerItemPost(const id, const Ent) {
	if(get_pdata_int(Ent, m_iId, EXTRAOFFSET_WEAPONS) == CSW_C4) {
		SetEntModel(id, deer);
	}
}

public FwdRemovePlayerItemPost(const id, const Ent) {
	if(get_pdata_int(Ent, m_iId, EXTRAOFFSET_WEAPONS) == CSW_C4) {
		SetEntModel(id, hat, get_pdata_int(id, m_iPlayerTeam, EXTRAOFFSET));
	}
}

CheckEnt(const id) {
	if(g_Ent[id] && is_valid_ent(g_Ent[id])) {
		entity_set_int(g_Ent[id], EV_INT_flags, FL_KILLME);
		entity_set_float(g_Ent[id], EV_FL_nextthink, get_gametime());
		g_Ent[id] = 0;
	}
}

SetEntModel(const id, const Body, const Skin = 0) {
	entity_set_int(g_Ent[id], EV_INT_body, Body);
	if(Body == hat) {
		entity_set_int(g_Ent[id], EV_INT_skin, Skin - 1);
	}
}