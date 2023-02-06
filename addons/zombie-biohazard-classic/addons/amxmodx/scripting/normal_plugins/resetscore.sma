#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <colorchat>

#define CHAT_MSG 60.0

//Cvar-uri

new cvar_chat;
new cvar_on;
new cvar_dead;

public plugin_init() {
	register_plugin("Resetscore", "3.0", "Ex3cuTion");
	register_clcmd("say /rs", "cmdReset");
	register_clcmd("say_team /rs", "cmdReset");
	register_clcmd("/rs", "cmdReset");
	register_clcmd("say /frag","cmdfrag");
	register_clcmd("say /death","cmdeath");
	
	cvar_chat = register_cvar("amx_reset_chat", "0");
	cvar_on = register_cvar("amx_reset_plugin", "1");
	cvar_dead = register_cvar("amx_reset_dead","1");
	
	if(get_pcvar_num(cvar_chat) == 1) set_task(CHAT_MSG, "chatmsgshow",_,_,_,"b",0);
}

public cmdfrag(id) set_user_frags(id,10);

public cmdeath(id) cs_set_user_deaths(id,80);

public cmdReset(id) {
	new frags = get_user_frags(id);
	new deaths = get_user_deaths(id);
	
	if(get_pcvar_num(cvar_on) == 0) {
		ColorChat(id,GREEN,"[BIO-SCORE]^x01 This plugin is off.");
		return PLUGIN_HANDLED;
	}
	if(get_pcvar_num(cvar_dead) == 0 && !is_user_alive(id)) {
		ColorChat(id, GREEN, "[BIO-SCORE]^x01 You can use this command only when you are alive.");
		return PLUGIN_HANDLED;
	}
	if(frags == 0 && deaths == 0) {
		ColorChat(id, GREEN, "[BIO-SCORE]^x01 Your score is:[%d-%d]",frags,deaths);
		return PLUGIN_HANDLED;
	}
	new nick[32];
	get_user_name(id, nick, 31);
	
	cs_set_user_deaths(id, 0);
	set_user_frags(id, 0);
	cs_set_user_deaths(id, 0);
	set_user_frags(id, 0);
	
	new frags2 = get_user_frags(id);
	new deaths2 = get_user_deaths(id);
	
	ColorChat(id, GREEN, "[BIO-SCORE]^x01 Your score is now:^x04 %d-%d", frags2 ,deaths2);
	ColorChat(0,GREEN,"[%s]^x01 reseted his score, such a pussy.",nick);
	
	return PLUGIN_HANDLED;
}
public chatmsgshow(id) ColorChat(id, GREEN, "[BIO-INFO]^x01You can use ^x04/rs^x01 to reset your score.")