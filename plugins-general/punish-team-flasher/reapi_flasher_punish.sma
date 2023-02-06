// Copyright © 2016 Vaqtincha

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG START ■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/
/// main:
#define PUNISH_BEGIN 			3				// fails			
// #define IMMUNITY_FLAG 		ADMIN_IMMUNITY		
// #define RESET_IN_RESTART
#define TEMP_SAVE_DATA							// reconnect protection


/// penalty's:
#define RESTRICT_FLASHBANG 				30		// restrict time (sec)
#define NO_MONEY_NEXT_ROUND						// NoReceiveMoneyNextRound
// #define MONEY_PENALTY			100			//
// #define SLAP_FLASHER				5			// set slap power
// #define STRIP_WEAPONS						// remove all items
// #define MIROR_BLIND							//

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG END ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#define PL_VERSION  			"0.0.2b"
// #define DEBUG					// test

#include <amxmodx>

#if AMXX_VERSION_NUM < 183 
	#include <colorchat>
#endif

#include <reapi>


#define rg_set_account 		rg_add_account
#define MAX_NAME_LEN  		32
#define MAX_AUTHID_LEN  	32

#define FFADE_IN			0x0000
#define sec_to_scrfade_units(%1) 		clamp((floatround(%1))<<12, 0, 0xFFFF)

new g_szPlayerName[MAX_CLIENTS+1][MAX_NAME_LEN]
new g_iFails[MAX_CLIENTS+1]
#if defined RESTRICT_FLASHBANG
new Float:g_flLastBlind[MAX_CLIENTS+1]
#endif

#if defined TEMP_SAVE_DATA
new g_szAuthid[MAX_CLIENTS+1][MAX_AUTHID_LEN]
new Trie:g_tPlayerData

public plugin_end()
{
	TrieDestroy(g_tPlayerData)
}

public client_disconnected(pPlayer)
{
	if(g_szAuthid[pPlayer][0] && g_iFails[pPlayer])
		TrieSetCell(g_tPlayerData, g_szAuthid[pPlayer], g_iFails[pPlayer])
}
#endif

public plugin_init()
{
	register_plugin("[ReAPI] Flasher Punish", PL_VERSION, "Vaqtincha")

	RegisterHookChain(RG_PlayerBlind, "PlayerBlind", .post = false)
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "CBasePlayer_SetUserInfoName", .post = true)

#if defined RESTRICT_FLASHBANG
	RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem", .post = false)
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "CBasePlayer_AddPlayerItem", .post = false)
#endif
#if defined DEBUG
	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", .post = true)
#endif
#if defined TEMP_SAVE_DATA
	g_tPlayerData = TrieCreate()
#endif
#if defined RESET_IN_RESTART
	register_event("TextMsg", "Event_NewGame", "a", "2=#Game_will_restart_in", "2=#Game_Commencing")
}

public Event_NewGame()
{
	arrayset(g_iFails, 0, sizeof(g_iFails))
	#if defined RESTRICT_FLASHBANG
	// arrayset(g_flLastBlind, 0.0, sizeof(g_flLastBlind))
	#endif
#endif
}

#if defined DEBUG
public CBasePlayer_Spawn(const pPlayer)
{
	if(is_user_alive(pPlayer))
	{
		rg_give_item(pPlayer, "weapon_flashbang")
		rg_give_item(pPlayer, "weapon_flashbang")
	}

	return HC_CONTINUE
}
#endif

public client_putinserver(pPlayer)
{
	get_user_name(pPlayer, g_szPlayerName[pPlayer], MAX_NAME_LEN -1)

#if defined TEMP_SAVE_DATA
	get_user_authid(pPlayer, g_szAuthid[pPlayer], MAX_AUTHID_LEN -1)
	if(g_szAuthid[pPlayer][0] == 'S' && TrieGetCell(g_tPlayerData, g_szAuthid[pPlayer], g_iFails[pPlayer])) 
	{
	#if defined RESTRICT_FLASHBANG
		g_flLastBlind[pPlayer] = get_gametime() + RESTRICT_FLASHBANG.0
	#endif
	}
	else{
		g_iFails[pPlayer] = 0
		g_szAuthid[pPlayer][0] = 0
	#if defined RESTRICT_FLASHBANG
		g_flLastBlind[pPlayer] = 0.0
	#endif
	}
#else
	g_iFails[pPlayer] = 0
#endif
}


