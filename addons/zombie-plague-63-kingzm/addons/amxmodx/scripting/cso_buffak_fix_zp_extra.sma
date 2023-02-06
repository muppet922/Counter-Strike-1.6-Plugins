/*
***********************************************************************
************************** WWW.ZOMBIE-MOD.RU **************************
***********************************************************************
****** The Plugins Is Made Indonesia :) || Sorry For Bad Coding *******
** My Group Community: Counter:Strike Zombie Plague Modder Indonesia **
***********************************************************************
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>

// ZP NATIVE
#include <zombieplague>

#define PLUGIN "[CSO] AK47 PALADIN || NATIVE + ZP EXTRA ITEMS"
#define VERSION "1.0 || CLOSED BETA"
#define AUTHOR "AsepKhairulAnam@CS:ZPMI || -RequiemID- || Facebook.com/asepdwa11"

// CONFIGURATION WEAPON
#define system_name		"buffak"
#define system_base		"ak47"

#define DRAW_TIME		0.66
#define RELOAD_TIME		2.1

#define CSW_BASE		CSW_AK47
#define WEAPON_KEY 		11092002112

#define OLD_MODEL		"models/w_ak47.mdl"
#define ANIMEXT			"carbine"

// Configuration Extra Items
#define NAME_EXTRA_ITEMS	"AK47 Paladin"
#define TEAM_EXTRA_ITEMS	ZP_TEAM_HUMAN
#define COST_EXTRA_ITEMS	35

/*
Support For Human And Survivor
Not Supported For Zombie || Madafaka!!
- ZP_TEAM HUMAN = HUMAN
- ZP_TEAM_SURVIVOR = SURVIVOR
*/

// ALL MACRO
#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define TASK_MUZZLEFLASH	102291

#define USE_STOPPED 		0
#define OFFSET_LINUX_WEAPONS 	4
#define OFFSET_LINUX 		5
#define OFFSET_WEAPONOWNER 	41
#define OFFSET_ACTIVE_ITEM 	373

#define m_fKnown		44
#define m_flNextPrimaryAttack 	46
#define m_flTimeWeaponIdle	48
#define m_iClip			51
#define m_fInReload		54
#define m_flNextAttack		83
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

// ALL ANIM
#define ANIM_RELOAD		1
#define ANIM_DRAW		2
#define ANIM_SHOOT1		3
#define ANIM_SHOOT2		4
#define ANIM_SHOOT3		5

#define MODE_A			0
#define MODE_B			1

// All Models Of The Weapon
new V_MODEL[64] = "models/v_buffak_fix.mdl"
new W_MODEL[64] = "models/w_buffak.mdl"
new P_MODEL[64] = "models/p_buffak.mdl"
new S_MODEL[64] = "sprites/asep/ef_buffak_hit.spr"

new const WeaponResources[][] =
{
	"sprites/asep/640hud7.spr",
	"sprites/asep/640hud132.spr"
}

new const MuzzleFlash[][] =
{
	"sprites/asep/muzzleflash40.spr",
	"sprites/asep/muzzleflash41.spr"
}

// You Can Add Fire Sound Here
new const Fire_Sounds[][] = { "weapons/ak47buff-1.wav", "weapons/ak47buff-2.wav" }

// All Vars Here
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new cvar_dmg, cvar_recoil, cvar_clip, cvar_spd, cvar_ammo, cvar_radius, cvar_dmg_2, cvar_trace_color
new g_MaxPlayers, g_orig_event, g_IsInPrimaryAttack, g_attack_type[33], Float:cl_pushangle[33][3]
new g_has_weapon[33], g_clip_ammo[33], g_weapon_TmpClip[33], oldweap[33], sBuffakHit
new g_Muzzleflash_Ent[2], g_Muzzleflash[33][2], g_Mode[33], g_item, g_list_variables[10]

// Macros Again :v
new weapon_name_buffer[512]
new weapon_base_buffer[512]
		
const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

