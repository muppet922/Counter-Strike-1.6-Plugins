//  Copyright © 2015 Vaqtincha

//====================== CONFIG START =======================//
// #define USE_COLORCHAT_INC	// use colorchat.inc
// #define NO_FLASH			// AntiFlash (beta)
// ======================= CONFIG END ========================//


#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#if defined USE_COLORCHAT_INC && !defined NO_FLASH && AMXX_VERSION_NUM < 183 
#include <colorchat>
#endif

enum
{
    Duration = 1,// short
    HoldTime,	// short
    Flags,		// short
    ColorR, 	// byte
    ColorG, 	// byte
    ColorB, 	// byte
	Alpha		// byte
}

new g_FlId, g_MsgIdSayText

public plugin_init()
{
	register_plugin("Flasher Name", "1.0.0", "Vaqtincha")

	RegisterHam(Ham_Think, "grenade", "Grenade_Think", .Post = false)

	g_MsgIdSayText = get_user_msgid("SayText")
	#if defined NO_FLASH
	register_message(get_user_msgid("ScreenFade"), "Message_ScreenFade")
	#else
	register_event("ScreenFade", "Event_ScreenFade", "be","1>0","2>0","3=0","4=255","5=255","6=255","7>199")
	#endif
}
#if defined NO_FLASH
public Message_ScreenFade(iMsgId, iMsgType, iMsgEnt)
{
	if(get_msg_arg_int(ColorR) != 255 || get_msg_arg_int(ColorG) != 255 
	|| get_msg_arg_int(ColorB) != 255 || get_msg_arg_int(Alpha) < 200)
		return PLUGIN_CONTINUE

	if(!g_FlId || iMsgEnt == g_FlId || get_user_team(iMsgEnt) != get_user_team(g_FlId))
		return PLUGIN_CONTINUE

	return PLUGIN_HANDLED
}
#else
public Event_ScreenFade(id)
{
	if(!g_FlId || id == g_FlId || get_user_team(id) != get_user_team(g_FlId))
		return

	new szNoobName[32], szVictimName[32]
	get_user_name(g_FlId, szNoobName, charsmax(szNoobName))
	get_user_name(id, szVictimName, charsmax(szVictimName))

	#if defined USE_COLORCHAT_INC
	client_print_color(id, print_team_grey, "^3Flashed by teammate ^1(^4%s^1)", szNoobName)
	client_print_color(g_FlId, print_team_red, "^3You flashed a teammate ^1(^4%s^1)", szVictimName)
	#else
	ChatPrintColor(id, "^4[SERVER] ^1Flashed by teammate (^3%s^1)", szNoobName)
	ChatPrintColor(g_FlId, "^4[SERVER] ^3You ^1flashed a teammate (^3%s^1)", szVictimName)
	#endif
}
#endif
public Grenade_Think(ent)
{
	static szModel[23]; pev(ent, pev_model, szModel, charsmax(szModel))

	if(equal(szModel, "models/w_flashbang.mdl"))
	{
		if(pev(ent, pev_dmgtime) <= get_gametime() && ~pev(ent, pev_effects) & EF_NODRAW)
			g_FlId = pev(ent, pev_owner)
	}
}

stock ChatPrintColor(id, const szMessage[], any:...)
{
	static szMsg[191]; vformat(szMsg, charsmax(szMsg), szMessage, 3)
	if(is_user_connected(id))
	{
		message_begin(MSG_ONE, g_MsgIdSayText, .player = id)
		write_byte(id)
		write_string(szMsg)
		message_end()
	}
}
