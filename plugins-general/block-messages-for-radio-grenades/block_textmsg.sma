#include <amxmodx>

public plugin_init()
{
	register_plugin("Block TextMsg", "1.0", "AcE")
	register_message(get_user_msgid("TextMsg"), "TextMsgHandler")
}

public TextMsgHandler(msgid, dest, receiver)
{
	#define ARG_DESTINATION_TYPE 1
	#define print_radio 5
	#define ARG_RADIO_STRING 3

	static szMsg[18]
	static const szGameRadio[] = "#Game_radio"

	if (get_msg_arg_int(ARG_DESTINATION_TYPE) != print_radio)
		return PLUGIN_CONTINUE

	get_msg_arg_string(ARG_RADIO_STRING, szMsg, charsmax(szMsg))
	if (!strcmp(szMsg, szGameRadio))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}