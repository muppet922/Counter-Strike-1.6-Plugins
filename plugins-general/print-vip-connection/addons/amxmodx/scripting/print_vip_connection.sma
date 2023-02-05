#include <amxmodx>

#define PVC_TASK_ID 318372

enum _:PlayerData
{
	Prefix[128],
	AuthID[MAX_AUTHID_LENGTH],
	Flag
}

new Array:g_ePlayerData;

enum _:ChatSettings
{
	Float:PrintDelay,
	SoundForPlayer,
	PlaySound[128],
	PrintMessage[128]
}

new g_eChatSettings[ChatSettings];

new g_iPrefixCount;

public plugin_precache()
{
	new szPath[128], iLen = get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	formatex(szPath[iLen], charsmax(szPath) - iLen, "/print_vip_connection/print_vip_connection.ini");

	new hFile = fopen(szPath, "rt");

	if(!hFile)
	{
		set_fail_state("Can't %s '%s'", file_exists(szPath) ? "read" : "find", szPath);
		return;
	}

	new szLine[256], szKey[64], szParam[128], pData[PlayerData];
	g_ePlayerData = ArrayCreate(PlayerData);

	while(!feof(hFile))
	{
		fgets(hFile, szLine, charsmax(szLine));
		trim(szLine);

		if(szLine[0] == ';')
			continue;

		if(parse(szLine, szKey, charsmax(szKey), szParam, charsmax(szParam)) != 2)
			continue;
		
		if(szKey[0] == EOS)
			continue;

		if(equali(szKey, "print_delay"))
		{
			g_eChatSettings[PrintDelay] = str_to_float(szParam);
			continue;
		}
		else if(equali(szKey, "sound_for_player"))
		{
			g_eChatSettings[SoundForPlayer] = str_to_num(szParam);
			continue;
		}
		else if(equali(szKey, "play_sound"))
		{
			g_eChatSettings[PlaySound] = szParam;
			precache_sound(szParam);
			continue;
		}

		UTIL_StrFixColors(szParam, charsmax(szParam));

		if(equali(szKey, "chat_message"))
		{
			g_eChatSettings[PrintMessage] = szParam;
			continue;
		}

		if(szKey[0] == 'S' || szKey[0] == 'V')
			copy(pData[AuthID], charsmax(pData[AuthID]), szKey);
		else
			pData[Flag] = read_flags(szKey);

		pData[Prefix] = szParam;

		ArrayPushArray(g_ePlayerData, pData);

		arrayset(pData, 0, sizeof(pData));
	}

	fclose(hFile);
}

public plugin_init()
{
	register_plugin("Print VIP Connection", "0.0.7", "Albertio");

	if(!(g_iPrefixCount = ArraySize(g_ePlayerData)))
		pause("d");
}

public client_putinserver(id)
{
	set_task(g_eChatSettings[PrintDelay], "PlayerConnectedPrint", id + PVC_TASK_ID);
}

public client_disconnected(id)
{
	remove_task(id + PVC_TASK_ID);
}

public PlayerConnectedPrint(id)
{
	id = id - PVC_TASK_ID;

	if(!is_user_connected(id))
		return;

	new szAuthID[MAX_AUTHID_LENGTH];
	get_user_authid(id, szAuthID, charsmax(szAuthID));
	
	for(new i, pData[PlayerData]; i < g_iPrefixCount; i++)
	{
		ArrayGetArray(g_ePlayerData, i, pData);

		if(equali(pData[AuthID], szAuthID) || get_user_flags(id) & pData[Flag])
		{
			UTIL_FormattedPrint(id, g_eChatSettings[PrintMessage], pData[Prefix]);
			return;
		}
	}
}

stock UTIL_StrFixColors(szStr[], iLen)
{
	replace_all(szStr, iLen, "!d", "^1");
	replace_all(szStr, iLen, "!t", "^3");
	replace_all(szStr, iLen, "!g", "^4");
}

stock UTIL_FormattedPrint(const id, const szStr[], const szPrefix[])
{
	new szMessage[128];
	copy(szMessage, charsmax(szMessage), szStr);

	replace_all(szMessage, charsmax(szMessage), "%nick%", fmt("%n", id));
	replace_all(szMessage, charsmax(szMessage), "%prefix%", fmt("%s", szPrefix));
	client_print_color(0, print_team_default, "%s", szMessage);

	if(g_eChatSettings[PlaySound][0] != EOS)
		client_cmd(g_eChatSettings[SoundForPlayer] ? id : 0, "spk %s", g_eChatSettings[PlaySound]);
}