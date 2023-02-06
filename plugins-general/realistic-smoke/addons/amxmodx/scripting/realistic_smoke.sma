#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>

new const PLUGIN_NAME[] = "Realistic Smoke";
new const PLUGIN_VERSION[] = "0.4";
new const PLUGIN_AUTHOR[] = "6u3oH";

new const SMOKE_DEFAULT_CLASSNAME[] = "grenade";
new const SMOKE_CUSTOM_CLASSNAME[] = "realistic_smoke";
new const SMOKE_CUSTOM_SPRITE[] = "sprites/realistic_smoke/realistic_smoke.spr";
new const SMOKE_DAMAGE_SOUND[][] =
{
	"realistic_smoke/smoke_damage_1.wav",
	"realistic_smoke/smoke_damage_2.wav",
	"realistic_smoke/smoke_damage_3.wav"
};
new const SMOKE_MODEL_FAKE_ZONE[] = "models/realistic_smoke/smoke_fake_blue_zone.mdl";
new const SMOKE_SOUND_EXPLODE[] = "weapons/sg_explode.wav";
new const SMOKE_ICON_GAS[] = "dmg_gas";
//
const TASK_ICON_GAS = 0xA715;

enum any: CvarsStruct
{
	Float: CVAR_DAMAGE_PERIOD,
	CVAR_DAMAGE_VALUE,
	CVAR_SMOKE_LIFETIME,
	CVAR_REMOVE_GRENADE
};

new
	g_iSmokeSpriteIndex,
	g_iBubbleSpriteIndex,
	g_iMsgStatusValueIndex,
	g_iMsgStatusIconIndex,
	g_eCvar[CvarsStruct];

public plugin_precache()
{
	precache_model(SMOKE_MODEL_FAKE_ZONE);
	precache_model(SMOKE_CUSTOM_SPRITE);

	g_iSmokeSpriteIndex = precache_model(SMOKE_CUSTOM_SPRITE);
	g_iBubbleSpriteIndex = precache_model("sprites/bubble.spr");

	for(new i; i < sizeof(SMOKE_DAMAGE_SOUND); i++)
		precache_sound(SMOKE_DAMAGE_SOUND[i]);
}

public client_disconnected(pPlayer)
{
	new eEnt;

	if(!g_eCvar[CVAR_REMOVE_GRENADE])
	{
		eEnt = NULLENT;
		while((eEnt = rg_find_ent_by_class(eEnt, SMOKE_DEFAULT_CLASSNAME)))
			if(!is_nullent(eEnt) && get_entvar(eEnt, var_iuser3) == pPlayer)
				rg_remove_entity(eEnt);
	}

	eEnt = NULLENT;
	while((eEnt = rg_find_ent_by_class(eEnt, SMOKE_CUSTOM_CLASSNAME)))
		if(!is_nullent(eEnt) && get_entvar(eEnt, var_iuser3) == pPlayer)
			rg_remove_entity(eEnt);
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true);
	RegisterHookChain(RG_CGrenade_ExplodeSmokeGrenade, "@CGrenade_ExplodeSmokeGrenade_Pre");

	register_message((g_iMsgStatusValueIndex = get_user_msgid("StatusValue")), "@message_StatusValue");
	g_iMsgStatusIconIndex = get_user_msgid("StatusIcon");

	@cvars_attach();
}

@CSGameRules_RestartRound_Post()
{
	new eEnt;

	if(!g_eCvar[CVAR_REMOVE_GRENADE])
	{
		eEnt = NULLENT;
		while((eEnt = rg_find_ent_by_class(eEnt, SMOKE_DEFAULT_CLASSNAME)))
			if(!is_nullent(eEnt))
				rg_remove_entity(eEnt);
	}

	eEnt = NULLENT;
	while((eEnt = rg_find_ent_by_class(eEnt, SMOKE_CUSTOM_CLASSNAME)))
		if(!is_nullent(eEnt))
			rg_remove_entity(eEnt);
}