// START TO CREATE PLUGINS || AMXMODX FORWARD
public plugin_init()
{
	formatex(weapon_name_buffer, sizeof(weapon_name_buffer), "weapon_%s_asep", system_name)
	formatex(weapon_base_buffer, sizeof(weapon_base_buffer), "weapon_%s", system_base)
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Event And Message
	register_event("CurWeapon", "Forward_CurrentWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "Forward_DeathMsg")
	register_message(get_user_msgid("WeaponList"), "Forward_MessageWeapList")
	
	// Ham Forward (Entity) || Ham_Use
	RegisterHam(Ham_Use, "func_tank", "Forward_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "Forward_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "Forward_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "Forward_UseStationary_Post", 1)
	
	// Ham Forward (Entity) || Ham_TraceAttack
	RegisterHam(Ham_TraceAttack, "player", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "Forward_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "Forward_TraceAttack", 1)
	
	// Ham Forward (Weapon)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base_buffer, "Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_base_buffer, "Weapon_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_base_buffer, "Weapon_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_base_buffer, "Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_base_buffer, "Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_base_buffer, "Weapon_AddToPlayer")
	
	for(new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if(WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "Weapon_Deploy_Post", 1)
		
	// Ham Forward (Player)
	RegisterHam(Ham_Killed, "player", "Forward_PlayerKilled")
	
	// Fakemeta Forward
	register_forward(FM_SetModel, "Forward_SetModel")
	register_forward(FM_PlaybackEvent, "Forward_PlaybackEvent")
	register_forward(FM_UpdateClientData, "Forward_UpdateClientData_Post", 1)
	register_forward(FM_AddToFullPack, "Forward_AddToFullPack", 1)
	register_forward(FM_CheckVisibility, "Forward_CheckVisibility")
	
	// All Some Cvar
	cvar_clip = register_cvar("buffak_clip", "50")
	cvar_spd = register_cvar("buffak_speed", "1.15")
	cvar_ammo = register_cvar("buffak_ammo", "240")
	cvar_dmg = register_cvar("buffak_damage", "2.0")
	cvar_recoil = register_cvar("buffak_recoil", "0.62")
	cvar_dmg_2 = register_cvar("buffak_buff_damage", "100")
	cvar_radius = register_cvar("buffak_buff_radius", "50")
	cvar_trace_color = register_cvar("buffak_trace_color", "7")
	
	g_MaxPlayers = get_maxplayers()
	g_item = zp_register_extra_item(NAME_EXTRA_ITEMS, COST_EXTRA_ITEMS, TEAM_EXTRA_ITEMS)
}

public plugin_precache()
{
	formatex(weapon_name_buffer, sizeof(weapon_name_buffer), "weapon_%s_asep", system_name)
	formatex(weapon_base_buffer, sizeof(weapon_base_buffer), "weapon_%s", system_base)
	
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	sBuffakHit = precache_model(S_MODEL)
	
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "sprites/%s.txt", weapon_name_buffer)
	precache_generic(Buffer) // EG: Output "sprites/weapon_buffak_asep.txt"
	
	for(new i = 0; i < sizeof Fire_Sounds; i++)
		precache_sound(Fire_Sounds[i])
	for(new i = 0; i < sizeof MuzzleFlash; i++)
		precache_model(MuzzleFlash[i])
	for(new i = 0; i < sizeof WeaponResources; i++)
		precache_model(WeaponResources[i])
		
	precache_viewmodel_sound(V_MODEL)
	formatex(Buffer, sizeof(Buffer), "test_%s", system_name)
	
	register_clcmd(Buffer, "give_item") // EG: Output "test_buffak"
	register_clcmd(weapon_name_buffer, "weapon_hook")
	register_forward(FM_PrecacheEvent, "Forward_PrecacheEvent_Post", 1)
	
	g_Muzzleflash_Ent[0] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent[0], MuzzleFlash[0])
	set_pev(g_Muzzleflash_Ent[0], pev_scale, 0.08)
	set_pev(g_Muzzleflash_Ent[0], pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent[0], pev_renderamt, 0.0)

	g_Muzzleflash_Ent[1] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent[1], MuzzleFlash[1])
	set_pev(g_Muzzleflash_Ent[1], pev_scale, 0.07)
	set_pev(g_Muzzleflash_Ent[1], pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent[1], pev_renderamt, 0.0)
}

public plugin_natives()
{
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "give_%s", system_name)
	register_native(Buffer, "give_item", 1) // EG: Output "give_buffak"
	formatex(Buffer, sizeof(Buffer), "remove_%s", system_name)
	register_native(Buffer, "remove_item", 1) // EG: Output "remove_buffak"
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_item)
		return

	give_item(id)
}

