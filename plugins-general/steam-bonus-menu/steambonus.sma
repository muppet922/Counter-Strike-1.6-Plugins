/******************************
*    	 .:: Credits ::.
*    	neugomon - author
*      roten - add UA lang
******************************/

#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>

// #### Начало Конфигурационные defines ####
#define CHATTAG "^3..::Steam Bonus::..^4"
#define MIN_MONEY 2500
#define MAX_MONEY 2500
#define MIN_HP 10
#define MAX_HP 10
#define STEAMBONUSROUND 3
//#define OPENMENUSOUND

new g_roundCount;

new const PRIMARY_WEAPONS_BITSUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
new const SECONDARY_WEAPONS_BITSUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);

public plugin_init()
{
	new sPref[][] = {"dm_", "awp_", "aim_", "35hp", "fy_"};
	new map[32]; get_mapname(map, charsmax(map));
	for(new i; i < sizeof sPref; i++)
	{
		if(containi(map, sPref[i]) != -1)
		{
			pause("ad");
			return;
		}
	}
	
	register_plugin("Steam Bonus", "2.0", "Neugomon")
	
	register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w");
	register_event("HLTV","eRoundStart","a","1=0","2=0");
		
	RegisterHam(Ham_Spawn, "player", "Player_Spawn", 1);
	
	register_menucmd(register_menuid("Steam Bonus Menu"), MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6, "SteamBonus");
}

public eRestart(id)
{
	g_roundCount = 0;
	
	show_menu(id, 0, "^n", 1)
}

public eRoundStart(id)
{
	g_roundCount++;
}

public Player_Spawn(id)
{
	if(g_roundCount < STEAMBONUSROUND)
		return 0;
		
	return SteamBonusMenu(id);
}

public SteamBonusMenu(id)
{	
	if(!is_user_steam(id)) return 0;
	
#if defined OPENMENUSOUND
	static OpenMenuSound[] = "buttons/blip2";
	client_cmd( id, "spk ^"%s^"", OpenMenuSound );
#endif
	
	static szMenu[512], iLen, iKey, Name[32];
	get_user_name(id, Name, charsmax(Name))
	
	iKey = MENU_KEY_6|MENU_KEY_5|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4;
	iLen = formatex(szMenu, 511, "\d[\rSTEAM BONUS MENU\d]^n\d[\rHello\r: \y%s\d]^n^n\r[\y1\r]\y Гроші^n\r[\y2\r]\y Броня+Шлем^n\r[\y3\r]\y Набір гранат^n\r[\y4\r]\y Зброю \rAK, M4, FM, AWP^n\r[\y5\r]\y Добавити \rHP \d[\yДо \r10HP\d]^n^n", Name);
	
	formatex(szMenu[iLen], 511 - iLen, "\r[\y6\r] [\yВідмовитись від бонусів\r]");
	
	return show_menu(id, iKey, szMenu, 15, "Steam Bonus Menu");
}

public SteamBonus(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			new iMoney = random_num(MIN_MONEY, MAX_MONEY);
			cs_set_user_money(id, cs_get_user_money(id) + iMoney);
			ChatColor(id, "%s Ви дістали бонус гроші за ^3Steam CS ^4в розмірі ^3%d$", CHATTAG, iMoney);
		}
		case 1:
		{
			cs_set_user_armor(id, 100, CsArmorType:2);
			ChatColor(id, "%s Ви дістали бонус за ^3Steam CS ^4Броню + Шлем", CHATTAG);
		}
		case 2:
		{
			give_item(id, "weapon_hegrenade");
			give_item(id, "weapon_flashbang");
			give_item(id, "weapon_smokegrenade");
			cs_set_user_bpammo(id, CSW_FLASHBANG, 2);
			ChatColor(id, "%s Ви дістали бонус за ^3Steam CS ^4Набір гранат", CHATTAG);
		}
		case 3:
		{
			WeaponRandom(id);
		}
		case 4:
		{
			new iHealth = random_num(MIN_HP, MAX_HP);
			set_user_health(id, get_user_health(id) + iHealth);
			ChatColor(id, "%s Ви дістали бонус за ^3Steam CS ^4Додано ^3%dHP", CHATTAG, iHealth);
		}
	}
	return PLUGIN_HANDLED;
}

public WeaponRandom(id)
{
	switch(random(4))
	{
	case 0: give_item_ex(id,"weapon_ak47",90,1)
	case 1: give_item_ex(id,"weapon_m4a1",90,1)
	case 2: give_item_ex(id,"weapon_awp",30,1)
	case 3: give_item_ex(id,"weapon_famas",90,1)
	}
	return PLUGIN_HANDLED;
}

stock give_item_ex(id,currWeaponName[],ammoAmount,dropFlag=0)
{
	static	weaponsList[32], weaponName[32], weaponsNum, currWeaponID;		
	currWeaponID = get_weaponid(currWeaponName);
	if(dropFlag)
	{	
		weaponsNum = 0;
		get_user_weapons(id,weaponsList,weaponsNum);
		for (new i;i < weaponsNum;i++)
		{
			if(((1 << currWeaponID) & PRIMARY_WEAPONS_BITSUM && (1 << weaponsList[i]) & PRIMARY_WEAPONS_BITSUM) | ((1 << currWeaponID) & SECONDARY_WEAPONS_BITSUM && (1 << weaponsList[i]) & SECONDARY_WEAPONS_BITSUM))
			{
				get_weaponname(weaponsList[i],weaponName,charsmax(weaponName));
				engclient_cmd(id,"drop",weaponName);
			}
		}
	}
	give_item(id,currWeaponName);
	cs_set_user_bpammo(id,currWeaponID,ammoAmount);
	ChatColor(id, "%s Ви дістали бонус за ^3Steam CS ^4Зброю: ^3%s", CHATTAG, currWeaponName[7]);
	return 1;
}

stock ChatColor(const id, const szMessage[], any:...)
{
	static szMsg[190], IdMsg; 
	vformat(szMsg, charsmax(szMsg), szMessage, 3);
	
	if(!IdMsg) IdMsg = get_user_msgid("SayText");
	
	message_begin(MSG_ONE, IdMsg, .player = id);
	write_byte(id);
	write_string(szMsg);
	message_end();
}

stock bool:is_user_steam(id)
{
	static dp_pointer;
	if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", id);
		server_exec();
		return (get_pcvar_num(dp_pointer) == 2) ? true : false;
	}
	return false;
}
