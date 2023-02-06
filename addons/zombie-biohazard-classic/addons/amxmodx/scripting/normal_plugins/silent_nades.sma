/**********************************************************************************
* Author: regalis (regalis1@gmx.de)
*
*	Version: 1.0
*
*
*	Description:
*		This plugin removes the message "Fire in the hole" and the sound "Fire in the hole" for every nade.
*		Every player can for himself choose if he want to hear/read the Nade-Sounds/Messages by simple client-commands
*		Thats all :)
*
*
*	CVARS:
*		-amx_snilentnades	1|0 (1 = enabled | 0 = disabled)
*		-amx_sn_mode 0|1|2 (0 = S:OFF M:OFF | 1 = S:OFF M:ON | 2 = S:ON M:OFF)
*
*
*	Console-Commands available for admins:
*		-amx_sntoggle - Toggles Silent-Nades ON|OFF
*		-amx_snmode - Toggles between the 3 Silent-Nades Modes (S:ON M:OFF | S:OFF M:ON | S:OFF M:OFF)
*
*
*	Commands available for each player:
*		say "/fithmsg" to toggle Nade-messages ON/OFF
*		say "/fithsnd" to toggle Nade-sounds ON/OFF
*		say "/fith" for an info message on how to enable/disable the sounds/messages
*
*
*	Changelog:
*		V0.1.0 
*			@Release
*
*		V0.2.0 
*			+Added CS:CZ support, requested and suggested by mogel and Ryu2877
*
*		V0.2.5
*			+Added Client commands so that everyone can choose for himself if want to hear/read the Nade-sounds/messages
*			+Added a welcome-message with the client command to get help
*			+Added a help-message which displays info on how to enable/disable the sounds/messages
*
*		V0.3.0
*			+Added Admin commands to disable/enable the whole plugin
*			+Added Admin commands to toggle between 3 modes:
*					1. Sound: ON / Messages: OFF
*					2. Sound: OFF / Messages: ON
*					3. Sound: OFF / Messages: OFF
*
*
*		V0.3.5
*			+Added ShowSyncHudMsg() support
*			+Added set_user_info() support for saving settings even after roundstart|reconnect
*
*		V1.0
*			!Optimized code a little
*			@Got approved and therefore changed Version to 1.0
*
*
* Known Bugs:
*			-NONE-
*
*
*	TODO:
*			+Add a procedure to save the player preferences so they will not be cleared on changelevel or reconnect.
*
*
*	Credits:
*		Angelina for the initial idea to make this plugin!
*		mogel and Ryu2877 for giving me the hint to adjust the argument number to 6 for CS:CZ support
*		VEN for the idea that everyone should be able to enable/disable the Messages/Sounds for himself
*		"Message Logging 1.17" by Damaged Soul VERY usefull!!! *omg*
*		http://wiki.alliedmods.net/Main_Page
*		http://www.amxmodx.org/doc/
*
***********************************************************************************/

/*
Also a hint.
You can use set_user_info() to store personal client configuration into UserInfo buffer.
This will allow to keep configuration for every specific client until his actual disconnect.
Buffer will not be cleared on changelevel or reconnect. 
Note that better set a short key name and key value to not clutter up UserInfo buffer.

For example this is how i'd do that.
key name: "_fith", key value: "3". 3 is ((1<<0) | (1<<1)) - so this mean that audio and text is disabled.
If you familiar with bitwise operations you'll get what i mean and how to deal with it.
If not then you can do it in similar manner but without bitwise operations.
And also maybe make amx_silentnades CVar functionality in the same manner to provide more flexibility.
If you don't like digits you can use for example "ab" letters/flags. 
But again it will be converted into bitwise-like form if you going to use read_flags().

If you interested in learning more about bitwise operations you can visit this page
http://wiki.amxmodx.org/index.php/Pawn
It's cover Pawn scripting basics.


Let's say that you have a CVar: my_cvar "ab"
You get CVar value and then do: 

new flags = read_flags(cvar_value)

And then:

if (flags & (1<<0)) // check for "a" flag, (1<<0) == 1 and corresponds to "a" 
 // do something
if (flags & (1<<1)) // check for "b" flag, (1<<1) == 2 and corresponds to "b"   
 // do something


*/

#include <amxmodx>
#include <amxmisc>

#define MAXPLAYERS 32
#define Version "1.0"

new bool:g_player_FITH[MAXPLAYERS+1][2];
new g_sn_enabled;
new g_sn_mode;
new g_MsgSync;