// Reset Bitvar (Fix Bug) If You Connect Or Disconnect Server
public client_connect(id) remove_item(id)
public client_disconnect(id) remove_item(id)
public zp_user_infected_post(id) remove_item(id)
public zp_user_humanized_post(id) remove_item(id)
/* ========= START OF REGISTER HAM TO SUPPORT BOTS FUNC ========= */
new g_HamBot
public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHam", id)
	}
}

public Do_RegisterHam(id)
{
	RegisterHamFromEntity(Ham_Killed, id, "Forward_PlayerKilled")
	RegisterHamFromEntity(Ham_TraceAttack, id, "Forward_TraceAttack", 1)
}

/* ======== END OF REGISTER HAM TO SUPPORT BOTS FUNC ============= */
/* ============ START OF ALL FORWARD (FAKEMETA) ================== */
public Forward_AddToFullPack(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if(iEnt == g_Muzzleflash_Ent[0])
	{
		if(g_Muzzleflash[iHost][0] == 3)
		{
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, random_float(200.0, 255.0))
			set_es(esState, ES_Scale, random_float(0.06, 0.1))
			
			g_Muzzleflash[iHost][0] = 2
		}
		else if(g_Muzzleflash[iHost][0] == 2)
		{
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, random_float(200.0, 255.0))
			set_es(esState, ES_Scale, random_float(0.06, 0.1))
			
			g_Muzzleflash[iHost][0] = 1
			g_Muzzleflash[iHost][1] = 1
		}
		else if(g_Muzzleflash[iHost][0] == 1)
		{
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, random_float(200.0, 255.0))
			set_es(esState, ES_Scale, random_float(0.06, 0.1))
			
			g_Muzzleflash[iHost][0] = 0
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}
	else if(iEnt == g_Muzzleflash_Ent[1])
	{
		if(g_Muzzleflash[iHost][1])
		{
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 240.0)
			
			g_Muzzleflash[iHost][1] = 0
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}

}

