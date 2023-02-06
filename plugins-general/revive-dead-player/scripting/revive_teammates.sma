/*
	Поддержать автора:
	2200 0202 2057 0834 - мир
	+79788978612 - киви
*/

#define PLUGIN			"Revive/Mined Die Players"
#define VERSION			"2.3.9"

//#define UNSTUCK			// если у вас люди при воскрешении застряют люди в текстурах (и если у вас есть прохождения сквозь свових) то расскоментируйте это.
//#define SKIN			// активируйте если у вас есть субмодели (skin) в моделях

new const CORPSE_CLASSNAME[] = "info_corpse";

#define NOTIFY(%0,%1,%2,%3) \
	%0(%1, %2, %3); \
	\
	if ((1 << %2) & ((1 << print_team_red) | (1 << print_center)) && CVAR[SOUND_NOTIFICATION]) \
		client_cmd(%1, "spk ^"buttons/blip2.wav^"");


#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <emma_jule>
//#include <aes_v>


enum _:CVARS
{
	ACCESS[16],
	MAX_SPAWNS,
	MAX_REVIVALS,
	MAX_MINES,
	DURATION,
	OBSERVER,
	NO_FIRE,
	RENDER,
	BAR,
	Float:RADIUS,
	Float:DAMAGE,
	Float:SHOCK,
	SCREENPUNCH,
	SPAWN_MODE,
#if REAPI_VERSION >= 5200231
	GIBS,
#endif
	GUN[256],
	Float:NEW_HEALTH,
	Float:BONUS_HEALTH,
	FRAGS,
	NO_DEATH,
	COST,
	DUEL,
	BOMB,
	VIP,
	ROUND,
	DOMINATION,
	Float:TIME_EXPIRED,
	SOUND_NOTIFICATION,
	DONT_MOTION,
	CAN_MINED,
	NOTIFICATION,
	REVIVE_SAMPLE[MAX_RESOURCE_PATH_LENGTH],
	MINED_SAMPLE[MAX_RESOURCE_PATH_LENGTH],
	EXPLODE_SAMPLE[MAX_RESOURCE_PATH_LENGTH],
	SIZE[64],
	
};	new CVAR[CVARS];


// Дата на каждого игрока
enum _:REVIVE_DATA
{
	CORPSE,
	IS_REVIVING,
	REVIVALS_COUNT,
	MINES_COUNT,
	
};	new eCorpseStruct[MAX_PLAYERS + 1][REVIVE_DATA];


new g_iAccessFlags, g_iPreventFlags;
new g_sModelIndexFireball, g_sModelIndexFireball2, g_sModelIndexFireball3;
new Float:g_vecCorpseMins[3], Float:g_vecCorpseMaxs[3];
new Float:flNextCorpseUsingTime[MAX_PLAYERS + 1];

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, "Emma Jule");
	
	@CreateCvars();
	
	// def sprites
	g_sModelIndexFireball = precache_model("sprites/zerogxplode.spr");
	g_sModelIndexFireball2 = precache_model("sprites/eexplo.spr");
	g_sModelIndexFireball3 = precache_model("sprites/fexplo.spr");
}

public plugin_init()
{
	if (register_dictionary("revive_teammates.txt") == 0) {
		//createLangFile("revive_teammates.txt");
	}
	
	register_event("TeamInfo", "Event_TeamInfo", "a", "1>0");
	register_message(get_user_msgid("ClCorpse"), "@CorpseSpawn");
	
	RegisterHookChain(RG_CSGameRules_CleanUpMap, "CSGameRules_CleanUpMap", true);
	if (CVAR[DONT_MOTION])
		RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "CBasePlayer_ResetMaxSpeed", true);
	
	RegisterHam(Ham_ObjectCaps, "info_target", "fw_ObjectCaps", false);
}

public Event_TeamInfo()
{
	@CorpseRemove(read_data(1));
}

public CSGameRules_CleanUpMap()
{
	new id = rg_find_ent_by_class(NULLENT, CORPSE_CLASSNAME);
	
	while (id > 0)
	{
		@CorpseRemove(get_entvar(id, var_owner));
		
		id = rg_find_ent_by_class(id, CORPSE_CLASSNAME);
	}
	
	arrayset(eCorpseStruct[0][_:0], 0, sizeof(eCorpseStruct) * sizeof(eCorpseStruct[]));
}

