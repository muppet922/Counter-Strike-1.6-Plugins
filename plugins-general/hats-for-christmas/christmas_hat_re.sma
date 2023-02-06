#include <amxmodx>
#include <reapi>

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

new g_MdlIndex, g_Ent[MAX_CLIENTS + 1];

public plugin_precache() {
	g_MdlIndex = precache_model(MDL_FILE);
}

public plugin_init() {
	register_plugin("Christmas hat", "0.3", "AMXX.Shop");
	RegisterHookChain(RG_CBasePlayer_Spawn, "FwdSpawnPost", true);
	#if DEER_HAT_FOR == c4_owner
	if(rg_find_ent_by_class(INVALID_HANDLE, "func_bomb_target", true) || rg_find_ent_by_class(INVALID_HANDLE, "info_bomb_target", true)) {
		RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "FwdAddPlayerItemPost", true);
		RegisterHookChain(RG_CBasePlayer_RemovePlayerItem, "FwdRemovePlayerItemPost", true);
	}
	#endif
}

public client_putinserver(id) {
	if(is_user_bot(id) || is_user_hltv(id)) {
		return;
	}
	CheckEnt(id);
	if((g_Ent[id] = rg_create_entity("info_target"))) {
		set_entvar(g_Ent[id], var_classname, "_christmas_hat_ent");
		set_entvar(g_Ent[id], var_model, MDL_FILE);
		set_entvar(g_Ent[id], var_modelindex, g_MdlIndex);
		set_entvar(g_Ent[id], var_movetype, MOVETYPE_FOLLOW);
		set_entvar(g_Ent[id], var_aiment, id);
	}
}

public client_disconnected(id) {
	CheckEnt(id);
}

public FwdSpawnPost(const id) {
	if(is_entity(g_Ent[id]) && is_user_alive(id)) {
		#if DEER_HAT_FOR == c4_owner
		SetEntModel(id, hat, get_member(id, m_iTeam));
		#else
		SetEntModel(id, random(10) % 2 ? hat : deer, get_member(id, m_iTeam));
		#endif
	}
}

public FwdAddPlayerItemPost(const id, const Ent) {
	if(get_member(Ent, m_iId) == CSW_C4) {
		SetEntModel(id, deer);
	}
}

public FwdRemovePlayerItemPost(const id, const Ent) {
	if(get_member(Ent, m_iId) == CSW_C4) {
		SetEntModel(id, hat, get_member(id, m_iTeam));
	}
}

CheckEnt(const id) {
	if(g_Ent[id] && is_entity(g_Ent[id])) {
		set_entvar(g_Ent[id], var_flags, FL_KILLME);
		set_entvar(g_Ent[id], var_nextthink, get_gametime());
		g_Ent[id] = 0;
	}
}

SetEntModel(const id, const Body, const Skin = 0) {
	set_entvar(g_Ent[id], var_body, Body);
	if(Body == hat) {
		set_entvar(g_Ent[id], var_skin, Skin - 1);
	}
}