public Forward_CheckVisibility(iEntity, pSet)
{
	if(iEntity == g_Muzzleflash_Ent[0] || iEntity == g_Muzzleflash_Ent[1])
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public Forward_PrecacheEvent_Post(type, const name[])
{
	new Buffer[512]
	formatex(Buffer, sizeof(Buffer), "events/%s.sc", system_base)
	if(equal(Buffer, name, 0))
	{
		g_orig_event = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public Forward_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, OLD_MODEL))
	{
		static iStoredAugID
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, weapon_base_buffer, entity)
			
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED

		if(g_has_weapon[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, WEAPON_KEY)
			g_has_weapon[iOwner] = 0
			entity_set_model(entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public Forward_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public Forward_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_BASE || !g_has_weapon[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public Forward_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if((eventid != g_orig_event) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if(!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

/* ================= END OF ALL FAKEMETA FORWARD ================= */
/* ================= START OF ALL MESSAGE FORWARD ================ */
public Forward_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, system_base) && get_user_weapon(iAttacker) == CSW_BASE)
	{
		if(g_has_weapon[iAttacker])
			set_msg_arg_string(4, system_name)
	}
	return PLUGIN_CONTINUE
}
/* ================== END OF ALL MESSAGE FORWARD ================ */
/* ================== START OF ALL EVENT FORWARD ================ */
public Forward_MessageWeapList(msg_id, msg_dest, id)
{
	if(get_msg_arg_int(8) != CSW_BASE)
		return
     
	g_list_variables[2] = get_msg_arg_int(2)
	g_list_variables[3] = get_msg_arg_int(3)
	g_list_variables[4] = get_msg_arg_int(4)
	g_list_variables[5] = get_msg_arg_int(5)
	g_list_variables[6] = get_msg_arg_int(6)
	g_list_variables[7] = get_msg_arg_int(7)
	g_list_variables[8] = get_msg_arg_int(8)
	g_list_variables[9] = get_msg_arg_int(9)
}

public Forward_CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))
     
	if(!is_user_alive(id))
		return
	if(read_data(2) != CSW_BASE || !g_has_weapon[id])
		return
     
	static Float:Speed
	if(g_has_weapon[id])
		Speed = get_pcvar_float(cvar_spd)
	
	static weapon[32], Ent
	get_weaponname(read_data(2), weapon, 31)
	Ent = find_ent_by_owner(-1, weapon, id)
	if(pev_valid(Ent))
	{
		static Float:Delay
		Delay = get_pdata_float(Ent, 46, 4) * Speed
		if(Delay > 0.0) set_pdata_float(Ent, 46, Delay, 4)
	}
}
/* ================== END OF ALL EVENT FORWARD =================== */
/* ================== START OF ALL HAM FORWARD ============== */
public Forward_PlayerKilled(id) remove_item(id)
public Forward_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iAttacker))
		return
	if(get_user_weapon(iAttacker) != CSW_BASE || !g_has_weapon[iAttacker])
		return

	static Float:flEnd[3], Float:WallVector[3], trace_color
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, WallVector)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	
	if(g_Mode[iAttacker] == MODE_A)
	{
		if(!is_user_alive(iEnt)) trace_color = get_pcvar_num(cvar_trace_color)
		else if(is_user_alive(iEnt)) trace_color = 2000 // NO STREAK COLOR or Disabled
		ExecuteHamB(Ham_TakeDamage, iEnt, iAttacker, iAttacker, flDamage * get_pcvar_float(cvar_dmg), DMG_BULLET)
	}
	
	if(pev(iEnt, pev_takedamage) != DAMAGE_NO)
	{
		set_hudmessage(255, 0, 0, -1.0, 0.46, 0, 0.2, 0.2)
		show_hudmessage(iAttacker, "\         /^n+^n/         \")
	}
	
	if(trace_color < 2000)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_STREAK_SPLASH)
		engfunc(EngFunc_WriteCoord, flEnd[0])
		engfunc(EngFunc_WriteCoord, flEnd[1])
		engfunc(EngFunc_WriteCoord, flEnd[2])
		engfunc(EngFunc_WriteCoord, WallVector[0] * random_float(25.0,30.0))
		engfunc(EngFunc_WriteCoord, WallVector[1] * random_float(25.0,30.0))
		engfunc(EngFunc_WriteCoord, WallVector[2] * random_float(25.0,30.0))
		write_byte(trace_color)
		write_short(50)
		write_short(3)
		write_short(90)	
		message_end()
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_short(iAttacker)
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
}

public Weapon_Deploy_Post(weapon_entity)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_entity)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_entity)
	
	replace_weapon_models(owner, weaponid)
}

public Weapon_AddToPlayer(weapon_entity, id)
{
	if(!is_valid_ent(weapon_entity) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(weapon_entity, EV_INT_WEAPONKEY) == WEAPON_KEY)
	{
		g_has_weapon[id] = true
		entity_set_int(weapon_entity, EV_INT_WEAPONKEY, 0)
		set_weapon_list(id, weapon_name_buffer)
		
		return HAM_HANDLED
	}
	else
	{
		set_weapon_list(id, weapon_base_buffer)
	}
	
	return HAM_IGNORED
}

public Weapon_PrimaryAttack(weapon_entity)
{
	new Player = get_pdata_cbase(weapon_entity, 41, 4)
	
	if(!g_has_weapon[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(weapon_entity)
}

public Weapon_PrimaryAttack_Post(weapon_entity)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(weapon_entity, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	
	if(!is_user_alive(Player))
		return
		
	if(g_has_weapon[Player])
	{
		if(!g_clip_ammo[Player])
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity)
			return
		}
		
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		set_weapon_shoot_anim(Player)
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_task(random_float(0.001, 0.005), "Re_MuzzleFlash", Player+TASK_MUZZLEFLASH)
	}
}