public CBasePlayer_ResetMaxSpeed(id)
{
	if (eCorpseStruct[id][IS_REVIVING])
	{
		set_entvar(id, var_maxspeed, 1.0);
	}
}

public fw_ObjectCaps(id)
{
	if (!FClassnameIs(id, CORPSE_CLASSNAME)) {
		return HAM_IGNORED;
	}
	
	SetHamReturnInteger(FCAP_ONOFF_USE);
	return HAM_OVERRIDE;
}

public Corpse_Use(id, activator, caller, USE_TYPE:useType, Float:value)
{
	if (value == 0.0)
		return;
	
	if (activator != caller)
		return;
	
	if (!ExecuteHam(Ham_IsPlayer, activator))
		return;
	
	// static Float:flCurTime;
	new Float:flCurTime = get_gametime();
	
	// static Float:flNextCorpseUsingTime[MAX_PLAYERS + 1];
	if (flNextCorpseUsingTime[activator] > flCurTime)
		return;
	
	flNextCorpseUsingTime[activator] = flCurTime + 0.1;
	
	// if (~get_entvar(activator, var_flags) & FL_ONGROUND)
		// return;
	
	if (rg_get_current_round() < CVAR[ROUND])
	{
		NOTIFY(client_print_color, activator, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_ROUND", CVAR[ROUND])
		return;
	}
	
	if (!rg_is_time_expired(CVAR[TIME_EXPIRED]))
	{
		NOTIFY(client_print_color, activator, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_TIME_RESTRICTIONS", CVAR[TIME_EXPIRED])
		return;
	}
	
	new TeamName:team = get_member(activator, m_iTeam);
	if (CVAR[DOMINATION] > 0 && rg_get_team_wins_row(CVAR[DOMINATION]) == team)
	{
		NOTIFY(client_print_color, activator, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_DOMINATION")
		return;
	}
	
	if (CVAR[VIP] && get_member(activator, m_bIsVIP))
	{
		NOTIFY(client_print, activator, print_center, "%L", LANG_PLAYER, "RT_VIP_PERSON")
		return;
	}
	
	if ((caller = get_entvar(id, var_euser1)) > 0)
	{
		NOTIFY(client_print, activator, print_center, "%L", LANG_PLAYER, "RT_ALREADY_USING_BY", caller)
		return;
	}
	
	if (UTIL_IsRestricted(id, activator))
		return;
	
	// Получаем владельца трупа
	caller = get_entvar(id, var_owner);
	
	// ВОСКРЕШЕНИЕ
	if (team == get_entvar(id, var_team))
	{
		if (get_member(caller, m_iNumSpawns) > CVAR[MAX_SPAWNS])
		{
			NOTIFY(client_print, activator, print_center, "%L", LANG_PLAYER, "RT_MAX_SPAWNS")
			return;
		}
		
		if (eCorpseStruct[activator][REVIVALS_COUNT] >= CVAR[MAX_REVIVALS])
		{
			NOTIFY(client_print, activator, print_center, "%L", LANG_PLAYER, "RT_MAX_REVIVALS", CVAR[MAX_REVIVALS])
			return;
		}
		
		set_dhudmessage(0, 160, 30, -1.0, 0.76, 2, 3.0, 2.0, 0.03, 0.4);
		show_dhudmessage(caller, "%L", LANG_PLAYER, "RT_REVIVED", activator);
		
		set_dhudmessage(0, 160, 30, -1.0, 0.76, 2, 3.0, 2.0, 0.03, 0.4);
		show_dhudmessage(activator, "%L", LANG_PLAYER, "RT_REVIVING", caller, CVAR[DURATION]);
		
		if (CVAR[OBSERVER])
		{
			// set_entvar(caller, var_iuser2, OBS_IN_EYE);
			rg_internal_cmd(caller, "specmode", "4");
			set_entvar(caller, var_iuser2, activator);
			
			set_member(caller, m_hObserverTarget, activator);
			set_member(caller, m_flNextObserverInput, flCurTime + 1.6);
		}
	}
	// МИНИРОВАНИЕ
	else
	{
		if (!CVAR[CAN_MINED])
		{
			// NOTIFY(client_print, activator, print_center, "%L", LANG_PLAYER, "RT_NO_MINED_MODE")
			return;
		}
		
		if (get_entvar(id, var_euser2) > 0)
		{
			NOTIFY(client_print, activator, print_center, "%L", LANG_PLAYER, "RT_ALREADY_MINED")
			return;
		}
		
		if (eCorpseStruct[activator][MINES_COUNT] >= CVAR[MAX_MINES])
		{
			NOTIFY(client_print, activator, print_center, "%L", LANG_PLAYER, "RT_MAX_MINES", CVAR[MAX_MINES])
			return;
		}
		
		set_dhudmessage(160, 0, 30, -1.0, 0.76, 2, 3.0, 2.0, 0.03, 0.4);
		show_dhudmessage(activator, "%L", LANG_PLAYER, "RT_MINING", caller);
	}
	
	// Присваеваем булевую которую можно проверять в других функциях
	eCorpseStruct[activator][IS_REVIVING] = true;
	
	// Ограничиваем движение игрока согласно флагам
	set_entvar(activator, var_iuser3, get_entvar(activator, var_iuser3) | g_iPreventFlags);
	
	if (CVAR[NO_FIRE]) {
		set_member(activator, m_bIsDefusing, true);
	}
	
	if (CVAR[BAR]) {
		rg_send_bartime(activator, CVAR[DURATION]);
	}
	
	if (CVAR[DONT_MOTION])
	{
		rg_reset_maxspeed(activator);
		set_entvar(activator, var_velocity, NULL_VECTOR);
	}
	
	set_entvar(id, var_euser1, activator);
	set_entvar(id, var_fuser1, flCurTime + float(CVAR[DURATION]));
	set_entvar(id, var_nextthink, flCurTime + 0.1);
	
	if (CVAR[RENDER])
	{
		UTIL_Render(id,
			.mode = kRenderTransAlpha,
			.flColor = Float:{ 200.0, 200.0, 200.0 },
			.fAmount = 200.0
		);
	}
}

public Corpse_Think(id)
{
	// Get Activator
	new pActivator = get_entvar(id, var_euser1);
	
	if (!VALID_PLAYER(pActivator)) {
		// return;
	}
	
	if (!is_user_alive(pActivator) || ~get_entvar(pActivator, var_button) & IN_USE || UTIL_IsRestricted(id, pActivator))
	{
		ResetRestrictions(id, !is_user_connected(pActivator) ? 0 : pActivator);
		return;
	}
	
	new Float:flTimeLeft;
	get_entvar(id, var_fuser1, flTimeLeft);
	if ((flTimeLeft != 0.0 && get_gametime() >= flTimeLeft))
	{
		new Float:vecSrc[3];
		get_entvar(id, var_origin, vecSrc);
		
		if (get_member(pActivator, m_iTeam) != get_entvar(id, var_team))
		{
			if (CVAR[MINED_SAMPLE][0]) {
				rh_emit_sound2(id, 0, CHAN_BODY, CVAR[MINED_SAMPLE]);
			}
			
			NOTIFY(client_print_color, pActivator, print_team_blue, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_MINED_SUCCESS")
			
			rg_add_account(pActivator, -CVAR[COST]);
			eCorpseStruct[pActivator][MINES_COUNT]++;
			ResetRestrictions(id, pActivator);
			
			// Set pMinedOwner
			set_entvar(id, var_euser2, pActivator);
		}
		else
		{
			new pOwner = get_entvar(id, var_owner), pMiner = get_entvar(id, var_euser2);
			new TeamName:iTeam = get_entvar(id, var_team);
			
			if (pMiner > 0)
			{
				new Float:vecSrc[3];
				get_entvar(id, var_origin, vecSrc);
				
			#if REAPI_VERSION >= 5200231
				if (CVAR[GIBS])
					rg_spawn_random_gibs(id, 5);
			#endif
				
				// Делаем взрыв
				UTIL_MakeExplosionEffects(vecSrc);
				
				// player not connected fix
				if (!is_user_connected(pMiner) || (1 << _:get_member(pMiner, m_iTeam) & ((1 << _:TEAM_UNASSIGNED) | (1 << _:TEAM_SPECTATOR) | (1 << _:iTeam))))
				{
					pMiner = 0;
				}
				
				for (new i = 1, Float:fReduceDamage, Float:vecEnd[3]; i <= MaxClients; i++)
				{
					if (!is_user_alive(i))
						continue;
					
					if (get_member(i, m_iTeam) != iTeam)
						continue;
					
					get_entvar(i, var_origin, vecEnd);
					if ((fReduceDamage = (CVAR[DAMAGE] - vector_distance(vecSrc, vecEnd) * (CVAR[DAMAGE] / CVAR[RADIUS]))) < 1.0)
						continue;
					
					set_member(i, m_LastHitGroup, HITGROUP_GENERIC);
					if (ExecuteHamB(Ham_TakeDamage, i, id, pMiner, fReduceDamage, DMG_GRENADE | DMG_ALWAYSGIB))
					{
						set_member(i, m_flVelocityModifier, CVAR[SHOCK]);
						
						if (CVAR[SCREENPUNCH])
							set_entvar(i, var_punchangle, Float: { 42.2, 19.0, 64.4 });
					}
				}
				
				@CorpseRemove(pOwner);
				
				//if (CVAR[MINED_EXPLOSION_SAMPLE][0]) {
					//rh_emit_sound2(id, 0, CHAN_ITEM, CVAR[MINED_EXPLOSION_SAMPLE]);
				//}
				
				NOTIFY(client_print_color, 0, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_WAS_MINED", pActivator)
			}
			else
			{
				// ::GiveDefaultItems() игнорирование при SpawnEquip
				set_member(pOwner, m_bNotKilled, true);
				
				// no ScoreInfo 
				if (CVAR[NO_DEATH]) {
					set_member(pOwner, m_iDeaths, max(get_member(pOwner, m_iDeaths) - 1, 0) /* -1 fix */ );
				}
				
				rg_round_respawn(pOwner);
				
				if (CVAR[SPAWN_MODE])
				{
				#if defined UNSTUCK
					// Semiclip edition
					get_entvar(pActivator, var_origin, vecSrc);
					engfunc(EngFunc_SetOrigin, pOwner, vecSrc);
				#else
					engfunc(EngFunc_SetOrigin, pOwner, vecSrc);
				#endif
					set_entvar(pOwner, var_flags, get_entvar(pOwner, var_flags) | FL_DUCKING);
					// set_entvar(pOwner, var_button, get_entvar(pOwner, var_button) | IN_DUCK);
					set_entvar(pOwner, var_view_ofs, Float:{ 0.0, 0.0, 12.0 });
				}
				
				if (CVAR[NEW_HEALTH])
				{
					set_entvar(pOwner, var_max_health, CVAR[NEW_HEALTH]);
					set_entvar(pOwner, var_health, CVAR[NEW_HEALTH]);
				}
				
				if (CVAR[GUN][0])
					rg_give_items(pOwner, CVAR[GUN]);
				else
					rg_give_default_items(pOwner);
				
				if (CVAR[FRAGS]) {
					ExecuteHamB(Ham_AddPoints, pActivator, CVAR[FRAGS], false);
				}
				
				if (CVAR[BONUS_HEALTH]) {
					rg_add_user_health(pActivator, CVAR[BONUS_HEALTH], .obey_limit = true);
					// ExecuteHamB(Ham_TakeHealth, pActivator, CVAR[BONUS_HEALTH], DMG_GENERIC);
				}
				
				//aes_add_player_exp_f(pActivator, 1);
				//client_print_color(pActivator, print_team_default, "%L вы получили^4 1 XP", LANG_PLAYER, "RT_PREFIX");
				
				// Уведомления включены
				if (CVAR[NOTIFICATION] < 2)
				{
					if (CVAR[NOTIFICATION])
					{
						// Всем
						NOTIFY(client_print_color, 0, pActivator, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_NOTIFICATION", pActivator, pOwner)
					}
					else
					{
						// Только игроку кто воскрешал и тому кого воскресили
						NOTIFY(client_print_color, pOwner, pActivator, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_NOTIFICATION", pActivator, pOwner)
						NOTIFY(client_print_color, pActivator, print_team_default, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_NOTIFICATION", pActivator, pOwner)
					}
				}
				
				if (CVAR[REVIVE_SAMPLE][0]) {
					rh_emit_sound2(id, 0, CHAN_BODY, CVAR[REVIVE_SAMPLE]);
				}
				
				rg_add_account(pActivator, -CVAR[COST]);
				
				eCorpseStruct[pActivator][REVIVALS_COUNT]++;
			}
		}
	}
	
	set_entvar(id, var_nextthink, get_gametime() + 0.1);
}

ResetRestrictions(id = 0, pActivator)
{
	if (pActivator > 0)
	{
		eCorpseStruct[pActivator][IS_REVIVING] = false;
		
		set_entvar(pActivator, var_iuser3, get_entvar(pActivator, var_iuser3) & ~g_iPreventFlags);
		
		if (CVAR[NO_FIRE]) {
			set_member(pActivator, m_bIsDefusing, false);
		}
		
		if (CVAR[BAR]) {
			// 3rd party
			rg_send_bartime(pActivator, 0);
		}
		
		rg_reset_maxspeed(pActivator);
	}
	
	if (id > 0)
	{
		set_entvar(id, var_euser1, 0);
		set_entvar(id, var_fuser1, 0.0);
		set_entvar(id, var_nextthink, 0.0);
		
		if (CVAR[RENDER])
			UTIL_Render(id);
	}
}

UTIL_IsRestricted(pCorpse, pPlayer)
{
	// Раунд окончен
	if (get_member_game(m_bRoundTerminating))
	{
		return true;
	}
	
	// Нельзя использовать труп в повышенном движении
	if (UTIL_GetPlayerSpeed(pPlayer) > 240.0)
	{
		return true;
	}
	
	// На лестнице
	if (get_entvar(pPlayer, var_movetype) == MOVETYPE_FLY)
	{
		NOTIFY(client_print, pPlayer, print_center, "%L", LANG_PLAYER, "RT_ON_LADDER")
		return true;
	}
	
	// По уши в воде
	if (get_entvar(pPlayer, var_waterlevel) > 2)
	{
		NOTIFY(client_print, pPlayer, print_center, "%L", LANG_PLAYER, "RT_IN_WATER")
		return true;
	}
	
	// Нет доступа
	if (!access(pPlayer, g_iAccessFlags))
	{
		NOTIFY(client_print_color, pPlayer, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_ACCESS")
		return true;
	}
	
	// Бомба установленна
	if (CVAR[BOMB] && rg_is_bomb_planted())
	{
		NOTIFY(client_print_color, pPlayer, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_BOMB")
		return true;
	}
	
	// Остались 1 на 1
	if (CVAR[DUEL] && rg_is_1v1())
	{
		NOTIFY(client_print_color, pPlayer, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_1V1")
		return true;
	}
	
	// Нет денег
	if (get_member(pPlayer, m_iAccount) < CVAR[COST])
	{
		NOTIFY(client_printex, pPlayer, print_center, "#Not_Enough_Money")
		return true;
	}
	
	// Нарушена допустимая дистанция
	static Float:vecCorpseOrigin[3], Float:vecPlayerOrigin[3];
	
	get_entvar(pCorpse, var_origin, vecCorpseOrigin);
	get_entvar(pPlayer, var_origin, vecPlayerOrigin);
	
	if (vector_distance(vecCorpseOrigin, vecPlayerOrigin) > 150.0)
	{
		NOTIFY(client_print_color, pPlayer, print_team_red, "%L %L", LANG_PLAYER, "RT_PREFIX", LANG_PLAYER, "RT_DISTANCE")
		return true;
	}
	
	// Все по правилам, даю добро
	return false;
}

// Создание трупа
@CorpseSpawn()
{
/*
	if (GET_CURRENT_ROUND() < CVAR[ROUND]) {
		return PLUGIN_CONTINUE;
	}
*/
	new id
		= rg_create_entity("info_target");
	
	if (is_nullent(id)) {
		return PLUGIN_HANDLED;
	}
	
	new Float:vecOrigin[3], Float:vecAngles[3];
	for (new i; i < 3; i++)
	{
		vecOrigin[i] = float(get_msg_arg_int(2 + i)) / 128.0;
		vecAngles[i] = get_msg_arg_float(5 + i);
	}
	
	new szModel[32];
	new pPlayer = get_msg_arg_int(12);
	get_msg_arg_string(1, szModel, charsmax(szModel));
	
	set_entvar(id, var_classname, CORPSE_CLASSNAME);
	//set_entvar(id, var_movetype, MOVETYPE_TOSS);
	set_entvar(id, var_solid, SOLID_TRIGGER);
	set_entvar(id, var_angles, vecAngles);
	set_entvar(id, var_body, get_msg_arg_int(10));
#if defined SKIN
	set_entvar(id, var_skin, get_entvar(pPlayer, var_skin));
#endif
	set_entvar(id, var_framerate, 1.0);
	set_entvar(id, var_animtime, 0.0);
	set_entvar(id, var_sequence, get_msg_arg_int(9));
	set_entvar(id, var_euser1, 0); // pData activator
	set_entvar(id, var_fuser1, 0.0); // pData timing
	set_entvar(id, var_euser2, 0); // pData mined
	set_entvar(id, var_owner, pPlayer);
	set_entvar(id, var_team, get_msg_arg_int(11));
	
	engfunc(EngFunc_SetModel, id, fmt("models/player/%s/%s.mdl", szModel, szModel));
	engfunc(EngFunc_SetSize, id, g_vecCorpseMins, g_vecCorpseMaxs);
	engfunc(EngFunc_SetOrigin, id, vecOrigin);
	
	SetUse(id, "Corpse_Use");
	SetThink(id, "Corpse_Think");
	
	eCorpseStruct[pPlayer][CORPSE] = id;
	
	// hook original corpse
	return PLUGIN_HANDLED;
}

// Удаление трупа
@CorpseRemove(pOwner)
{
	new id = eCorpseStruct[pOwner][CORPSE];
	
	eCorpseStruct[pOwner][CORPSE] = 0;
	
	if (is_nullent(id)) {
		return;
	}
	
	ResetRestrictions(.pActivator = get_entvar(id, var_euser1));
	
	SetUse(id, NULL_STRING);
	SetThink(id, NULL_STRING);
	
	set_entvar(id, var_flags, FL_KILLME);
	set_entvar(id, var_nextthink, get_gametime());
}

// Регистрация кваров
@CreateCvars()
{
	bind_pcvar_string(create_cvar("rt_access", "", .description = "Флаг(и) доступа для воскрешений/минирований игроков"), CVAR[ACCESS], charsmax(CVAR[ACCESS]));
	bind_pcvar_num(create_cvar("rt_max_spawns", "3", .description = "Сколько максимально может воскреснуть игрок за раунд", .has_max = true, .max_val = 10.0), CVAR[MAX_SPAWNS]);
	bind_pcvar_num(create_cvar("rt_max_revivals", "2", .description = "Сколько максимально может воскресить союзников игрок за раунд"), CVAR[MAX_REVIVALS]);
	bind_pcvar_num(create_cvar("rt_max_mines", "2", .description = "Сколько максимально может заминировать врагов игрок за раунд"), CVAR[MAX_MINES]);
	bind_pcvar_num(create_cvar("rt_duration", "5", .description = "Длительность возрождения", .has_min = true, .min_val = 1.0, .has_max = true, .max_val = 30.0), CVAR[DURATION]);
	bind_pcvar_num(create_cvar("rt_observer", "1", .description = "Автоматически переключать мою камеру на того кто меня воскрешает"), CVAR[OBSERVER]);
	bind_pcvar_num(create_cvar("rt_hook_attack", "1", .description = "Заблокировать стрельбу во время возрождения/минирования?"), CVAR[NO_FIRE]);
	bind_pcvar_num(create_cvar("rt_render", "1", .description = "Подсвечивать труп когда его минируют/возрождают?"), CVAR[RENDER]);
	bind_pcvar_num(create_cvar("rt_progress_bar", "1", .description = "Полоска прогресса во время возрождения/минирования?"), CVAR[BAR]);
	bind_pcvar_float(create_cvar("rt_radius", "350.0", .description = "Максимальный допустимый радиус поражения", .has_min = true, .min_val = 64.0, .has_max = true, .max_val = 500.0), CVAR[RADIUS]);
	bind_pcvar_float(create_cvar("rt_damage", "250.0", .description = "Максимальный урон от взрыва (урон наносится в зависимости от радиуса)", .has_min = true, .min_val = 64.0), CVAR[DAMAGE]);
	bind_pcvar_float(create_cvar("rt_painshock", "0.15", .description = "Болевой шок после удара (сила замедления диапазон: от 0 до 1)", .has_min = true, .has_max = true, .max_val = 1.0), CVAR[SHOCK]);
	bind_pcvar_num(create_cvar("rt_screen_punch", "1", .description = "Трясти экран от полученного урона (взрывной волны)"), CVAR[SCREENPUNCH]);
	bind_pcvar_num(create_cvar("rt_spawn_place", "1", .description = "Спавнить воскрешенного игрока на месте смерти (в противном случае будет на базе)"), CVAR[SPAWN_MODE]);
#if REAPI_VERSION >= 5200231
	bind_pcvar_num(create_cvar("rt_gibs", "1", .description = "Спавнить ошметки после взрыва заминированного трупа?"), CVAR[GIBS]);
#endif
	bind_pcvar_string(create_cvar("rt_weapons", "knife deagle", .description = "Оружия вновь воскрешенного игрока (пустое значение будет использовать оружия из game.cfg)"), CVAR[GUN], charsmax(CVAR[GUN]));
	bind_pcvar_float(create_cvar("rt_health", "0.0", .description = "Здоровье воскрешенного игрока (0 - будет как обычно)", .has_max = true, .max_val = 255.0), CVAR[NEW_HEALTH]);
	bind_pcvar_float(create_cvar("rt_bonus_health", "10.0", .description = "Сколько добавить здоровья игроку за воскрешение", .has_max = true, .max_val = 100.0), CVAR[BONUS_HEALTH]);
	bind_pcvar_num(create_cvar("rt_frags", "1", .description = "Сколько давать фрагов за возрождение?"), CVAR[FRAGS]);
	bind_pcvar_num(create_cvar("rt_restore_death", "1", .description = "Обнулить очко смерти игроку которое он получил при смерти"), CVAR[NO_DEATH]);
	bind_pcvar_num(create_cvar("rt_cost", "0", .description = "Стоимость услуги (используйте отрицательное значение и тогда будет в + как награда)"), CVAR[COST]);
	bind_pcvar_num(create_cvar("rt_bomb", "0", .description = "Нельзя воскрешать когда бомба установленна"), CVAR[BOMB]);
	bind_pcvar_num(create_cvar("rt_1v1", "0", .description = "Нельзя воскрешать когда 1 на 1"), CVAR[DUEL]);
	bind_pcvar_num(create_cvar("rt_vip", "0", .description = "Может ли VIP игрок воскрешать (as_* карты)"), CVAR[VIP]);
	bind_pcvar_num(create_cvar("rt_round", "0", .description = "С какого раунда доступно возрождение"), CVAR[ROUND]);
	bind_pcvar_num(create_cvar("rt_domination", "0", .description = "Если команда доминирует над другой (побед подряд) запретить ей воскрешать/минировать?"), CVAR[DOMINATION]);
	bind_pcvar_float(create_cvar("rt_time_expired", "10.0", .description = "Возможность воскрешать/минировать только после Х сек. от начала раунда", .has_max = true, .max_val = 60.0), CVAR[TIME_EXPIRED]);
	bind_pcvar_num(create_cvar("rt_sound_notification", "1", .description = "Проигрывать звук к запрещаюшим уведомлениям"), CVAR[SOUND_NOTIFICATION]);
	bind_pcvar_num(create_cvar("rt_dont_motion", "1", .description = "Заблокировать движение во время воскрешения/минирования"), CVAR[DONT_MOTION]);
	bind_pcvar_num(create_cvar("rt_can_mined", "1", .description = "Возможно ли минировать врагов [1 - да, 0 - только воскрешение тиммейтов]"), CVAR[CAN_MINED]);
	bind_pcvar_num(create_cvar("rt_notification", "1", .description = "Метод уведомлений при воскрешении^n2 - отключить^n1 - всем^n0 - только тому кто поднимал и тому кто поднял", .has_min = true), CVAR[NOTIFICATION]);	
	bind_pcvar_string(create_cvar("rt_revive_sample", "", .description = "Звук воскрешения трупа (опционально)"), CVAR[REVIVE_SAMPLE], charsmax(CVAR[REVIVE_SAMPLE]));
	bind_pcvar_string(create_cvar("rt_mined_sample", "weapons/c4_disarm.wav", .description = "Звук когда труп заминировали (опционально)"), CVAR[MINED_SAMPLE], charsmax(CVAR[MINED_SAMPLE]));
	bind_pcvar_string(create_cvar("rt_explode_sample", "", .description = "Звук взрыва от заминированного трупа (опционально)"), CVAR[EXPLODE_SAMPLE], charsmax(CVAR[EXPLODE_SAMPLE]));
	bind_pcvar_string(create_cvar("rt_size", "-36.0 -36.0 -36.0 36.0 36.0 36.0", .description = "Минимальный и максимальный размер объекта"), CVAR[SIZE], charsmax(CVAR[SIZE]));
	
	if (CVAR[REVIVE_SAMPLE][0]) {
		precache_sound(CVAR[REVIVE_SAMPLE]);
	}
	
	if (CVAR[MINED_SAMPLE][0]) {
		precache_sound(CVAR[MINED_SAMPLE]);
	}
	
	if (CVAR[EXPLODE_SAMPLE][0]) {
		precache_sound(CVAR[EXPLODE_SAMPLE]);
	}
	
	new szSize[6][8];
	if (parse(CVAR[SIZE], szSize[0], 7, szSize[1], 7, szSize[2], 7, szSize[3], 7, szSize[4], 7, szSize[5], 7) != 6)
	{
		// Установим размеры по умолчанию
		@defsize:
		g_vecCorpseMins[0] = g_vecCorpseMins[1] = g_vecCorpseMins[2] = -24.0;
		g_vecCorpseMaxs[0] = g_vecCorpseMaxs[1] = g_vecCorpseMaxs[2] = 24.0;
		
		// server_print("[%s] Установленны размеры трупа по умолчанию", PLUGIN);
	}
	else
	{
		// Установим размеры согласно квару
		for (new i; i < 3; i++)
		{
			if ((g_vecCorpseMins[i] = str_to_float(szSize[i])) > 0.0
			|| (g_vecCorpseMaxs[i] = str_to_float(szSize[3 + i])) < 0.0)
				goto @defsize
		}
	}
	
	// Флаги доступа
	g_iAccessFlags = read_flags(CVAR[ACCESS]);
	
	// Флаги движения
	g_iPreventFlags = (1 << 5); // def
	if (CVAR[DONT_MOTION])
		g_iPreventFlags |= (1 << 6);
	
	// configs/plugins/ReviveTeammates.cfg
	AutoExecConfig(.name = "ReviveTeammates");
}

// Взрыв
stock UTIL_MakeExplosionEffects(const Float:vecOrigin[3])
{
	new bIsCustomExplosive = CVAR[EXPLODE_SAMPLE][0] != EOS;
	
	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_EXPLOSION); // This makes a dynamic light and the explosion sprites/sound
	write_coord_f(vecOrigin[0]); // Send to PAS because of the sound
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] + 20.0);
	write_short(g_sModelIndexFireball3);
	write_byte(25); // scale * 10
	write_byte(30); // framerate
	write_byte(bIsCustomExplosive ? TE_EXPLFLAG_NOSOUND : TE_EXPLFLAG_NONE); // flags
	message_end();

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_EXPLOSION); // This makes a dynamic light and the explosion sprites/sound
	write_coord_f(vecOrigin[0] + random_float(-64.0, 64.0)); // Send to PAS because of the sound
	write_coord_f(vecOrigin[1] + random_float(-64.0, 64.0));
	write_coord_f(vecOrigin[2] + random_float(30.0, 35.0));
	write_short(g_sModelIndexFireball2);
	write_byte(30); // scale * 10
	write_byte(30); // framerate
	write_byte(bIsCustomExplosive ? TE_EXPLFLAG_NOSOUND : TE_EXPLFLAG_NONE); // flags
	message_end();

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_SPRITE);
	write_coord_f(vecOrigin[0] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[1] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[2] + random_float(-10.0, 10.0));
	write_short(g_sModelIndexFireball2);
	write_byte(30);
	write_byte(150);
	message_end();
	
	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_SPRITE);
	write_coord_f(vecOrigin[0] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[1] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[2] + random_float(-10.0, 10.0));
	write_short(g_sModelIndexFireball2);
	write_byte(30);
	write_byte(150);
	message_end();

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_SPRITE);
	write_coord_f(vecOrigin[0] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[1] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[2] + random_float(-10.0, 10.0));
	write_short(g_sModelIndexFireball3);
	write_byte(30);
	write_byte(150);
	message_end();

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_SPRITE);
	write_coord_f(vecOrigin[0] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[1] + random_float(-256.0, 256.0));
	write_coord_f(vecOrigin[2] + random_float(-10.0, 10.0));
	write_short(g_sModelIndexFireball);
	write_byte(30);
	write_byte(17);
	message_end();
	
	if (bIsCustomExplosive) {
		rh_emit_sound2(0, 0, CHAN_AUTO, CVAR[EXPLODE_SAMPLE], .origin = vecOrigin);
	}
}

stock Float:UTIL_GetPlayerSpeed(const id)
{
	new Float:vecVelocity[3];
	get_entvar(id, var_velocity, vecVelocity);
	// vecVelocity[2] *= 0.5;
	
	return vector_length(vecVelocity);
}

stock UTIL_Render(const id, const fx = kRenderFxNone, const mode = kRenderNormal, const Float:flColor[] = NULL_VECTOR, const Float:fAmount = 0.0)
{
	set_entvar(id, var_renderfx, fx);
	set_entvar(id, var_rendermode, mode);
	set_entvar(id, var_rendercolor, flColor);
	set_entvar(id, var_renderamt, fAmount);
}

