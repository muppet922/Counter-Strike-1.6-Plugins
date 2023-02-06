#include <amxmodx>

new g_scTitle[]   = "Last Round";
new g_scVersion[] = "1.0";
new g_scAuthor[]  = "TEST";

new bool:g_lastround = false;
new bool:g_changemap = false;
new Float:g_timelimit = 0.0;
new Float:g_maxspeed;

#define INITIATE_LAST_ROUND_TASK 545454
#define CHANGE_MAP_TASK 545455
#define DISABLE_PLAYERS_TASK 545456

public evRoundStart() {
	// Wanted this in init but never got a value 
	if (g_timelimit == 0.0)
		g_timelimit = get_cvar_float("mp_timelimit");
	
	if (g_lastround) {
		new Float:roundtime = get_cvar_float("mp_roundtime");
		new Float:c4timer = get_cvar_float("mp_c4timer")/60;
		// Extend the maps time one round + c4timer + some buffer
		set_cvar_float("mp_timelimit", g_timelimit + roundtime + c4timer + 0.5);
		
		new text[256];
		format(text, 255, "The time limit is over, this is the LAST ROUND !");
		doTypesay(text, 5, 210, 0, 0);
		
		g_changemap = true;
		g_lastround = false;
		} else if (g_changemap) {
		new nextmap[32];
		get_cvar_string("amx_nextmap", nextmap, 31);
		
		new text[256];
		format(text, 255, "The time is over. Nextmap is: %s!", nextmap);
		doTypesay(text, 5, 210, 0, 0);
		
		g_maxspeed = get_cvar_float("sv_maxspeed");
		set_cvar_float("sv_maxspeed", 0.0);
		
		set_task(0.1, "disablePlayers", DISABLE_PLAYERS_TASK, "", 0, "a", 3);
		set_task(6.0, "changeMap", CHANGE_MAP_TASK);
	}
	
	return PLUGIN_CONTINUE;
}

public initiateLastRound() {
	remove_task(INITIATE_LAST_ROUND_TASK);
	
	new text[256];
	format(text, 255, "");
	doTypesay(text, 5, 210, 0, 0);
	
	new Float:roundtime = get_cvar_float("mp_roundtime");
	new Float:c4timer = get_cvar_float("mp_c4timer")/60;
	
	// (2* roundtime since it is possible that the even occurs at the beginning of a round)
	set_cvar_float("mp_timelimit", g_timelimit + (2.0*roundtime) + (2.0*c4timer));
	
	g_lastround = true;
	
	return PLUGIN_CONTINUE;
}

public disablePlayers() {
	new players[32], num;
	get_players(players, num, "c");
	for(new i=0;i<num; i++) {
		client_cmd(players[i],"drop");
	}
}

public changeMap() {
	remove_task(CHANGE_MAP_TASK);
	
	new nextmap[32];
	get_cvar_string("amx_nextmap", nextmap, 31);
	server_cmd("changelevel %s", nextmap);
}

doTypesay(string[], duration, r, g, b) {
	set_hudmessage(r, g, b, 0.05, 0.45, 0, 6.0, float(duration) , 0.5, 0.15, 4);
	show_hudmessage(0, string);
}

public plugin_init() {
	register_plugin(g_scTitle, g_scVersion, g_scAuthor);
	
	register_logevent("evRoundStart", 2, "0=World triggered", "1=Round_Start");
	
	// Chose 90 seconds not to clash with other events
	set_task(90.0, "initiateLastRound", INITIATE_LAST_ROUND_TASK, "", 0, "d");
	
	return PLUGIN_CONTINUE;
}

public plugin_end() {
	set_cvar_float("mp_timelimit", g_timelimit);
	set_cvar_float("sv_maxspeed", g_maxspeed);
	
	remove_task(DISABLE_PLAYERS_TASK);
	
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
