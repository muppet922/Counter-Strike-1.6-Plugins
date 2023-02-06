//	Copyright © 2016 Vaqtincha
/***************************
*	Support forum:
*		http://goldsrc.ru
*
****************************/

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG START ■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

// #define EXCLUDE_FLAG 			ADMIN_LEVEL_H
#define TOP_PLAYERS 				10 				// top 10 players menu

// #define MULTIPLICATION_MONEY		2
#define ROUND_NUMBER 				1
#define MIN_PLAYERS 				4

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG END ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#define PL_VERSION "0.0.3"

#include <amxmodx>
#include <reapi>

#if AMXX_VERSION_NUM < 183
	#include <colorchat>
#endif

#define IsPlayer(%1)					(1 <= %1 <= g_iMaxPlayers)
#define ClearArray(%1)					arrayset(_:%1, _:0.0, sizeof(%1))

#if defined TOP_PLAYERS
	new g_iTopPlayersMenu
	const MENU_KEYS = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0
#endif
const TASK_ID_GIVEBONUS = 155261

enum player_e
{ 
	PlayerID, 
	Float:Damage
}

new g_ePlayerData[MAX_CLIENTS /* + 1 */][player_e], Float:g_flPlayerDamage[MAX_CLIENTS + 1]
new g_iMaxPlayers, g_iRoundCounter, mp_maxmoney


public plugin_init()
{
	register_plugin("Best Damage Bonus", PL_VERSION, "Vaqtincha")
	register_event("TextMsg", "Event_NewGame", "a", "2=#Game_will_restart_in", "2=#Game_Commencing")

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage", .post = true)
	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound", .post = true)

	mp_maxmoney = get_cvar_pointer("mp_maxmoney")
	g_iMaxPlayers = get_maxplayers()

#if defined TOP_PLAYERS
	g_iTopPlayersMenu = register_menuid("TopPlayers")
	register_clcmd("say /dmg", "ClCmd_TopPlayers")
	register_menucmd(g_iTopPlayersMenu, MENU_KEYS, "MenuHandler")
#endif
}

public client_putinserver(pPlayer)
{
	g_flPlayerDamage[pPlayer] = 0.0
}

public Event_NewGame()
{
	g_iRoundCounter = 0
	remove_task(TASK_ID_GIVEBONUS)
	ClearArray(g_flPlayerDamage)
}

public CSGameRules_RestartRound()
{
	g_iRoundCounter++
	if(g_iRoundCounter >= ROUND_NUMBER)
		set_task(0.1, "GetBestPlayer", TASK_ID_GIVEBONUS) // delay before giving
}

public GetBestPlayer()
{
	new pPlayer
	if((pPlayer = ComparePlayersDamage()) && is_user_connected(pPlayer))
	{
		new iBonus = GivePlayerBonus(pPlayer)
		if(iBonus)
			client_print_color(pPlayer, print_team_grey, "^1* ^3Вы нанесли ^4%0.1f ^3урона и получили бонус^1: ^4%d^1$", g_flPlayerDamage[pPlayer], iBonus)	
		else
			client_print_color(pPlayer, print_team_grey, "^1* ^3Вы нанесли ^4%0.1f ^3урона и оказались лучшим игроком раунда", g_flPlayerDamage[pPlayer])

		PrintChatAll(pPlayer, g_flPlayerDamage[pPlayer], iBonus)
	}
}

public CBasePlayer_TakeDamage(const pPlayer, pevInflictor, const pevAttacker, Float:flDamage, bitsDamageType)
{
	if(g_iRoundCounter < ROUND_NUMBER || pPlayer == pevAttacker || bitsDamageType & DMG_BLAST)
		return HC_CONTINUE

	if(IsPlayer(pevAttacker) && rg_is_player_can_takedamage(pPlayer, pevAttacker))
		g_flPlayerDamage[pevAttacker] += flDamage

	return HC_CONTINUE
}

public SortArrayCallBack(const iElem1[], const iElem2[])
{
	return (iElem1[1] < iElem2[1]) ? 1 : (iElem1[1] > iElem2[1]) ? -1 : 0
}

#if defined TOP_PLAYERS
public MenuHandler(const pPlayer, const iKey) 
{
	return PLUGIN_HANDLED
}