public plugin_init()
{
	register_plugin("silentnades", Version, "regalis");

	register_message(get_user_msgid("TextMsg"), "block_FITH_message");
	register_message(get_user_msgid("SendAudio"), "block_FITH_audio");

	register_cvar("silentnades_version", Version, FCVAR_SERVER|FCVAR_SPONLY);
	g_sn_enabled = register_cvar("amx_silentnades", "1");
	g_sn_mode = register_cvar("amx_sn_mode", "0");
	register_concmd("amx_sntoggle", "toggle_sn", ADMIN_CVAR, "amx_sn_toggle - Toggle Silent-Nades ON/OFF");
	register_concmd("amx_snmode", "toggle_mode", ADMIN_CVAR, "amx_sn_mode - Toggle between modes RADIO/CHAT/BOTH");
	register_clcmd("say /fithmsg", "client_message");
	register_clcmd("say /fithsnd", "client_sound");
	register_clcmd("say /fith", "client_info");
	g_MsgSync = CreateHudSyncObj();
}


public toggle_mode(id,lvl,cid)
{
	if(!cmd_access(id, lvl, cid, 1)) return PLUGIN_HANDLED;
	new snmode = get_pcvar_num(g_sn_mode);	
	switch(snmode)
	{
		case 0:
		{
			set_pcvar_num(g_sn_mode, 1);
			set_fith_mode(false, true);
			console_print(id, "Silent-Nades:  SOUND-MESSAGES: -Disabled- / CHAT-MESSAGES: -Enabled-");
			log_message("[AMXX] Silent-Nades:  SOUND-MESSAGES: -Disabled- / CHAT-MESSAGES: -Enabled-");
		}
		case 1:
		{
			set_pcvar_num(g_sn_mode, 2);
			set_fith_mode(true, false);
			console_print(id, "Silent-Nades:  SOUND-MESSAGES: -Enabled- / CHAT-MESSAGES: -Disabled-");
			log_message("[AMXX] Silent-Nades:  SOUND-MESSAGES: -Enabled- / CHAT-MESSAGES: -Disabled-");
		}
		case 2:
		{
			set_pcvar_num(g_sn_mode, 0);
			set_fith_mode(false, false);
			console_print(id, "Silent-Nades:  SOUND-MESSAGES: -Disabled- / CHAT-MESSAGES: -Disabled-");
			log_message("[AMXX] Silent-Nades:  SOUND-MESSAGES: -Disabled- / CHAT-MESSAGES: -Disabled-");	
		}
	}
	return PLUGIN_HANDLED;
}


public toggle_sn(id,lvl,cid)
{
	if(!cmd_access(id, lvl, cid, 1)) return PLUGIN_HANDLED;
	if(!get_pcvar_num(g_sn_enabled))
	{
		set_pcvar_num(g_sn_enabled, 1);
		set_fith_mode(false, false);
		console_print(id, "Silent-Nades:  The Messages are now -Disabled-");
		log_message("[AMXX] Silent-Nades:  The Messages are now -Disabled-");
	}
	else 
	{
		set_pcvar_num(g_sn_enabled, 0);
		set_fith_mode(true, true);
		console_print(id, "Silent-Nades:  The Messages are now -Enabled-");
		log_message("[AMXX] Silent-Nades:  The Messages are now -Enabled-");
	}
	return PLUGIN_HANDLED;
}


set_fith_mode(bool:snd, bool:msg)
{
	new playercount, Players[MAXPLAYERS];
	get_players(Players, playercount);
	for(new i=0;i<playercount;i++)
	{		
		g_player_FITH[i][0] = msg;
		g_player_FITH[i][1] = snd;
	}	
}


public client_putinserver(id)
{
	if(!get_pcvar_num(g_sn_enabled)) return PLUGIN_HANDLED;
	set_task(10.0,"welcome",id);
	return PLUGIN_HANDLED;
}


public welcome(id)
{
	set_hudmessage(192, 192, 192, -1.0, 0.45, 2, 0.02, 10.0, 0.01, 0.1);
	switch(get_pcvar_num(g_sn_mode))
	{
		case 1:{
			ShowSyncHudMsg(id, g_MsgSync, "Welcome! Don't forget to visit our forum as well: www.oldones.ro");
		}
		case 2:{
			ShowSyncHudMsg(id, g_MsgSync, "Welcome! Don't forget to visit our forum as well: www.oldones.ro");
		}
		default:{
			ShowSyncHudMsg(id, g_MsgSync, "Welcome! Don't forget to visit our forum as well: www.oldones.ro");
		}
	}
	return PLUGIN_HANDLED;
}


public client_info(id)
{
	if(!get_pcvar_num(g_sn_enabled)) return PLUGIN_HANDLED;
	set_hudmessage(192, 192, 192, -1.0, 0.45, 2, 0.02, 5.0, 0.01, 0.1);
	switch(get_pcvar_num(g_sn_mode))
	{
		case 1:{
			ShowSyncHudMsg(id, g_MsgSync, "For enable/disable Nade-Sounds type /fithsnd");
		}
		case 2:{
			ShowSyncHudMsg(id, g_MsgSync, "For enable/disable Nade-Messages type /fithmsg");
		}
		default:{
			ShowSyncHudMsg(id, g_MsgSync, "For enable/disable Nade-Sounds/Messages type /fithsnd or /fithmsg");
		}
	}
	return PLUGIN_HANDLED;
}


