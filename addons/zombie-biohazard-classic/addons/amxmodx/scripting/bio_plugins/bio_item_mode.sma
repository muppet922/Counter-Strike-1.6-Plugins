#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <fakemeta>
#include <dhudmessage>
#include <biohazard>



#define SCREENFLASH_ON_KILL



new const PLUGIN_NAME[] = "[BH] Item Mode", 
	 PLUGIN_VERSION[] = "3.0", 
	 PLUGIN_AUTHOR[] = "TEST";

new const Tag[] = "[BIO-REWARD]";
new const SoundLevelUp[] = "biohazard/levelup.wav";

new g_UserKills[33];

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_cvar("level_mod_", PLUGIN_VERSION, FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string("level_mod_", PLUGIN_VERSION);

	register_event("DeathMsg", "event_DeathMsg", "a");

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1);
}

public fw_PlayerSpawn(id)
{
	if(!is_user_connected(id)) return;
	reset_vars(id);

	cs_set_user_armor(id, 0, CS_ARMOR_NONE);
}

public plugin_precache()
{
	precache_sound(SoundLevelUp);
}

public client_disconnect(id)
{
	reset_vars(id);
}

public event_DeathMsg()
{
	new attacker = read_data(1);
	new victim = read_data(2);

	if(!is_user_alive(attacker) || !is_user_connected(victim))
		return PLUGIN_CONTINUE;

	if(attacker == victim || is_user_zombie(attacker))
		return PLUGIN_HANDLED;

	#if defined SCREENFLASH_ON_KILL
	if(is_user_zombie(victim))
		MakeFadeScreen(attacker, 1.5, 37, 80, 207, 50);
	#endif

	reset_vars(victim);
	CheckUserLevel(attacker);

	return PLUGIN_CONTINUE;
}

public event_infect(victim, attacker)
{
	reset_vars(victim);
}

public CheckUserLevel(id)
{
	if(!is_user_connected(id) || is_user_zombie(id))
		return PLUGIN_HANDLED;

	g_UserKills[id]++;

	switch(g_UserKills[id])
	{
		case 1:
		{
			new CsArmorType:ArmorType = CS_ARMOR_KEVLAR;
			cs_set_user_armor(id, 20, ArmorType);

			emit_sound(id, CHAN_AUTO, SoundLevelUp, 1.0, ATTN_NORM, 0, PITCH_NORM);
			ColorChat(id, "!3%s!1 Well done, you've got !420 ARMOR!1. Want more? Kill more !4ZOMBIES !", Tag);
		}
		case 2:
		{
			new CsArmorType:ArmorType = CS_ARMOR_KEVLAR;
			cs_set_user_armor(id, 60, ArmorType);

			emit_sound(id, CHAN_AUTO, SoundLevelUp, 1.0, ATTN_NORM, 0, PITCH_NORM);
			ColorChat(id, "!3%s!1 Well done, you've got !460 ARMOR!1. Want more? Kill more !4ZOMBIES !", Tag);
		}
		case 3:
		{
			new CsArmorType:ArmorType = CS_ARMOR_KEVLAR;
			cs_set_user_armor(id, 100, ArmorType);

			emit_sound(id, CHAN_AUTO, SoundLevelUp, 1.0, ATTN_NORM, 0, PITCH_NORM);
			ColorChat(id, "!3%s!1 Well done, you've got !4100 ARMOR!1.", Tag);
			ColorChat(id, "!4%s!1 You've got !3FULL ARMOR BODY !1this round, you are the !4MVP.", Tag);
		}
		default:
		{
			ColorChat(id, "!4%s!1 Congratulations, you've managed to get !3FULL ARMOR BODY !", Tag);
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}

stock MakeFadeScreen(id, const Float:Seconds, const Red, const Green, const Blue, const Alpha)
{
	static g_MsgScreenFade = 0;
	if(!g_MsgScreenFade)
		g_MsgScreenFade = get_user_msgid("ScreenFade");

	message_begin(MSG_ONE, g_MsgScreenFade, _, id);
	write_short(floatround(4096.0 * Seconds, floatround_round));
	write_short(floatround(4096.0 * Seconds, floatround_round));
	write_short(0x0000);
	write_byte(Red);
	write_byte(Green);
	write_byte(Blue);
	write_byte(Alpha);
	message_end();
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

public reset_vars(id)
{
	g_UserKills[id] = 0;
}

stock fm_find_ent_by_owner(index, const classname[], owner) 
{
	static ent;
	ent = index;
	
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) && pev(ent, pev_owner) != owner) {}
	
	return ent;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