public ClCmd_TopPlayers(const pPlayer)
{
	if(!is_user_connected(pPlayer) || !ComparePlayersDamage())
		return PLUGIN_HANDLED

	new szMenu[512], szName[32], iLen, i
	iLen = formatex(szMenu, charsmax(szMenu), "\yTop \r%d \yPlayers:^n^n", TOP_PLAYERS)

	for(i = 0; i < TOP_PLAYERS; i++)
	{
		if(g_ePlayerData[i][Damage] <= 0.0)
			continue

		get_user_name(g_ePlayerData[i][PlayerID], szName, charsmax(szName))
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%d\w. %s%s\R\y%0.1f^n",
			i + 1, g_ePlayerData[i][PlayerID] == pPlayer ? "\r":"\w", szName, g_ePlayerData[i][Damage])
	}

	return show_menu(pPlayer, MENU_KEYS, szMenu, -1, "TopPlayers")
}

CloseOpenedMenu(const pPlayer) 
{
	new iMenuId, iKeys
	get_user_menu(pPlayer, iMenuId, iKeys)
	if(iMenuId == g_iTopPlayersMenu && (iKeys & MENU_KEYS) == MENU_KEYS)
	{
		menu_cancel(pPlayer)
		show_menu(pPlayer, 0, "^n", 1)
	}
}
#endif

GivePlayerBonus(const pPlayer)
{
#if defined EXCLUDE_FLAG
	if(get_user_flags(pPlayer) & EXCLUDE_FLAG)
		return 0
#endif
	if(get_member(pPlayer, m_iAccount) >= get_pcvar_num(mp_maxmoney))
		return 0
#if defined	MULTIPLICATION_MONEY
	new iBonus = floatround(g_flPlayerDamage[pPlayer]) * MULTIPLICATION_MONEY
#else
	new iBonus = floatround(g_flPlayerDamage[pPlayer])
#endif
	rg_add_account(pPlayer, iBonus)

	return iBonus
}

ComparePlayersDamage()
{
	new iPlayers[32], iCount, pPlayer
	get_players(iPlayers, iCount, "h")

	if(iCount <= 1 || iCount < MIN_PLAYERS)
		return 0

	for(--iCount; iCount >= 0; iCount--)
	{
		pPlayer = iPlayers[iCount]
		g_ePlayerData[iCount][PlayerID] = pPlayer
		g_ePlayerData[iCount][Damage] = _:g_flPlayerDamage[pPlayer]
	#if defined TOP_PLAYERS
		CloseOpenedMenu(pPlayer)
	#endif
	}

	SortCustom2D(g_ePlayerData, sizeof(g_ePlayerData), "SortArrayCallBack")
	new pBestPlayer = g_ePlayerData[0][PlayerID]

	return (g_flPlayerDamage[pBestPlayer] <= 0.0) ? 0 : pBestPlayer
}

PrintChatAll(const pBestPlayer, const Float:flBestDamage, const iBonus)
{
	new iPlayers[32], szName[32], iCount, pReceiver
	new iTeamColor = get_member(pBestPlayer, m_iTeam) == TEAM_TERRORIST ? print_team_red : print_team_blue

	get_players(iPlayers, iCount, "ch")
	get_user_name(pBestPlayer, szName, charsmax(szName))

	for(--iCount; iCount >= 0; iCount--)
    {
		pReceiver = iPlayers[iCount]
		if(pBestPlayer == pReceiver)
			continue

		if(iBonus) 
		{
			client_print_color(pReceiver, iTeamColor, "^4* ^1Лучший игрок раунда: ^3%s ^1нанес: ^4%0.1f ^1урона и получил ^4%d^1$, ^1Вы нанесли: ^4%0.1f",
				szName, flBestDamage, iBonus, g_flPlayerDamage[pReceiver])
		}
		else
		{
			client_print_color(pReceiver, iTeamColor, "^4* ^1Лучший игрок раунда: ^3%s ^1нанес: ^4%0.1f ^1урона, Вы нанесли: ^4%0.1f",
				szName, flBestDamage, g_flPlayerDamage[pReceiver])
		}
	}

	ClearArray(g_flPlayerDamage)
}



