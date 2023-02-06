#include <amxmodx>
#include <biohazard>
#include <cstrike>

new g_LastAnnounce
new g_center1_sync
new g_bottom_sync

new g_LastMessages[4][] =
{
	"Well...now everything depends on you.", 
	"I hope you know what are you doing, since you are the last one of your kind.", 
	"All your teammates are dead, try not to dissapoint them.", 
	"Well...now you are fucked, shall we wish you GOOD LUCK?!"
}

new g_teamsNames[4][] =
{
	"ZOMBIE", 
	"HUMAN", 
	"ZOMBIES", 
	"HUMANS"
}

new cvar_enemy_remaining, cvar_last_man, maxplayers;

public plugin_init()
{
	register_plugin("[Biohazard] Misc. Stats", AMXX_VERSION_STR, "TEST")

	register_event("SendAudio", "eEndRound", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin", "2&%!MRAD_rounddraw")

	cvar_enemy_remaining = register_cvar("bio_enemy_remaining", "1");	// 1 / 0
	cvar_last_man = register_cvar("bio_last_man", "1");	// 1 / 0
	
	g_center1_sync = CreateHudSyncObj()
	g_bottom_sync = CreateHudSyncObj()

	maxplayers = get_maxplayers()
}

public event_infect(victim, attacker)
{
	if (get_pcvar_num(cvar_enemy_remaining) && is_user_connected(victim) && is_user_connected(attacker))
	{
		if (fnGetZombies() > 1 && fnGetHumans() != 0)
		{
			set_hudmessage(255, 255, 255, 0.72, 0.88, 2, 0.05, 0.1, 0.02, 3.0, -1)
			
			new id
			for (id = 0; id < fnGetHumans(); ++id)
			{
				ShowSyncHudMsg(id, g_bottom_sync, "%d HUMAN%s Remaining...", fnGetHumans(), fnGetHumans() == 1 ? "" : "S")
			}
		}
	}
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if (get_pcvar_num(cvar_enemy_remaining) && is_user_connected(victim))
	{
		if (fnGetZombies() > 1 && fnGetHumans() != 0)
		{
			set_hudmessage(255, 255, 255, 0.72, 0.88, 2, 0.05, 0.1, 0.02, 3.0, -1)
			
			new id
			for (id = 0; id < fnGetZombies() + fnGetHumans(); ++id)
			{
				if(is_user_zombie(id)) ShowSyncHudMsg(id, g_bottom_sync, "%d HUMAN%s Remaining...", fnGetHumans(), fnGetHumans() == 1 ? "" : "S")
				else ShowSyncHudMsg(id, g_bottom_sync, "%d ZOMBIE%s Remaining...", fnGetZombies(), fnGetZombies() == 1 ? "" : "S")
			}
		}
	}

	if (get_pcvar_num(cvar_last_man))
	{
		new cts[32], ts[32], ctsnum, tsnum
		new maxplayers = get_maxplayers()
		new CsTeams:team
		
		for (new i=1; i<=maxplayers; i++)
		{
			if (!is_user_connected(i) || !is_user_alive(i))
			{
				continue
			}
			team = cs_get_user_team(i)
			if (team == CS_TEAM_T)
			{
				ts[tsnum++] = i
			} else if (team == CS_TEAM_CT) {
				cts[ctsnum++] = i
			}
		}
		
		if (ctsnum == 1 && tsnum == 1)
		{
			new ctname[32], tname[32]
			
			get_user_name(cts[0], ctname, 31)
			get_user_name(ts[0], tname, 31)
			
			set_hudmessage(0, 255, 255, -1.0, 0.29, 0, 6.0, 6.0, 0.5, 0.15, -1)
			ShowSyncHudMsg(0, g_center1_sync, "%s vs. %s", ctname, tname)
			
			play_sound("misc/maytheforce")
		}
		else if (!g_LastAnnounce)
		{
			new oposite = 0, _team = 0
			
			if (ctsnum == 1 && tsnum > 1)
			{
				g_LastAnnounce = cts[0]
				oposite = tsnum
				_team = 0
			}
			else if (tsnum == 1 && ctsnum > 1)
			{
				g_LastAnnounce = ts[0]
				oposite = ctsnum
				_team = 1
			}

			if (g_LastAnnounce)
			{
				new name[32]
				get_user_name(g_LastAnnounce, name, 31)
				
				set_hudmessage(0, 255, 255, -1.0, 0.29, 0, 6.0, 6.0, 0.5, 0.15, -1)
				ShowSyncHudMsg(0, g_center1_sync, "%s (%d HP) vs. %d %s%s: %s", name, get_user_health(g_LastAnnounce), oposite, g_teamsNames[_team], (oposite == 1) ? "" : "S", g_LastMessages[random_num(0, 3)])
				
				if (!is_user_connecting(g_LastAnnounce))
				{
					client_cmd(g_LastAnnounce, "spk misc/oneandonly")
				}
			}
		}
	}
}

public eEndRound()
{
	g_LastAnnounce = 0
}

public play_sound(sound[])
{
	new players[32], pnum
	get_players(players, pnum, "c")
	new i
	
	for (i = 0; i < pnum; i++)
	{
		if (is_user_connecting(players[i]))
			continue
		
		client_cmd(players[i], "spk %s", sound)
	}
}

stock fnGetHumans()
{
	new humans, id;
	
	for(id = 1; id <= maxplayers; id++)
	{
		if(is_user_alive(id) && !is_user_zombie(id))
			humans++;
	}
	
	return humans;
}

stock fnGetZombies()
{
	new zombies, id;
	
	for(id = 1; id <= maxplayers; id++)
	{
		if(is_user_alive(id) && is_user_zombie(id))
			zombies++;
	}
	
	return zombies;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1048\\ f0\\ fs16 \n\\ par }
*/
