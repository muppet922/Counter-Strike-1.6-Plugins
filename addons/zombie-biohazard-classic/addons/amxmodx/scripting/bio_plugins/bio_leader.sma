/*
* CREDITS:
* - tuty			*for Trail Player
*/

#include <amxmodx> 
#include <fun>
#include <fakemeta>
#include <biohazard>

#define TASK_AURA 1292

enum attributes
{
	GLOW = 0,
	TRAIL,
	AURA
};
new cvar[attributes];
new trail_randomcolor[3], trail[33], Float:bflNextCheck[33];
new leader = -1, last_leader = -1, g_rounds = 0, trail_sprite;

new const g_trail_sprite[] = "sprites/zbeam2.spr";
const IN_MOVING = IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP;

public plugin_init()
{
	register_plugin("[Biohazard] Leader", "1.0", "TEST");

	register_logevent("le_RoundStart", 2, "1=Round_Start");
	register_logevent("le_RoundRestart", 2, "1&Restart_Round_");
	register_logevent("le_RoundRestart", 2, "1=Game_Commencing");

	register_event("DeathMsg", "event_DeathMsg", "a");

	register_forward(FM_CmdStart, "fw_CmdStart");

	cvar[GLOW] = register_cvar("bio_leader_glow", "1");
	cvar[TRAIL] = register_cvar("bio_leader_trail", "0");
	cvar[AURA] = register_cvar("bio_leader_aura", "0");
}

public plugin_precache()
{
	trail_sprite = precache_model(g_trail_sprite);
}

public le_RoundRestart()
{
	g_rounds = 0;
}

public client_disconnect(id)
{
	return_to_default(leader);
	set_task(0.1, "check_leader");
}

public le_RoundStart()
{
	if(g_rounds == 1)
	{
		g_rounds = -1;
	}
	else if(g_rounds != -1)
	{
		g_rounds = 1;
	}
	
	return_to_default(leader);
	return_to_default(last_leader);
	last_leader = -1;
}

public event_infect(victim, attacker)
{
	set_task(0.5, "check_leader");
}

public event_DeathMsg()
{
	set_task(0.5, "check_leader");
}

public event_gamestart()
{
	set_task(0.5, "check_leader");
}

public check_leader()
{
	if(!game_started() || g_rounds == 0 || g_rounds == 1)
	{
		return;
	}

	leader = get_leader();
	
	if(last_leader != leader && last_leader != -1)
	{
		return_to_default(leader);
		return_to_default(last_leader);
		last_leader = -1;
	}

	if(leader != last_leader)
	{
		trail_randomcolor[0] = random_num(0, 255);
		trail_randomcolor[1] = random_num(0, 255);
		trail_randomcolor[2] = random_num(0, 255);
		
		if(get_pcvar_num(cvar[GLOW]))
		{
			set_user_rendering(leader, kRenderFxGlowShell, trail_randomcolor[0], trail_randomcolor[1], trail_randomcolor[2], kRenderNormal, 15);
		}

		if(get_pcvar_num(cvar[TRAIL]))
		{
			trail[leader] = 1;
		}

		if(get_pcvar_num(cvar[AURA]))
		{
			set_task(0.1, "leader_aura", leader + TASK_AURA, _, _, "b");
		}

		new name[32];
		get_user_name(leader, name, charsmax(name));
		ColorChat(0, "!4[LEADER]!3 %s!1 is the new !3Human Leader !1follow him if you want to survive this round !", name);
		
		last_leader = leader;
	}
}

public fw_CmdStart(id, handle)
{
	if(!get_pcvar_num(cvar[TRAIL]))
	{
		return FMRES_HANDLED;
	}

	if(leader != last_leader)
	{
		id = leader;
	}
	
	if(!is_user_alive(id) || trail[id] == 0)
	{
		return FMRES_IGNORED;
	}
	
	new iButton = get_uc(handle, UC_Buttons);

	if(!(iButton & IN_MOVING))
    	{
		new Float:flGameTime = get_gametime();
	
		if(bflNextCheck[id] < flGameTime)
		{
			UTIL_KillBeamFollow(id);
			UTIL_BeamFollow(id);
		
			bflNextCheck[id] = flGameTime + (15 / 8);
		}
	}
	
	return FMRES_IGNORED;
}

public get_leader_handler(id1, id2)
{
	if(get_user_frags(id1) > get_user_frags(id2) || get_user_frags(id1) == get_user_frags(id2) && get_user_deaths(id1) < get_user_deaths(id2))
		return -1;

	return 1;
}

public get_leader()
{
	new players[32], num;
	get_players(players, num, "aeh", "CT");

	if(num < 2)
	{
		return -1;
	}

	SortCustom1D(players, num, "get_leader_handler");

	return players[0];
}

public leader_aura(taskid)
{
	new id = taskid - TASK_AURA;

	new origin[3];
	get_user_origin(id, origin);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_DLIGHT);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_byte(20);
	write_byte(trail_randomcolor[0]);
	write_byte(trail_randomcolor[1]);
	write_byte(trail_randomcolor[2]);
	write_byte(2);
	write_byte(0);
	message_end();
}
		
stock UTIL_BeamFollow(const id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(id);
	write_short(trail_sprite);
	write_byte(15);
	write_byte(20);
	write_byte(trail_randomcolor[0]);
	write_byte(trail_randomcolor[1]);
	write_byte(trail_randomcolor[2]);
	write_byte(255);
	message_end();
}

stock UTIL_KillBeamFollow(const id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);    
	write_short(id);
	message_end();
}

stock return_to_default(id)
{
	if(!(1 <= id <= 32) || !is_user_connected(id))
		return;

	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	trail[id] = 0;
	bflNextCheck[id] = -1.0;
	UTIL_KillBeamFollow(id);
	remove_task(id + TASK_AURA);
}

stock ColorChat(id, String[], any:...)
{
	static szMesage[192];
	vformat(szMesage, charsmax(szMesage), String, 3);
	
	replace_all(szMesage, charsmax(szMesage), "!1", "^1");
	replace_all(szMesage, charsmax(szMesage), "!3", "^3");
	replace_all(szMesage, charsmax(szMesage), "!4", "^4");
	
	static g_msg_SayText = 0;
	if(!g_msg_SayText)
		g_msg_SayText = get_user_msgid("SayText");
	
	new Players[32], iNum = 1, i;

 	if(id) Players[0] = id;
	else get_players(Players, iNum, "ch");
	
	for(--iNum; iNum >= 0; iNum--)
	{
		i = Players[iNum];
	
		message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i);
		write_byte(i);
		write_string(szMesage);
		message_end();
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1048\\ f0\\ fs16 \n\\ par }
*/
