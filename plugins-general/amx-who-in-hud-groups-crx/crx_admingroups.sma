#include <amxmodx>
#include <amxmisc>
#include <cromchat>
#include <formatin>

new const PLUGIN_VERSION[] = "1.2"
const NO_GROUP             = -1
const NOT_CONNECTED        = -2

enum
{
	SECTION_NONE,
	SECTION_SETTINGS,
	SECTION_GROUPS
}

enum _:Settings
{
	MENU_ACCESS,
	MENU_PERPAGE,
	MENU_SOUND[64],
	FLAGS_METHOD,
	bool:EXIT_TO_MAIN
}

enum _:Groups
{
	Name[32],
	Flags[32],
	ViewFlags[32]
}

new g_eSettings[Settings],
	Array:g_aGroups,
	g_iUserGroup[33],
	g_iCallback,
	g_iTotalGroups

public plugin_init()
{
	register_plugin("Admin Groups", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXAdminGroups", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("AdminGroups.txt")
	g_iCallback = menu_makecallback("Menu_CheckViewFlag")
}

public plugin_precache()
{
	g_aGroups = ArrayCreate(Groups)
	ReadFile()
}

public plugin_end()
{
	ArrayDestroy(g_aGroups)
}

ReadFile()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/AdminGroups.ini", szConfigsName)

	new iFilePointer = fopen(szFilename, "rt")

	if(iFilePointer)
	{
		new szData[96], szValue[64], szKey[32], iSection = SECTION_NONE, iSize
		new eGroup[Groups]

		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)

			switch(szData[0])
			{
				case EOS, ';', '#': continue
				case '[':
				{
					iSize = strlen(szData)

					if(szData[iSize - 1] == ']')
					{
						switch(szData[1])
						{
							case 'N', 'n': iSection = SECTION_NONE
							case 'S', 's': iSection = SECTION_SETTINGS
							case 'G', 'g': iSection = SECTION_GROUPS
							default: continue
						}
					}
					else continue
				}
				default:
				{
					if(iSection == SECTION_NONE)
					{
						continue
					}

					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)

					if(!szValue[0])
					{
						continue
					}

					switch(iSection)
					{
						case SECTION_SETTINGS:
						{
							if(equal(szKey, "MENU_COMMANDS"))
							{
								while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
								{
									trim(szKey); trim(szValue)

									switch(szKey[0])
									{
										case '/', '!':
										{
											register_clcmd(formatin("say %s", szKey), "Menu_Groups")
											register_clcmd(formatin("say_team %s", szKey), "Menu_Groups")
										}
										default:
										{
											register_clcmd(szKey, "Menu_Groups")
										}
									}
								}
							}
							else if(equal(szKey, "MENU_ACCESS"))
							{
								g_eSettings[MENU_ACCESS] = szValue[0] == '0' ? ADMIN_ALL : read_flags(szValue)
							}
							else if(equal(szKey, "CHAT_PREFIX"))
							{
								CC_SetPrefix(szValue)
							}
							else if(equal(szKey, "MENU_PERPAGE"))
							{
								g_eSettings[MENU_PERPAGE] = clamp(str_to_num(szValue), 0, 7)
							}
							else if(equal(szKey, "MENU_SOUND"))
							{
								copy(g_eSettings[MENU_SOUND], charsmax(g_eSettings[MENU_SOUND]), szValue)

								if(szValue[0])
								{
									precache_sound(szValue)
								}
							}
							else if(equal(szKey, "FLAGS_METHOD"))
							{
								g_eSettings[FLAGS_METHOD] = clamp(str_to_num(szValue), 0, 1)
							}
							else if(equal(szKey, "EXIT_TO_MAIN"))
							{
								g_eSettings[EXIT_TO_MAIN] =  _:clamp(str_to_num(szValue), false, true)
							}
						}
						case SECTION_GROUPS:
						{
							eGroup[ViewFlags][0] = EOS
							copy(eGroup[Name], charsmax(eGroup[Name]), szKey)
							parse(szValue, eGroup[Flags], charsmax(eGroup[Flags]), eGroup[ViewFlags], charsmax(eGroup[ViewFlags]))
							ArrayPushArray(g_aGroups, eGroup)
							g_iTotalGroups++
						}
					}
				}
			}
		}

		fclose(iFilePointer)
	}
}

