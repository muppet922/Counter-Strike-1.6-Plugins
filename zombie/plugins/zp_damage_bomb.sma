/////////////////////////////////////////////////////////
//                 MODIFIED BY: zmd94                  //
/////////////////////////////////////////////////////////
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <zombie_plague_special>

const Float:NADE_EXPLOSION_RADIUS = 240.0
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_DBOMB1 = 6669
const COLOR_R = 237
const COLOR_G = 60
const COLOR_B = 202

#define ITEM_NAME "\r[\yZP\r]\yDamage Bomb"
#define DAMAGE_DEALT_1 25.0
#define MODEL_P "models/zombie_plague/p_zombibomb.mdl"
#define MODEL_V "models/zombie_plague/v_zombibomb.mdl"
#define MODEL_W "models/zombie_plague/w_zombibomb.mdl"
#define SOUND_BUY "zombie_plague/killbomb_buy.wav"
#define SOUND_EXPLODE "zombie_plague/killbomb_exp.wav"
#define WEAPON_REF "weapon_smokegrenade"

new SprTrail, SprExplode, bHasBomb1[33]

public plugin_precache()
{
	SprTrail = precache_model("sprites/laserbeam.spr")
	SprExplode = precache_model("sprites/skull.spr")

	precache_model(MODEL_P)
	precache_model(MODEL_V)
	precache_model(MODEL_W)

	precache_sound(SOUND_BUY)
	precache_sound(SOUND_EXPLODE)
}

public plugin_init()
{
	register_plugin(ITEM_NAME, "1.0", "wbyokomo")
	g_itemid = zp_register_extra_item("\r[\yZP\r]\yDamage Bomb)", 35, ZP_TEAM_ZOMBIE)


	register_event("DeathMsg", "OnDeathMsg", "a")

	RegisterHam(Ham_Item_Deploy, WEAPON_REF, "OnSgDeployPost", 1)
	RegisterHam(Ham_Think, "grenade", "OnThinkGrenade")

	register_forward(FM_SetModel, "OnSetModel")
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

public client_disconnected(id)
{
	bHasBomb1[id] = 0
}

public OnDeathMsg()
{
	new id = read_data(2)
	if(is_user_connected(id)) bHasBomb1[id] = 0;
}

public zp_user_infected_post(id)
{
	bHasBomb1[id] = 1
	give_item(id, WEAPON_REF)
	emit_sound(id, CHAN_VOICE, SOUND_BUY, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public zp_user_humanized_post(id)
{
	bHasBomb1[id] = 0
}

public OnSgDeployPost(ent)
{
	static id; id = get_pdata_cbase(ent, 41, 4);
	if(!is_user_connected(id)) return;
	if(!bHasBomb1[id]) return;
	if(!zp_get_user_zombie(id)) return;

	set_pev(id, pev_viewmodel2, MODEL_V)
	set_pev(id, pev_weaponmodel2, MODEL_P)
}

public OnThinkGrenade(ent)
{
	if(!pev_valid(ent)) return HAM_IGNORED;

	static Float:dmgtime; pev(ent, pev_dmgtime, dmgtime);
	if(dmgtime > get_gametime()) return HAM_IGNORED;

	if(pev(ent, PEV_NADE_TYPE) == NADE_TYPE_DBOMB1)
	{
		DBomb1Explode(ent)
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public OnSetModel(ent, const model[])
{
	if(!pev_valid(ent)) return FMRES_IGNORED;

	static Float:dmgtime; pev(ent, pev_dmgtime, dmgtime);
	if(dmgtime == 0.0) return FMRES_IGNORED;

	static owner; owner = pev(ent, pev_owner);
	if(!is_user_connected(owner)) return FMRES_IGNORED;
	if(!bHasBomb1[owner]) return FMRES_IGNORED;
	if(!zp_get_user_zombie(owner)) return FMRES_HANDLED;

	if(model[9] == 's' && model[10] == 'm')
	{
		bHasBomb1[owner] = 0
		set_pev(ent, PEV_NADE_TYPE, NADE_TYPE_DBOMB1)
		set_rendering(ent, kRenderFxGlowShell, COLOR_R, COLOR_G, COLOR_B, kRenderNormal, 0)

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(ent)
		write_short(SprTrail)
		write_byte(10)
		write_byte(3)
		write_byte(COLOR_R)
		write_byte(COLOR_G)
		write_byte(COLOR_B)
		write_byte(192)
		message_end()

		engfunc(EngFunc_SetModel, ent, MODEL_W)
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

DBomb1Explode(ent)
{
	static Float:originF[3]
	pev(ent, pev_origin, originF)

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2])
	write_short(SprExplode)
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()

	emit_sound(ent, CHAN_WEAPON, SOUND_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_NORM)

	static attacker; attacker = pev(ent, pev_owner);
	if(!is_user_connected(attacker))
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}

	static victim; victim = -1;
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, NADE_EXPLOSION_RADIUS)) != 0)
	{
		if(is_user_alive(victim) && !zp_get_user_zombie(victim))
		{
			ExecuteHam(Ham_TakeDamage, victim, ent, attacker, DAMAGE_DEALT_1, DMG_BULLET)
		}
	}

	engfunc(EngFunc_RemoveEntity, ent)
}
