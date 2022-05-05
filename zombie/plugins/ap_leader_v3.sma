#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <zombie_plague_special>

#define TASK_ID_CHECKFORMAPEND 241
#define TASK_ID_DELAYMAPCHANGE 242

new g_IsLastRound = 0
new g_OldTimelimit = 0

new cvar_bonus, cvar_apamount
new iMaxPlayers

public plugin_init()
{
	register_plugin("[ZP] Addon: Frag Leader", "1.0.2" ,"EKS + Kis2e")

	register_event("SendAudio","Event_EndRound","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")
	set_task(15.0,"Task_MapEnd",TASK_ID_CHECKFORMAPEND,_,_,"d",1)

	cvar_bonus = register_cvar("zp_leader_bonus", "1") // Enable the bonus for the frag leader
	cvar_apamount = register_cvar("zp_ap_amount", "150") // Amount of AP given to the frag leader

	iMaxPlayers = get_maxplayers()
}

public Task_MapEnd()
{
	if(get_playersnum())
	{
		g_IsLastRound = 1
		g_OldTimelimit = get_cvar_num("mp_timelimit")

		server_cmd("mp_timelimit 0")
		client_print(0, print_chat, "Timelimit has expired, map change will happen after this round")
	}
}

public Event_EndRound()
{
	if(g_IsLastRound == 1)
	{
		client_print(0, print_chat,"Round is over, changing map in 5 seconds!")
		set_task(5.0, "Task_DelayMapEnd", TASK_ID_DELAYMAPCHANGE, _, _, "a", 1)

		set_task(0.1, "iLeader")
	}
}

public server_changelevel(map[])
{
	if(g_IsLastRound == 1)
		Task_DelayMapEnd()
}

public Task_DelayMapEnd()
{
	remove_task(TASK_ID_DELAYMAPCHANGE)
	g_IsLastRound = 0
	if(get_cvar_num("mp_timelimit") == 0)
		server_cmd("mp_timelimit %d",g_OldTimelimit)
}

public iLeader()
{
	new iFrags
	new iLeader = GetLeader_Frags(iFrags)
	new Players = UsersGetPlaying()
	new iPlayers[32], iNum, Others
	new szName[32]
	get_user_name( iLeader, szName, 31 )
	get_players( iPlayers, iNum, "ch" )

	for ( new i = 0; i < iNum; i++ )
		Others = get_user_frags(i)

	if ( Players == 0 )
		return;

	else if ( iFrags == Others )
		return;

	else

	set_hudmessage(random_num(10,255), random(256), random(256), -1.0, 0.20, 0, 6.0, 12.0, 0.0, 0.0, -1)
	show_hudmessage(0, "The frags leader is %s with %d Frags", szName, iFrags )

	if ( get_pcvar_num(cvar_bonus) )
	{
		zp_set_user_ammo_packs(iLeader, zp_get_user_ammo_packs(iLeader) + get_pcvar_num(cvar_apamount))
		client_print(iLeader, print_chat, "[ZP] %s, you have recieved %d AP bonus as the frags leader", szName, get_pcvar_num(cvar_apamount))
	}
}

GetLeader_Frags( &iFrags )
{
    new iPlayers[32], iNum, id, i, iLeader, iFrag
    get_players( iPlayers, iNum, "ch" )

    for ( i = 0; i < iNum; i++ )
    {
        id = iPlayers[i]
        iFrag = get_user_frags(id)

        if ( iFrag > iFrags )
        {
            iFrags = iFrag
            iLeader = id
        }
    }
    return iLeader;
}

UsersGetPlaying()
{
    static iPlaying, id
    iPlaying = 0

    for ( id = 1; id <= iMaxPlayers; id++ )
    {
        if ( is_user_connected(id) )
        {
            if ( get_user_team(id) == 1 || get_user_team(id) == 2 )
                iPlaying++
        }
    }

    return iPlaying;
}