public client_putinserver(id)
{
	update_user_group(id)
}

public client_infochanged(id)
{
	static szNewName[32], szOldName[32]
	get_user_info(id, "name", szNewName, charsmax(szNewName))
	get_user_name(id, szOldName, charsmax(szOldName))

	if(!equal(szNewName, szOldName))
	{
		set_task(0.1, "update_user_group", id)
	}
}

public Menu_Groups(id, bool:bWentBack)
{
	if(!bWentBack)
	{
		if(g_eSettings[MENU_ACCESS] != ADMIN_ALL && ~get_user_flags(id) & g_eSettings[MENU_ACCESS])
		{
			CC_SendMessage(id, "%L", id, "AGROUPS_NO_ACCESS")
			return PLUGIN_HANDLED
		}
	}

	new szTitle[128], szName[32], szGroup[32]
	get_user_name(id, szName, charsmax(szName))

	if(g_iUserGroup[id] == NO_GROUP)
	{
		formatex(szGroup, charsmax(szGroup), "%L", id, "AGROUPS_NO_GROUP")
	}
	else
	{
		get_user_group(id, szGroup, charsmax(szGroup))
	}

	formatex(szTitle, charsmax(szTitle), "%L", id, "AGROUPS_MENU_TITLE", szName, szGroup)
	replace_newline_characters(szTitle, charsmax(szTitle))

	static eGroup[Groups]
	new iMenu = menu_create(szTitle, "Groups_Handler")

	for(new i, iOnline; i < g_iTotalGroups; i++)
	{
		iOnline = get_players_in_group(i)
		ArrayGetArray(g_aGroups, i, eGroup)
		menu_additem(iMenu, formatin("%L", id, iOnline ? "AGROUPS_DISPLAY_ONLINE" : "AGROUPS_DISPLAY_OFFLINE", eGroup[Name], iOnline), .callback = g_iCallback)
	}

	if(!bWentBack)
	{
		play_menu_sound(id)
	}

	menu_setprop(iMenu, MPROP_PERPAGE, g_eSettings[MENU_PERPAGE])
	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public Menu_CheckViewFlag(id, iMenu, iItem)
{
	static eGroup[Groups]
	ArrayGetArray(g_aGroups, iItem, eGroup)
	return (!eGroup[ViewFlags][0] || has_required_flags(id, eGroup[ViewFlags])) ? ITEM_ENABLED : ITEM_DISABLED
}

public Groups_Handler(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}

	menu_destroy(iMenu)
	Menu_SubGroup(id, iItem)
	return PLUGIN_HANDLED
}