/// MAIN
public PlayerBlind(const pPlayer, const inflictor, const pAttacker, const Float:fadeTime, const Float:fadeHold, const alpha, Float:color[3])
{
	if(pPlayer == pAttacker)
		return HC_CONTINUE

	if(get_member(pPlayer, m_iTeam) == get_member(pAttacker, m_iTeam))
	{
		client_print_color(pPlayer, print_team_default, "^4* ^1Вас ослепил ^3%s", g_szPlayerName[pAttacker])

#if defined IMMUNITY_FLAG
		if(get_user_flags(pAttacker) & IMMUNITY_FLAG)
			return HC_CONTINUE
#endif
		g_iFails[pAttacker]++
		client_print_color(pAttacker, print_team_default, "^4* ^1Вы ослепили тиммейта ^3%s ^1всего: ^4%d ^1раз(a)", g_szPlayerName[pPlayer], g_iFails[pAttacker])

		if(g_iFails[pAttacker] < PUNISH_BEGIN)
			return HC_CONTINUE

	#if defined RESTRICT_FLASHBANG
		g_flLastBlind[pAttacker] = get_gametime() + RESTRICT_FLASHBANG.0
	#endif
	#if defined NO_MONEY_NEXT_ROUND
		set_member(pAttacker, m_bReceivesNoMoneyNextRound, true)
	#endif
	#if defined STRIP_WEAPONS	
		rg_remove_all_items(pAttacker)
	#endif
	#if defined MONEY_PENALTY
		rg_set_account(pAttacker, max(get_member(pAttacker, m_iAccount) - MONEY_PENALTY, 0), .typeSet = AS_SET)
	#endif
	#if defined SLAP_FLASHER
		user_slap(pAttacker, SLAP_FLASHER)
	#endif
	#if defined MIROR_BLIND
		ScreenFade(pAttacker, fadeTime, fadeHold, alpha)
	#endif
		// return HC_SUPERCEDE // block flash (aka noteamflash)
	}

	return HC_CONTINUE
}

public CBasePlayer_SetUserInfoName(const pPlayer, infobuffer[], szNewName[])
{
	if(!equal(g_szPlayerName[pPlayer], szNewName))
		copy(g_szPlayerName[pPlayer], MAX_NAME_LEN -1, szNewName)
}

///
#if defined RESTRICT_FLASHBANG
public CBasePlayer_AddPlayerItem(const pPlayer, const pItem)
{
	if(g_iFails[pPlayer] < PUNISH_BEGIN || get_member(pItem, m_iId) != WEAPON_FLASHBANG)
		return HC_CONTINUE

	if(g_flLastBlind[pPlayer] <= get_gametime())
		return HC_CONTINUE
	
	SetHookChainReturn(ATYPE_INTEGER, false)
	return HC_SUPERCEDE
}

public CBasePlayer_HasRestrictItem(const pPlayer, const ItemID:item, const ItemRestType:type)
{
	if(g_iFails[pPlayer] < PUNISH_BEGIN || item != ITEM_FLASHBANG)
		return HC_CONTINUE

	static Float:flCurTime; flCurTime = get_gametime()
	if(g_flLastBlind[pPlayer] <= flCurTime)
		return HC_CONTINUE
	
	if(type == ITEM_TYPE_BUYING)
		client_print(pPlayer, print_center, "Вы не можете купить данный предмет ^rв течении %0.f сек", (g_flLastBlind[pPlayer] - flCurTime))

	SetHookChainReturn(ATYPE_INTEGER, true)
	return HC_SUPERCEDE
}
#endif



stock ScreenFade(const pPlayer, const Float:flFxTime, const Float:flHoldTime, const iAlpha)
{
	static iMsgIdScreenFade
	if(!iMsgIdScreenFade)
		iMsgIdScreenFade = get_user_msgid("ScreenFade")

	if(is_user_alive(pPlayer)) 	// send only alive player
	{
		message_begin(MSG_ONE, iMsgIdScreenFade, .player = pPlayer)
		write_short(sec_to_scrfade_units(flFxTime))
		write_short(sec_to_scrfade_units(flHoldTime))
		write_short(FFADE_IN)
		write_byte(255) // red
		write_byte(255) // green
		write_byte(255) // blue
		write_byte(iAlpha)
		message_end()
	}
}