public Weapon_ItemPostFrame(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED

	static iClipExtra
	iClipExtra = get_pcvar_num(cvar_clip)
	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, OFFSET_LINUX)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_BASE)
	new iClip = get_pdata_int(weapon_entity, m_iClip, OFFSET_LINUX_WEAPONS)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, OFFSET_LINUX_WEAPONS) 
	if(fInReload && flNextAttack <= 0.0)
	{
		new j = min(iClipExtra - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, OFFSET_LINUX_WEAPONS)
		cs_set_user_bpammo(id, CSW_BASE, iBpAmmo-j)
		
		set_pdata_int(weapon_entity, m_fInReload, 0, OFFSET_LINUX_WEAPONS)
		fInReload = 0
	}
	else if(!fInReload && !get_pdata_int(weapon_entity, 74, 4))
	{
		if(!iClip)
			return HAM_IGNORED
			
		if(get_pdata_float(id, 83, 5) <= 0.0 && get_pdata_float(weapon_entity, 46, 4) <= 0.0 ||
		get_pdata_float(weapon_entity, 47, 4) <= 0.0 || get_pdata_float(weapon_entity, 48, 4) <= 0.0)
		{
			if(pev(id, pev_button) & IN_ATTACK)
			{
				if(g_Mode[id] == MODE_B)
					Shoot_Special(id)
			}
			else if(pev(id, pev_button) & IN_ATTACK2)
			{
				set_buffak_zoom(id, 0)
				set_weapons_timeidle(id, CSW_BASE, 0.4)
				set_player_nextattackx(id, 0.4)
			}
		}
	}
	
	return HAM_IGNORED
}

public Weapon_Reload(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(!g_has_weapon[id])
		return HAM_IGNORED
	static iClipExtra
	if(g_has_weapon[id])
		iClipExtra = get_pcvar_num(cvar_clip)

	g_weapon_TmpClip[id] = -1

	new iBpAmmo = cs_get_user_bpammo(id, CSW_BASE)
	new iClip = get_pdata_int(weapon_entity, m_iClip, OFFSET_LINUX_WEAPONS)

	if(iBpAmmo <= 0)
		return HAM_SUPERCEDE

	if(iClip >= iClipExtra)
		return HAM_SUPERCEDE

	g_weapon_TmpClip[id] = iClip

	return HAM_IGNORED
}

public Weapon_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if(!g_has_weapon[id])
		return HAM_IGNORED
	if(g_weapon_TmpClip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_int(weapon_entity, m_iClip, g_weapon_TmpClip[id], OFFSET_LINUX_WEAPONS)
	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, RELOAD_TIME, OFFSET_LINUX_WEAPONS)
	set_pdata_float(id, m_flNextAttack, RELOAD_TIME, OFFSET_LINUX)
	set_pdata_int(weapon_entity, m_fInReload, 1, OFFSET_LINUX_WEAPONS)
	
	set_weapon_anim(id, ANIM_RELOAD)
	set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
	set_buffak_zoom(id, 1)
	
	return HAM_IGNORED
}

/* ===================== END OF ALL HAM FORWARD ====================== */
/* ================= START OF OTHER PUBLIC FUNCTION  ================= */
public give_item(id)
{
	drop_weapons(id, 1)
	new iWeapon = fm_give_item(id, weapon_base_buffer)
	if(iWeapon > 0)
	{
		cs_set_weapon_ammo(iWeapon, get_pcvar_num(cvar_clip))
		cs_set_user_bpammo(id, CSW_BASE, get_pcvar_num(cvar_ammo))
		emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM,0,PITCH_NORM)
		
		set_weapon_anim(id, ANIM_DRAW)
		set_pdata_float(id, m_flNextAttack, DRAW_TIME, OFFSET_LINUX)
		
		set_weapon_list(id, weapon_name_buffer)
		set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
		set_pdata_int(iWeapon, 74, MODE_A)
	}
	
	g_has_weapon[id] = true
	g_Mode[id] = MODE_A
	remove_bitvar(id)
}