@CGrenade_ExplodeSmokeGrenade_Pre(eSmoke)
{
	new Float: fOrigin[3];
	get_entvar(eSmoke, var_origin, fOrigin);

	if(get_entvar(eSmoke, var_waterlevel))
	{
		set_msg_bubbles(fOrigin, 100, g_iBubbleSpriteIndex, 30, 10);

		set_entvar(eSmoke, var_angles, Float: {0.0, 0.0, 0.0});
		set_entvar(eSmoke, var_avelocity, Float: {0.0, 0.0, 0.0});

		if(g_eCvar[CVAR_REMOVE_GRENADE])
			rg_remove_entity(eSmoke);
	}else{
		new
			eZone,
			Float: fAngles[3],
			Float: fGameTime;

		fGameTime = get_gametime();

		get_entvar(eSmoke, var_angles, fAngles);

		eZone = rg_create_entity("info_target");

		engfunc(EngFunc_SetOrigin, eZone, fOrigin);
		engfunc(EngFunc_SetModel, eZone, SMOKE_MODEL_FAKE_ZONE);
		engfunc(EngFunc_SetSize, eZone, Float: { -150.0, -150.0, -35.0 }, Float: { 150.0, 150.0, 55.0 });

		set_entvar(eZone, var_classname, SMOKE_CUSTOM_CLASSNAME);
		set_entvar(eZone, var_movetype, MOVETYPE_NOCLIP);
		set_entvar(eZone, var_solid, SOLID_TRIGGER);
		set_entvar(eZone, var_iuser3, get_entvar(eSmoke, var_owner));
		set_entvar(eZone, var_effects, get_entvar(eZone, var_effects) | EF_NODRAW);
		set_entvar(eZone, var_nextthink, fGameTime + float(g_eCvar[CVAR_SMOKE_LIFETIME]));

		SetThink(eZone, "@smoke_think");
		SetTouch(eZone, "@smoke_touch");

		emit_sound(eZone, CHAN_STATIC, SMOKE_SOUND_EXPLODE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_msg_firefield(fOrigin, 100, g_iSmokeSpriteIndex, 30, (TEFIRE_FLAG_ALPHA|TEFIRE_FLAG_PLANAR), g_eCvar[CVAR_SMOKE_LIFETIME]);
	}

	if(g_eCvar[CVAR_REMOVE_GRENADE])
		rg_remove_entity(eSmoke);

	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

@message_StatusValue(iMsgIndex, iMsgDest, pPlayer)
{
	new 
		eEnt,
		Float: fOriginEye[3],
		Float: fOriginAiming[3];

	eEnt = NULLENT;
	get_origin_eye_aiming(pPlayer, fOriginEye, fOriginAiming);

	while((eEnt = rg_find_ent_by_class(eEnt, SMOKE_CUSTOM_CLASSNAME)))
	{
		engfunc(EngFunc_TraceModel, fOriginEye, fOriginAiming, HULL_POINT, eEnt, 0);

		if(get_tr2(0, TR_pHit) == eEnt)
		{
			for(new i = 1; i <= 3; i++)
			{
				message_begin(MSG_ONE_UNRELIABLE, g_iMsgStatusValueIndex, .player = pPlayer);
				write_byte(i);
				write_short(0);
				message_end();
			}

			break;
		}
	}
}

@smoke_think(eEnt)
{
	rg_remove_entity(eEnt);
}

@smoke_touch(eEnt, pPlayer)
{
	if(!is_user_connected(pPlayer))
		return;

	static
		pOwner,
		Float: fGameTime,
		Float: fDamageTime[MAX_PLAYERS+1],
		Float: fHealth;

	fGameTime = get_gametime();
	pOwner = get_entvar(eEnt, var_iuser3);

	if(fDamageTime[pPlayer] < fGameTime && pPlayer != pOwner && rg_is_player_can_takedamage(pPlayer, pOwner) && fm_is_ent_visible(pPlayer, eEnt))
	{
		fHealth = Float: get_entvar(pPlayer, var_health) - float(g_eCvar[CVAR_DAMAGE_VALUE]);

		if(fHealth > 1)
			set_entvar(pPlayer, var_health, fHealth);
		else
			ExecuteHamB(Ham_TakeDamage, pPlayer, eEnt, pOwner, 1000.0, DMG_NERVEGAS);

		emit_sound(pPlayer, CHAN_STATIC, SMOKE_DAMAGE_SOUND[random(sizeof(SMOKE_DAMAGE_SOUND))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		fDamageTime[pPlayer] = fGameTime + Float: g_eCvar[CVAR_DAMAGE_PERIOD];

		remove_task(pPlayer + TASK_ICON_GAS);
		set_task(3.0, "@func_remove_icon", pPlayer + TASK_ICON_GAS);
		set_msg_status_icon(pPlayer, 1, SMOKE_ICON_GAS, 255, 0, 0);
	}
}

@func_remove_icon(pPlayer)
{
	pPlayer -= TASK_ICON_GAS;

	if(!is_user_connected(pPlayer))
		return;

	set_msg_status_icon(pPlayer, 0, SMOKE_ICON_GAS, 0, 0, 0);
}

@cvars_attach()
{
	bind_pcvar_float(
		create_cvar(
			"rs_damage_period", "1.0", FCVAR_SERVER,
			.description = "Период получения игроком урона от дыма (в секундах)",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), Float: g_eCvar[CVAR_DAMAGE_PERIOD]
	);

	bind_pcvar_num(
		create_cvar(
			"rs_damage_value", "5", FCVAR_SERVER,
			.description = "Урон от дыма, наносимый за временной период",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_DAMAGE_VALUE]
	);

	bind_pcvar_num(
		create_cvar(
			"rs_smoke_ltime", "15", FCVAR_SERVER,
			.description = "Время существования дыма",
			.has_min = false, .min_val = 0.0,
			.has_max = false, .max_val = 0.0
		), g_eCvar[CVAR_SMOKE_LIFETIME]
	);

	bind_pcvar_num(
		create_cvar(
			"rs_smoke_grenade_remove", "1", FCVAR_SERVER,
			.description = "Удалять гранату? 1 - да, 0 - нет",
			.has_min = true, .min_val = 0.0,
			.has_max = true, .max_val = 1.0
		), g_eCvar[CVAR_REMOVE_GRENADE]
	);

	AutoExecConfig(true);
}

stock rg_remove_entity(eEnt)
{
	set_entvar(eEnt, var_flags, FL_KILLME);
	set_entvar(eEnt, var_nextthink, -1.0);
}

stock set_msg_firefield(Float: fOrigin[3], iRadius, iSpriteIndex, iSpritesCount, iFlags, iDuration)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_FIREFIELD);
	write_coord_f(fOrigin[0]);
	write_coord_f(fOrigin[1]);
	write_coord_f(fOrigin[2] + 50.0);
	write_short(iRadius);
	write_short(iSpriteIndex);
	write_byte(iSpritesCount);
	write_byte(iFlags);
	write_byte(iDuration*10);
	message_end();
}

stock set_msg_bubbles(Float: fOrigin[3], iHeight, iSpriteIndex, iCount, iSpeed)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BUBBLES);
	write_coord_f(fOrigin[0] - 10.0);
	write_coord_f(fOrigin[1] - 10.0);
	write_coord_f(fOrigin[2] - 30.0);
	write_coord_f(fOrigin[0] + 10.0);
	write_coord_f(fOrigin[1] + 10.0);
	write_coord_f(fOrigin[2] + 30.0);
	write_coord(iHeight);
	write_short(iSpriteIndex);
	write_byte(iCount);
	write_coord(iSpeed);
	message_end();
}

stock set_msg_status_icon(pPlayer, iStatus, const sSpriteName[], iRed, iGreen, iBlue)
{
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgStatusIconIndex, .player = pPlayer);
	write_byte(iStatus);
	write_string(sSpriteName);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	message_end();
}

stock get_origin_eye_aiming(pPlayer, Float: fDest1[3], Float: fDest2[3])
{
	get_entvar(pPlayer, var_origin, fDest1);
	get_entvar(pPlayer, var_view_ofs, fDest2);

	xs_vec_add(fDest1, fDest2, fDest1);

	get_entvar(pPlayer, var_v_angle, fDest2);
	engfunc(EngFunc_MakeVectors, fDest2);
	global_get(glb_v_forward, fDest2);

	xs_vec_mul_scalar(fDest2, 8192.0, fDest2);
	xs_vec_add(fDest1, fDest2, fDest2);

	engfunc(EngFunc_TraceLine, fDest1, fDest2, DONT_IGNORE_MONSTERS, pPlayer, 0);
	get_tr2(0, TR_vecEndPos, fDest2);
}