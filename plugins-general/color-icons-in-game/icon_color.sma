#include <amxmodx>

new icon_color[3], icon[10], CVAR_RANDOM_COLOR, CVAR_COLOR[15]
enum {MsgArg_Status = 1, MsgArg_Name, MsgArg_R, MsgArg_G, MsgArg_B}
new const icon_name[][] = {"c4", "defuser", "buyzone", "escape", "rescue", "vipsafety"}

public plugin_init()
{
	register_plugin("Icon Color", "1.0", "AcE")
	register_message(get_user_msgid("StatusIcon"), "mStatusIcon")
	bind_pcvar_num(create_cvar("icon_random_color", "1"), CVAR_RANDOM_COLOR)
	bind_pcvar_string(create_cvar("icon_color", "0 160 0"), CVAR_COLOR, charsmax(CVAR_COLOR))
	server_cmd("exec addons/amxmodx/configs/icon_color.cfg"); server_exec()

	if (CVAR_RANDOM_COLOR)
	{
		register_event_ex("HLTV", "EventStartRound", RegisterEvent_Global, "1=0", "2=0")
		EventStartRound()
	}
	else
	{
		new sColor[3][4]
		parse(CVAR_COLOR, sColor[0], 3, sColor[1], 3, sColor[2], 3)
		icon_color[0] = str_to_num(sColor[0])
		icon_color[1] = str_to_num(sColor[1])
		icon_color[2] = str_to_num(sColor[2])
	}
}

public EventStartRound()
{
	icon_color[0] = random_num(0, 255)
	icon_color[1] = random_num(0, 255)
	icon_color[2] = random_num(0, 255)
}

public mStatusIcon(msgId, msgDest, msgEnt)
{
	#pragma unused msgId
	#pragma unused msgDest
	#pragma unused msgEnt

	if (get_msg_arg_int(MsgArg_Status))
	{
		get_msg_arg_string(MsgArg_Name, icon, charsmax(icon))
		for (new i; i < sizeof icon_name; i ++)
		{
			if (!strcmp(icon, icon_name[i]))
			{
				set_msg_arg_int(MsgArg_R, ARG_BYTE, icon_color[0])
				set_msg_arg_int(MsgArg_G, ARG_BYTE, icon_color[1])
				set_msg_arg_int(MsgArg_B, ARG_BYTE, icon_color[2])
			}
		}
	}
	return PLUGIN_CONTINUE
}