public client_message(id)
{
	if(!get_pcvar_num(g_sn_enabled)) return PLUGIN_HANDLED;
	set_hudmessage(20, 20, 200, -1.0, 0.0, 0, 0.0, 5.0, 0.0, 0.0);
	if(get_pcvar_num(g_sn_mode) == 1)
	{
		ShowSyncHudMsg(id, g_MsgSync, "Sorry, server has disabled this option only /fithsnd will work!");
	}
	else
	{
		if(!g_player_FITH[id][0])
		{
			g_player_FITH[id][0] = true;
		}
		else
		{
			g_player_FITH[id][0] = false;
		}
		ShowSyncHudMsg(id, g_MsgSync, "NADE-Messages: %s", (g_player_FITH[id][0] ? "ON" : "OFF"));
	}
	return PLUGIN_HANDLED;
}


public client_sound(id)
{
	if(!get_pcvar_num(g_sn_enabled)) return PLUGIN_HANDLED;
	set_hudmessage(20, 20, 200, -1.0, 0.0, 0, 0.0, 5.0, 0.0, 0.0);
	if(get_pcvar_num(g_sn_mode) == 2)
	{
		ShowSyncHudMsg(id, g_MsgSync, "Sorry, server has disabled this option only /fithmsg will work!");
	}
	else
	{
		if (!get_pcvar_num(g_sn_enabled)) return PLUGIN_HANDLED;
		if(!g_player_FITH[id][1])
		{
			g_player_FITH[id][1] = true;
		}
		else
		{
			g_player_FITH[id][1] = false;
		}
		ShowSyncHudMsg(id, g_MsgSync, "NADE-Sound: %s", (g_player_FITH[id][1] ? "ON" : "OFF"));
	}
	return PLUGIN_HANDLED;
}


/*
MessageBegin (TextMsg "77") (Destination "One<1>") (Args "5") (Entity "1") (Classname "player") (Netname "~regalis~") (Origin "0.000000 0.000000 0.000000")
Arg 1 (Byte "5")
Arg 2 (String "1")
Arg 3 (String "#Game_radio")
Arg 4 (String "~regalis~")
Arg 5 (String "#Fire_in_the_hole")
MessageEnd (TextMsg "77")
*/
public block_FITH_message(msg_id, msg_dest, entity)
{
	if(!get_pcvar_num(g_sn_enabled)) return PLUGIN_CONTINUE;
	if(get_pcvar_num(g_sn_mode) == 1) return PLUGIN_CONTINUE;
	if(get_msg_args() == 5)
	{
		if(get_msg_argtype(5) == ARG_STRING)
		{
			new value5[64];
			get_msg_arg_string(5 ,value5 ,63);
			if(equal(value5, "#Fire_in_the_hole"))
			{
				if(!g_player_FITH[entity][0]) return PLUGIN_HANDLED;
			}
		}
	}
	else if(get_msg_args() == 6)
	{
		if(get_msg_argtype(6) == ARG_STRING)
		{
			new value6[64];
			get_msg_arg_string(6 ,value6 ,63);
			if(equal(value6 ,"#Fire_in_the_hole"))
			{
				if(!g_player_FITH[entity][0]) return PLUGIN_HANDLED;
			}
		}
	}
	return PLUGIN_CONTINUE;
}


/*
MessageBegin (SendAudio "100") (Destination "One<1>") (Args "3") (Entity "1") (Classname "player") (Netname "~regalis~") (Origin "0.000000 0.000000 0.000000")
Arg 1 (Byte "1")
Arg 2 (String "%!MRAD_FIREINHOLE")
Arg 3 (Short "100")
MessageEnd (SendAudio "100")
*/
public block_FITH_audio(msg_id, msg_dest, entity)
{
	if(!get_pcvar_num(g_sn_enabled)) return PLUGIN_CONTINUE;
	if(get_pcvar_num(g_sn_mode) == 2) return PLUGIN_CONTINUE;
	if(get_msg_args() == 3)
	{
		if(get_msg_argtype(2) == ARG_STRING)
		{
			new value2[64];
			get_msg_arg_string(2 ,value2 ,63);
			if(equal(value2 ,"%!MRAD_FIREINHOLE"))
			{
				if(!g_player_FITH[entity][1]) return PLUGIN_HANDLED;
			}
		}
	}
	return PLUGIN_CONTINUE;
}