public remove_item(id)
{
	g_has_weapon[id] = false
	g_Mode[id] = MODE_A
	remove_bitvar(id)
}

public remove_bitvar(id)
{
	g_attack_type[id] = 0
	g_Muzzleflash[id][0] = 0
	g_Muzzleflash[id][1] = 0
}

public weapon_hook(id)
{
	engclient_cmd(id, weapon_base_buffer)
	return PLUGIN_HANDLED
}

public replace_weapon_models(id, weaponid)
{
	if(weaponid != CSW_BASE)
	{
		if(g_has_weapon[id])
		{
			remove_bitvar(id)
			set_buffak_zoom(id, 1)
		}
	}
	
	switch(weaponid)
	{
		case CSW_BASE:
		{
			if(g_has_weapon[id])
			{
				set_pev(id, pev_viewmodel2, V_MODEL)
				set_pev(id, pev_weaponmodel2, P_MODEL)
				
				if(oldweap[id] != CSW_BASE) 
				{
					set_weapon_anim(id, ANIM_DRAW)
					set_player_nextattackx(id, DRAW_TIME)
					set_weapons_timeidle(id, CSW_BASE, DRAW_TIME)
					set_weapon_list(id, weapon_name_buffer)
					set_pdata_string(id, (492) * 4, ANIMEXT, -1 , 20)
				}
			}
		}
	}
	
	oldweap[id] = weaponid
}

public Shoot_Special(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
		
	new szClip, szWeapId
	szWeapId = get_user_weapon(id, szClip)
	if(szWeapId != CSW_BASE || !g_has_weapon[id] || !szClip)
		return
	
	g_Muzzleflash[id][0] = 3
	set_task(random_float(0.001, 0.005), "Re_MuzzleFlash", id+TASK_MUZZLEFLASH)
	
	static Float:PunchAngles[3]
	PunchAngles[0] = -5.0
	PunchAngles[1] = -2.5
	PunchAngles[2] = -2.5
	set_pev(id, pev_punchangle, PunchAngles)
	
	set_weapon_shoot_anim(id)
	emit_sound(id, CHAN_WEAPON, Fire_Sounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	new Float:fStart[3], Float:originF[3]
	new target, body
	
	fm_get_aim_origin(id, originF)
	get_user_aiming(id, target, body)
	
	pev(id, pev_origin, fStart)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fStart, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2] + 20.0)
	write_short(sBuffakHit)
	write_byte(10)
	write_byte(240)
	message_end()
	
	new a = FM_NULLENT
	while((a = find_ent_in_sphere(a, originF, float(get_pcvar_num(cvar_radius)))) != 0)
	{
		if(id == a)
			continue
	
		if(pev(a, pev_takedamage) != DAMAGE_NO)
			ExecuteHamB(Ham_TakeDamage, a, 0, id, float(get_pcvar_num(cvar_dmg_2)), DMG_BULLET)
	}
	
	if(!is_user_alive(target))
	{
		static Classname[32]
		pev(target, pev_classname, Classname, sizeof(Classname))
		
		if(equal(Classname, "func_breakable"))
			ExecuteHamB(Ham_TakeDamage, target, 0, 0, float(get_pcvar_num(cvar_dmg_2)), DMG_GENERIC)
	}
	else if(is_user_alive(target) && is_user_connected(target))
	{
		static Float:MyOrigin[3]
		pev(id, pev_origin, MyOrigin)
		hook_ent2(target, MyOrigin, 400.0, 2)
		ExecuteHamB(Ham_TakeDamage, target, 0, id, float(get_pcvar_num(cvar_dmg_2))*0.75, DMG_BULLET)
	}
	
	static entity_weapon
	entity_weapon = find_ent_by_owner(ENG_NULLENT, weapon_base_buffer, id)
	
	if(!pev_valid(entity_weapon))
		return
	
	cs_set_weapon_ammo(entity_weapon, szClip - 1)
	set_player_nextattackx(id, 0.7)
	set_weapons_timeidle(id, CSW_BASE, 0.7)
}

