#include <amxmodx>
#include <cstrike>

#define	PLUGIN	"Money Transferer"
#define	VERSION	"1.0"
#define	AUTHOR	"TEST"

new players_menu, players[32], num, i
new accessmenu, iName[64], callback

new const tag[] = "[Biohazard]";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /give", "transfer_menu", ADMIN_ALL, "");
	register_clcmd("say_team /give", "transfer_menu", ADMIN_ALL, "");
	
	register_clcmd("transfer", "transfer_money", ADMIN_ALL, "");
}

public transfer_menu(id)
{
	get_players(players, num, "h")
	
	if (num <= 1)
	{
		ColorChat(id, "!4%s!1 Nu poti dona bani !", tag);
		return PLUGIN_HANDLED
	}
	
	new tempname[32], info[10]
	
	players_menu = menu_create("Alege un jucator pentru a transfera bani:", "players_menu_handler")
	
	for(i = 0; i < num; i++)
	{
		if(players[i] == id)
			continue
		
		get_user_name(players[i], tempname, 31)
		num_to_str(players[i], info, 9)
		menu_additem(players_menu, tempname, info, 0)
	}
	
	menu_setprop(players_menu, MPROP_EXIT, MEXIT_ALL)
	
	menu_display(id, players_menu, 0)
	return PLUGIN_CONTINUE
}

public players_menu_handler(id, players_menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(players_menu)
		return PLUGIN_HANDLED
	}
	
	new data[6]
	
	menu_item_getinfo(players_menu, item, accessmenu, data, charsmax(data), iName, charsmax(iName), callback)
	
	new player = str_to_num(data)
	ColorChat(id, "!4%s!1 Introdu suma pe care vrei sa o transferi:", tag);
	client_cmd(id, "messagemode ^"transfer %i^"", player)
	return PLUGIN_CONTINUE;
}

public transfer_money(id)
{
	new param[11]
	read_argv(2, param, charsmax(param))
	
	for (new x; x < strlen(param); x++)
	{
		if(!isdigit(param[x]))
		{
			ColorChat(id, "!4%s!1 Valoarea pe care ai scris-o nu contine numere! Reintrodu din nou!", tag);
			return PLUGIN_HANDLED
		}
	}
	
	new amount = str_to_num(param)
	new money = cs_get_user_money(id)
	
	if (money < amount)
	{
		ColorChat(id, "!4%s!1 Nu ai suficienti bani! Reintrodu alta suma!", tag);
		return PLUGIN_HANDLED
	}
	
	read_argv(1, param, charsmax(param))
	new player = str_to_num(param)
	
	new player_money = cs_get_user_money(player)
	
	cs_set_user_money(id, money - amount)
	cs_set_user_money(player, player_money + amount)
	
	new names[2][32]
	
	get_user_name(id, names[0], 31)
	get_user_name(player, names[1], 31)
	
	ColorChat(id, "!4%s!1 Ai transferat cu succes suma de!3 %d!1 $ lui!3 %s!1.", tag, amount, names[1])
	ColorChat(player, "!4%s!3 %s!1 ti-a donat!3 %d!1 $ din suma lui.", tag, names[0], amount)
	
	return PLUGIN_HANDLED
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