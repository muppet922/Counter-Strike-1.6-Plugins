#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

new const red_color[14] = { 250, 50, 250, 250, 250, 250, 250, 50, 250, 250, 250, 250, 250, 250 }
new const green_color[14] = { 250, 150, 250, 150, 0, 250, 50, 150, 150, 0, 150, 250, 150, 0 }
new const blue_color[14] = { 250, 250, 50, 50, 0, 50, 250, 250, 50, 0, 250, 50, 50, 0 }
new const cso_kill_headshot[] = "so/headshot.wav"
new const cso_kill_sounds[14][] =
{
	"so/kill1.wav",
	"so/kill2.wav",
	"so/kill3.wav",
	"so/kill4.wav",
	"so/kill5.wav",
	"so/kill6.wav",
	"so/kill7.wav",
	"so/kill8.wav",
	"so/kill9.wav",
	"so/kill10.wav",
	"so/kill11.wav",
	"so/kill12.wav",
	"so/kill13.wav",
	"so/kill14.wav"
}

new Float:g_iTask[33];
new g_iKills[33];
new g_center1_sync;

public plugin_init()
{
	register_plugin("Kill's Like CS Online", "0.1", "fl0wer")

	RegisterHam(Ham_Killed, "player", "Player_Killed_Post", 1)
	RegisterHam(Ham_Player_PostThink, "player", "Player_PostThink_Post", 1)

	g_center1_sync = CreateHudSyncObj()
}

public plugin_precache()
{
	for(new i = 0; i < sizeof cso_kill_sounds; i++) 
		precache_sound(cso_kill_sounds[i])

	precache_sound(cso_kill_headshot)
}

public Player_Killed_Post(victim, attacker, shouldgib)
{
	if(!is_user_connected(attacker))
		return;

	if(victim == attacker)
		return;

	g_iKills[attacker]++;
	g_iTask[attacker] = get_gametime();
	g_iKills[victim] = 0;
	g_iTask[victim] = 0.0;

	new speak_kills = g_iKills[attacker] - 1;

	if(get_pdata_int(victim, 75) == HIT_HEAD)
	{
		client_cmd(attacker, "speak ^"%s^"", cso_kill_headshot)
	}
	else
	{
		client_cmd(attacker, "speak ^"%s^"", cso_kill_sounds[speak_kills])
	}
	set_hudmessage(red_color[g_iKills[attacker]], green_color[g_iKills[attacker]], blue_color[g_iKills[attacker]], -1.0, 0.25, 0, 0.1, 3.0, 0.1, 0.1, -1)
	ShowSyncHudMsg(attacker, g_center1_sync, "%d KILL!", g_iKills[attacker])
}

public Player_PostThink_Post(id)
{
	if(!is_user_alive(id))
		return;

	if(g_iTask[id] + 4.0 <= get_gametime())
	{
		g_iKills[id] = max(g_iKills[id] -= 1, 0);
		g_iTask[id] = get_gametime();
	}
}