public set_weapon_shoot_anim(id)
{
	if(!g_attack_type[id])
	{
		set_weapon_anim(id, ANIM_SHOOT1)
		g_attack_type[id] = 1
	}
	else if(g_attack_type[id] == 1)
	{
		set_weapon_anim(id, ANIM_SHOOT2)
		g_attack_type[id] = 2
	}
	else if(g_attack_type[id] == 2)
	{
		set_weapon_anim(id, ANIM_SHOOT3)
		g_attack_type[id] = 0
	}
}

public Re_MuzzleFlash(id)
{
	id -= TASK_MUZZLEFLASH

	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_BASE || !g_has_weapon[id])
		return
	
	if(g_Mode[id] == MODE_A) g_Muzzleflash[id][0] = true
	else if(g_Mode[id] == MODE_B) g_Muzzleflash[id][1] = true
}

/* ============= END OF OTHER PUBLIC FUNCTION (Weapon) ============= */
/* ================= START OF ALL STOCK TO MACROS ================== */
stock set_buffak_zoom(id, const reset = 0)
{
	if(reset == 1)
	{
		set_fov(id)
		g_Mode[id] = MODE_A
	}
	else if(reset == 0)
	{
		if(g_Mode[id] == MODE_A)
		{
			set_fov(id, 80)
			g_Mode[id] = MODE_B
		}
		else if(g_Mode[id] == MODE_B)
		{
			set_fov(id)
			g_Mode[id] = MODE_A
		}
	}
}

stock set_fov(id, fov = 90)
{
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(fov)
	message_end()
}

stock set_weapon_list(id, const weapon_name[])
{
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id)
	write_string(weapon_name)
	write_byte(g_list_variables[2])
	write_byte(g_list_variables[3])
	write_byte(g_list_variables[4])
	write_byte(g_list_variables[5])
	write_byte(g_list_variables[6])
	write_byte(g_list_variables[7])
	write_byte(g_list_variables[8])
	write_byte(g_list_variables[9])
	message_end()
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = 100.0
	
	new Float:fl_Time = distance_f / speed
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	}
	else if(type == 2)
	{
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}
	
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock drop_weapons(id, dropwhat)
{
	static weapons[32], num = 0, i, weaponid
	get_user_weapons(id, weapons, num)
     
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
          
		if(dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		{
			static wname[32]
			get_weaponname(weaponid, wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 47, TimeIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(entwpn, 48, TimeIdle + 1.0, OFFSET_LINUX_WEAPONS)
}

stock set_weapons_timeidlex(id, Float:TimeIdle, Float:Idle)
{
	new entwpn = fm_get_user_weapon_entity(id, CSW_BASE)
	if(!pev_valid(entwpn)) 
		return
	
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, Idle, 4)
}

stock set_weapon_anim(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock precache_viewmodel_sound(const model[]) // I Get This From BTE
{
	new file, i, k
	if((file = fopen(model, "rt")))
	{
		new szsoundpath[64], NumSeq, SeqID, Event, NumEvents, EventID
		fseek(file, 164, SEEK_SET)
		fread(file, NumSeq, BLOCK_INT)
		fread(file, SeqID, BLOCK_INT)
		
		for(i = 0; i < NumSeq; i++)
		{
			fseek(file, SeqID + 48 + 176 * i, SEEK_SET)
			fread(file, NumEvents, BLOCK_INT)
			fread(file, EventID, BLOCK_INT)
			fseek(file, EventID + 176 * i, SEEK_SET)
			
			// The Output Is All Sound To Precache In ViewModels (GREAT :V)
			for(k = 0; k < NumEvents; k++)
			{
				fseek(file, EventID + 4 + 76 * k, SEEK_SET)
				fread(file, Event, BLOCK_INT)
				fseek(file, 4, SEEK_CUR)
				
				if(Event != 5004)
					continue
				
				fread_blocks(file, szsoundpath, 64, BLOCK_CHAR)
				
				if(strlen(szsoundpath))
				{
					strtolower(szsoundpath)
					engfunc(EngFunc_PrecacheSound, szsoundpath)
				}
			}
		}
	}
	fclose(file)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

/* ================= END OF ALL STOCK AND PLUGINS CREATED ================== */
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
