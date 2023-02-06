#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#tryinclude <biohazard>

#define PLUGIN_NAME	"[Biohazard] Human: Powers"
#define PLUGIN_AUTHORS	"TEST"
#define PLUGIN_VERSION	"1.0"

new menu, text_menu[128], g_HostName[64]
new cvar_hostname, cvar_start

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHORS);
	is_biomod_active() ? plugin_init2() : pause("ad")
}

public plugin_init2()
{
	cvar_hostname = get_cvar_pointer("hostname")
	cvar_start = get_cvar_pointer("bh_starttime")

	register_logevent("event_NewRound", 2, "1=Round_Start")
}

public plugin_cfg()
{
	get_pcvar_string(cvar_hostname, g_HostName, charsmax(g_HostName))
}

public client_disconnected(id)
{
	remove_task(11110)
}

public event_NewRound()
{
	new Float:start_time = get_pcvar_float(cvar_start) + 1
	set_task(start_time, "task_init", 11110)
}

public task_init()
{
	if(!game_started())
		return

	new players[32], num, id
	get_players(players, num, "ac")

	for(new i = 0; i < num ; i++)
	{
		id = players[i];
		if(is_user_zombie(id) || !is_user_alive(id))
			continue

		PowersHuman(id)
	}
}

public PowersHuman(id)
{
	formatex(text_menu, charsmax(text_menu), "\wPick up your Soldier^n\y%s", g_HostName)
	menu = menu_create(text_menu, "HumanHandler")

	menu_additem(menu, "Pyroman Soldier (\r+1 NapalmNades\w)", "1", 0)
	menu_additem(menu, "Light Soldier (\r+2 LightGrenades\w)", "2", 0)
	menu_additem(menu, "IceAge Soldier (\r+1 FrostNades\w)", "3", 0)
	menu_additem(menu, "Inazuma Soldier (\r310 Speed\w)", "4", 0)
	menu_additem(menu, "Hibryd Soldier (\r600 Gravity\w)", "5", 0)

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	
	return PLUGIN_CONTINUE
}

public HumanHandler(id, menu, item)
{
	new data[6], name[64], access, CallBack
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), CallBack)
	new iKey = str_to_num(data)

	if(!is_user_connected(id) || is_user_zombie(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(iKey)
	{
		case 1:
		{
			bacon_strip_weapon(id, "weapon_hegrenade")
			give_item(id, "weapon_hegrenade")
			cs_set_user_bpammo(id, CSW_HEGRENADE, 2)
		}

		case 2:
		{
			bacon_strip_weapon(id, "weapon_smokegrenade")
			give_item(id, "weapon_smokegrenade")
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 3)
		}

		case 3:
		{
			bacon_strip_weapon(id, "weapon_flashbang")
			give_item(id, "weapon_flashbang")
			cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
		}

		case 4:
		{
			set_user_maxspeed(id, 310.0)
			emit_sound(id, CHAN_VOICE, "items/tr_kevlar.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}

		case 5:
		{
			set_user_gravity(id, 600.0 * 0.00125)
			emit_sound(id, CHAN_VOICE, "items/tr_kevlar.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
	}

	menu_destroy(menu)
	return PLUGIN_HANDLED
}

stock ColorChat(id, String[], any:...)
{
	static szMesage[192]
	vformat(szMesage, charsmax(szMesage), String, 3)
	
	replace_all(szMesage, charsmax(szMesage), "!1", "^1")
	replace_all(szMesage, charsmax(szMesage), "!3", "^3")
	replace_all(szMesage, charsmax(szMesage), "!4", "^4")
	
	static g_msg_SayText = 0
	if(!g_msg_SayText)
		g_msg_SayText = get_user_msgid("SayText")
	
	new Players[32], iNum = 1, i

 	if(id) Players[0] = id
	else get_players(Players, iNum, "ch")
	
	for(--iNum; iNum >= 0; iNum--)
	{
		i = Players[iNum]
	
		message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i)
		write_byte(i)
		write_string(szMesage)
		message_end()
	}
}

stock fm_find_ent_by_owner(id, const szClassName[], iOwner, jghgtype = 0)
{
	new str_type[11] = "classname", iEnt = id

	switch(jghgtype)
	{
		case 1: str_type = "target"
		case 2: str_type = "targetname"
	}

	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, str_type, szClassName)) && pev(iEnt, pev_owner) != iOwner) {}
	return iEnt
}

stock bacon_strip_weapon(index, weapon[])
{
	if(!equal(weapon, "weapon_", 7)) 
		return PLUGIN_CONTINUE

	static weaponid;
	weaponid = get_weaponid(weapon)
	
	if(!weaponid) 
		return PLUGIN_CONTINUE

	static weaponent
	weaponent = fm_find_ent_by_owner(-1, weapon, index);
	
	if(!weaponent)
		return PLUGIN_CONTINUE

	if(get_user_weapon(index) == weaponid) 
		ExecuteHamB(Ham_Weapon_RetireWeapon, weaponent)

	if(!ExecuteHamB(Ham_RemovePlayerItem, index, weaponent)) 
		return PLUGIN_CONTINUE
	
	ExecuteHamB(Ham_Item_Kill, weaponent)
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))

	return PLUGIN_HANDLED
}