Menu_SubGroup(id, iGroup)
{
	new szTitle[128]
	static eGroup[Groups]
	ArrayGetArray(g_aGroups, iGroup, eGroup)
	formatex(szTitle, charsmax(szTitle), "%L", id, "AGROUPS_MENU2_TITLE", eGroup[Name], get_players_in_group(iGroup))
	replace_newline_characters(szTitle, charsmax(szTitle))

	new iPlayers[32], iPnum
	get_players(iPlayers, iPnum)

	new iMenu = menu_create(szTitle, "SubGroup_Handler")

	for(new i, iPlayer, szName[32]; i < iPnum; i++)
	{
		iPlayer = iPlayers[i]

		if(g_iUserGroup[iPlayer] == iGroup)
		{
			get_user_name(iPlayer, szName, charsmax(szName))
			menu_additem(iMenu, szName)
		}
	}

	if(!menu_items(iMenu))
	{
		menu_additem(iMenu, formatin("%L", id, "AGROUPS_NO_USERS"))
	}

	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public SubGroup_Handler(id, iMenu, iItem)
{
	menu_destroy(iMenu)

	if(g_eSettings[EXIT_TO_MAIN])
	{
		Menu_Groups(id, true)
	}

	return PLUGIN_HANDLED
}

public update_user_group(id)
{
	static eGroup[Groups]
	g_iUserGroup[id] = NO_GROUP

	for(new i; i < g_iTotalGroups; i++)
	{
		ArrayGetArray(g_aGroups, i, eGroup)

		if(has_required_flags(id, eGroup[Flags]))
		{
			g_iUserGroup[id] = i
			break
		}
	}

	return g_iUserGroup[id]
}

has_required_flags(const id, const szFlags[])
{
	return (g_eSettings[FLAGS_METHOD] == 1) ? has_all_flags(id, szFlags) : has_flag(id, szFlags)
}

get_user_group(const id, szGroup[], const iLen)
{
	if(g_iUserGroup[id] == NO_GROUP)
	{
		formatex(szGroup, iLen, "%L", id, "AGROUPS_NO_GROUP")
		return
	}

	static eGroup[Groups]
	ArrayGetArray(g_aGroups, g_iUserGroup[id], eGroup)
	copy(szGroup, iLen, eGroup[Name])
}

get_players_in_group(const iGroup)
{
	new iPlayers[32], iPnum, iCount
	get_players(iPlayers, iPnum)

	for(new i; i < iPnum; i++)
	{
		if(g_iUserGroup[iPlayers[i]] == iGroup)
		{
			iCount++
		}
	}

	return iCount
}

play_menu_sound(id)
{
	if(g_eSettings[MENU_SOUND][0])
	{
		client_cmd(id, "spk %s", g_eSettings[MENU_SOUND])
		return 1
	}

	return 0
}

replace_newline_characters(szString[], const iLen)
{
	replace_all(szString, iLen, "\n", "^n")
}

public plugin_natives()
{
	register_library("agroups.inc")
	register_native("agroups_get_groups_num", "_agroups_get_groups_num")
	register_native("agroups_get_players_in_group", "_agroups_get_players_in_group")
	register_native("agroups_get_user_group", "_agroups_get_user_group")
	register_native("agroups_open_groups_menu", "_agroups_open_groups_menu")
	register_native("agroups_play_menu_sound", "_agroups_play_menu_sound")
	register_native("agroups_update_user_group", "_agroups_update_user_group")
}

public _agroups_get_groups_num(iPlugin, iParams)
{
	return g_iTotalGroups
}

public _agroups_get_players_in_group(iPlugin, iParams)
{
	new iGroup = get_param(1)

	if(iGroup < 0 || iGroup > g_iTotalGroups)
	{
		return -1
	}

	return get_players_in_group(iGroup)
}

public _agroups_get_user_group(iPlugin, iParams)
{
	new id = get_param(1)

	if(!is_user_connected(id))
	{
		return NOT_CONNECTED
	}

	if(g_iUserGroup[id] == NO_GROUP)
	{
		set_string(2, formatin("%L", id, "AGROUPS_NO_GROUP"), get_param(3))
		return NO_GROUP
	}

	static eGroup[Groups]
	ArrayGetArray(g_aGroups, g_iUserGroup[id], eGroup)
	set_string(2, eGroup[Name], get_param(3))
	return g_iUserGroup[id]
}

public _agroups_open_groups_menu(iPlugin, iParams)
{
	new id = get_param(1)

	if(!is_user_connected(id))
	{
		return NOT_CONNECTED
	}

	Menu_Groups(id, false)
	return 1
}

public _agroups_play_menu_sound(iPlugin, iParams)
{
	new id = get_param(1)

	if(!is_user_connected(id))
	{
		return NOT_CONNECTED
	}

	return play_menu_sound(id)
}

public _agroups_update_user_group(iPlugin, iParams)
{
	new id = get_param(1)

	if(!is_user_connected(id))
	{
		return NOT_CONNECTED
	}

	return update_user_group(id)
}