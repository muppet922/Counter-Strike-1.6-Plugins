/*=============================================================================================
			 [ZPSp] Addon: XP System

	-> Description:
	This plugin will be turn your zombie plague into zombie plague xp, with rank etc

	-> How to use require level for a class/item/weapon:
	When plugin enables, will be add a level line in **zpsp_zombieclasses.ini**, **zpsp_humanclasses.ini**, **zpsp_extraitems.ini**
	and **zpsp_custom_weapons.ini** and you can change minimum level require for use this item/class/weapon

	-> Changelog:
		- Alpha (06/03/22): First release
		- Alpha (08/03/22): Added Upgrade System
		- 1.0: Official Release

	-> Cvars:
		- zp_xp_save_type "1" ; Save Data Type: (1 - Authid | 2 = Name | 3 = IP)
		- zp_xp_for_kill "20" ; Xp For Kill Zombies/Humans
		- zp_xp_for_kill_specials "30" ; Xp For Kill Zombies/Humans Specials
		- zp_xp_infect "20" ; Xp For Infect Players
		- zp_xp_damage_give "2" ; Xp for X damage
		- zp_xp_damage_needed "750" ; Needed damage for give xp by damage
		- zp_xp_vip_flag "b" ; Flag Acess to Bonus XP
		- zp_xp_vip_bonus_xp "10" ; Bonus XP Amount

	-> Credits:
		Supremache: For original RankSystem
		Perfect Scrash: For this plugin
=============================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fvault>
#include <hamsandwich>
#include <amx_settings_api>
#include <zombie_plague_special>

// Files
new const ZPSP_XP_CFG_FILE[] = "zpsp_configs/zpsp_xp_system.cfg" // Config file
new const VAULT_NAME[] = "zpsp_xp_system" // Vault File

// Defines/Conts
#define GetRankName(%1) g_mPlayerData[g_iPlayerLevel[%1]][m_szRankName]
#define MANAGE_ACESS ADMIN_ADMIN // Flag Y
#define MAX_BUFFER_STRING 250

enum { SND_LVL_UP = 0, SND_BUY_UP, SND_SELL_UP, SND_ERROR }

new const g_Sounds[][] = {
	"vox/doop.wav",
	"zpsp_xp/upgrade_purchase.wav",
	"zpsp_xp/upgrade_sell.wav",
	"zpsp_xp/upgrade_error.wav"
}

// Enums
enum _:eCommandSettings { iMenuType, iCommands[MAX_BUFFER_STRING], iFlags };
enum _:mData { m_szRankName[MAX_BUFFER_STRING], m_iRankXP };

// XP manager
#define MAXLEVEL (sizeof(g_mPlayerData)-1) // Dont Change
new const g_mPlayerData[][mData] = {
	{ "Newbie", 0 }, 
	{ "Killer", 90 }, 
	{ "Good Killer", 180 }, 
	{ "Super Killer", 300 }, 
	{ "Mega Killer", 450 }, 
	{ "Ultra Killer", 700 }, 
	{ "Xtreme Killer", 1200 }, 
	{ "Supernova", 1800 }, 
	{ "Monster", 2800 }, 
	{ "Professional", 4100 }, 
	{ "Builder", 5200 }, 
	{ "Pro Builder", 6000 }, 
	{ "Colonel", 6800 }, 
	{ "General", 8200 }, 
	{ "Private", 10200 }, 
	{ "Specialist", 12000 }, 
	{ "Corporal", 15000 }, 
	{ "Sargeant", 17500 }, 
	{ "Staff Sargeant", 20500 }, 
	{ "Warrant Officer", 25500 }, 
	{ "Chief Warrant Officer", 29000 }, 
	{ "Second Lieutenant", 35000 }, 
	{ "First Lieutenant", 46000 }, 
	{ "Captain", 58000 }, 
	{ "Major", 71000 }, 
	{ "Silver III", 85000 }, 
	{ "Silver II", 100000 }, 
	{ "Silver I", 116000 }, 
	{ "Silver Elite Master", 133000 }, 
	{ "Gold III", 151000 }, 
	{ "Gold II", 170000 }, 
	{ "Gold I", 190000 }, 
	{ "Gold Epic Master", 211000 }, 
	{ "Legendary KiLLeR", 233000 }, 
	{ "Diamond III", 256000 }, 
	{ "Diamond II", 280000 }, 
	{ "Diamond I", 305000 }, 
	{ "Diamond Rare Killer", 331000 }, 
	{ "Master III", 358000 }, 
	{ "Master II", 386000 }, 
	{ "Master I", 415000 }, 
	{ "EpiC Master", 445000 }, 
	{ "Terminator", 476000 }, 
	{ "KinG III", 508000 }, 
	{ "KinG II", 541000 }, 
	{ "KinG I", 575000 }, 
	{ "KinG Of Builders", 610000 }, 
	{ "KinG Of Server", 646000 }, 
	{ "Commander III", 683000 }, 
	{ "Commander II", 721000 }, 
	{ "Commander I", 760000 }, 
	{ "Pro Commander", 800000 }, 
	{ "Like a Boss", 842000 }, 
	{ "Respect", 886000 }, 
	{ "Advanced", 974000 }, 
	{ "Cs-Max Master", 1020000 }, 
	{ "Cs-Max Officer", 1068000 }, 
	{ "Top", 1118000 }, 
	{ "Top Gamer", 1170000 }, 
	{ "Pro Rank", 1224000 }, 
	{ "Predator", 1280000 }, 
	{ "Ace", 1338000 }, 
	{ "Conquer", 1398000 }, 
	{ "Global III", 1460000 }, 
	{ "Global II", 1524000 }, 
	{ "Global I", 1590000 }, 
	{ "Global Builder", 1658000 }, 
	{ "ProfessorX", 1728000 }, 
	{ "Doctor Strange", 1800000 }, 
	{ "Daredevil", 1874000 }, 
	{ "Unstoppable", 1950000 }
};

// Forwards
enum {
	FW_LEVEL_UP = 0,
	FW_UPGRADE_BUY_PRE,
	FW_UPGRADE_BUY_POST,
	FW_UPGRADE_SELL_PRE,
	FW_UPGRADE_SELL_POST,
	FW_UPGRADE_MENU_OPEN,
	MAX_FORWARDS
}
new g_forwards[MAX_FORWARDS], g_ReturnResult

// Variables
new g_iPlayerXP[33], g_iPlayerLevel[33], szPlayerAuthid[33][33], szPlayerName[33][33], szPlayerIP[33][33], g_iPlayerMenu[33], g_damagedealt[33], g_PageUpgrades[33]
new cvar_savetype, cvar_xp_kill, cvar_xp_kill_specials, cvar_xp_infect, cvar_vip_bonus_xp, cvar_vip_bonus_flag, cvar_xp_damage_give, cvar_xp_damage_needed;
new Array:g_ItemLevel, Array:g_ZombieClassLevel, Array:g_HumanClassLevel, Array:g_WpnPrimaryLevel, Array:g_WpnSecondaryLevel
new g_SaveType, g_VipFlag, g_HudSync, g_AdditionalText[MAX_BUFFER_STRING], g_AdditionalNote[500];
new Array:g_UpgradeName, Array:g_UpgradeDesc, Array:g_UpgradePriceHandler, Array:g_UpgradeSellHandler, Array:g_UpgradeMaxLevel, Array:g_UpgradeUseLang, Array:g_UpgradeVaultName, Array:g_PlayerUpgradeLevel[33], g_UpgradeCount

// Plugin Initializing
public plugin_init() {
	// Register Plugin
	register_plugin("[ZPSp] Addon: XP System", "1.0", "Supremache | Perf. Scrash");

	// Dictionary
	register_dictionary("zpsp_xp_system.txt")

	// Register Events
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)

	// Save Data Type: (1 - Authid | 2 = Name | 3 = IP)
	cvar_savetype = register_cvar("zp_xp_save_type", "1")
	
	// Register XP Cvars
	cvar_xp_kill = register_cvar("zp_xp_for_kill", "20");
	cvar_xp_kill_specials = register_cvar("zp_xp_for_kill_specials", "30");
	cvar_xp_infect = register_cvar("zp_xp_infect", "20");
	cvar_vip_bonus_flag = register_cvar("zp_xp_vip_flag", "b");
	cvar_vip_bonus_xp = register_cvar("zp_xp_vip_bonus_xp", "10");
	cvar_xp_damage_give = register_cvar("zp_xp_damage_give", "2");
	cvar_xp_damage_needed = register_cvar("zp_xp_damage_needed", "750");

	// Register Client Commands
	register_say_cmd("upgrade", "MenuUpgrades")
	register_say_cmd("upgrades", "MenuUpgrades")
	register_say_cmd("xp", "MainMenu")
	register_say_cmd("xplist", "ListXPs")
	register_say_cmd("resetdata", "ResetData", MANAGE_ACESS)
	register_say_cmd("manage", "ManageData", MANAGE_ACESS)
	register_concmd("amx_setlvl", "SetLevels", MANAGE_ACESS, " <player> <quantity>");
	register_concmd("amx_givexp", "GiveEXP", MANAGE_ACESS, " <player> <quantity>");
		
	// Forward
	g_forwards[FW_LEVEL_UP] = CreateMultiForward("zp_user_level_change", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_forwards[FW_UPGRADE_BUY_PRE] = CreateMultiForward("zp_upgrade_buy_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_forwards[FW_UPGRADE_BUY_POST] = CreateMultiForward("zp_upgrade_buy_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_forwards[FW_UPGRADE_SELL_PRE] = CreateMultiForward("zp_upgrade_sell_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_forwards[FW_UPGRADE_SELL_POST] = CreateMultiForward("zp_upgrade_sell_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_forwards[FW_UPGRADE_MENU_OPEN] = CreateMultiForward("zp_upgrade_menu_open", ET_CONTINUE, FP_CELL, FP_CELL);

	// Hud Sync
	g_HudSync = CreateHudSyncObj();
}

// Load Configs
public plugin_cfg() {
	static cfgdir[32]; get_configsdir(cfgdir, charsmax(cfgdir)) // Get configs dir
	server_cmd("exec %s/%s", cfgdir, ZPSP_XP_CFG_FILE) // Execute .cfg config file
	g_SaveType = get_pcvar_num(cvar_savetype)

	static flag[10]; get_pcvar_string(cvar_vip_bonus_flag, flag, charsmax(flag))
	g_VipFlag = read_flags(flag);

	// Load level Itens
	load_level_itens();
}

// Download Sound
public plugin_precache() {
	g_UpgradeName = ArrayCreate(MAX_BUFFER_STRING, 1)
	g_UpgradeDesc = ArrayCreate(MAX_BUFFER_STRING, 1)
	g_UpgradePriceHandler = ArrayCreate(1, 1)
	g_UpgradeSellHandler = ArrayCreate(1, 1)
	g_UpgradeMaxLevel = ArrayCreate(1, 1)
	g_UpgradeUseLang = ArrayCreate(1, 1)
	g_UpgradeVaultName = ArrayCreate(MAX_BUFFER_STRING, 1)

	new i;
	for(i = 0; i <= MaxClients; i++)
		g_PlayerUpgradeLevel[i] = ArrayCreate(1, 1)

	for(i = 0; i < sizeof g_Sounds; i++)
		precache_sound(g_Sounds[i])
}

/*--------------*
* NATIVES *
*---------------*/
public plugin_natives() {
	register_native("zp_get_user_xp", "_get_user_xp")
	register_native("zp_set_user_xp", "_set_user_xp")
	register_native("zp_get_user_max_xp", "_get_user_max_xp")
	register_native("zp_get_max_levels", "_get_max_levels")
	register_native("zp_get_user_level", "_get_user_level")
	register_native("zp_set_user_level", "_set_user_level")
	register_native("zp_get_user_rank", "_get_user_rank")
	register_native("zp_get_user_next_rank", "_get_user_next_rank")
	register_native("zp_register_upgrade", "_register_upgrade")
	register_native("zp_get_user_upgrade_lvl", "_get_user_upgrade_lvl")
	register_native("zp_set_user_upgrade_lvl", "_set_user_upgrade_lvl")
	register_native("zp_get_upgrade_max_lvl", "_get_upgrade_max_lvl")
	register_native("zp_upgrade_add_text", "_add_text")
	register_native("zp_upgrade_menu_add_note", "_add_note")
}

// Native: zp_get_user_xp
public _get_user_xp(iPlugin, iParams)
	return g_iPlayerXP[get_param(1)];

// Native: zp_set_user_xp
public _set_user_xp(iPlugin, iParams) {
	g_iPlayerXP[get_param(1)] = get_param(2);
	CheckLevel(get_param(1));
}

// Native: zp_get_user_level
public _get_user_level(iPlugin, iParams)
	return g_iPlayerLevel[get_param(1)];

// Native: zp_set_user_level
public _set_user_level(iPlugin, iParams) {
	g_iPlayerLevel[get_param(1)] = get_param(2);
	CheckLevel(get_param(1));
}

// Native: zp_get_user_max_xp
public _get_user_max_xp(iPlugin, iParams) {
	new iMaxLevel
	
	if(g_iPlayerLevel[get_param(1)] >= MAXLEVEL) 
		iMaxLevel = MAXLEVEL
	else
		iMaxLevel = g_mPlayerData[g_iPlayerLevel[get_param(1)] + 1][m_iRankXP]
	
	return iMaxLevel;
}

public _get_user_rank(iPlugin, iParams)
	set_string(2, GetRankName(get_param(1)), get_param(3));

public _get_user_next_rank(iPlugin, iParams)
	set_string(2, g_mPlayerData[g_iPlayerLevel[get_param(1)] +1][m_szRankName], get_param(3));

public _get_max_levels(iPlugin, iParams)
	return MAXLEVEL;

// native zp_register_upgrade(const name[], const description[], const price[], const sell_value[], MaxLevel, const vaultname[], UseLang = 0);
public _register_upgrade(plugin_id, num_params) {
	new name[MAX_BUFFER_STRING], Price[100], sell_value[100], MaxLevel, vaultname[MAX_BUFFER_STRING], UseLang, Description[MAX_BUFFER_STRING]

	MaxLevel = get_param(5);
	if(MaxLevel > 100 || MaxLevel < 1) {
		log_error(AMX_ERR_NATIVE, "[ZP] MaxLevel (%d) out of bounds. Recomended Value Between 1 and 100", MaxLevel)
		return -1
	}

	get_string(1, name, charsmax(name))
	get_string(2, Description, charsmax(Description))
	get_array(3, Price, MaxLevel)
	get_array(4, sell_value, MaxLevel)

	get_string(6, vaultname, charsmax(vaultname))
	UseLang = get_param(7)

	
	ArrayPushString(g_UpgradeName, name) // Name
	ArrayPushString(g_UpgradeDesc, Description) // Description
	ArrayPushCell(g_UpgradeUseLang, UseLang) // Use Lang

	// Price / Sell Value
	new Array:UpgradePrice, Array:SellValue, i
	UpgradePrice = ArrayCreate(1, 1)
	SellValue = ArrayCreate(1, 1)
	for(i = 0; i < MaxLevel; i++) {
		ArrayPushCell(UpgradePrice, Price[i]);
		ArrayPushCell(SellValue, sell_value[i]);
	}
	
	ArrayPushCell(g_UpgradePriceHandler, UpgradePrice)
	ArrayPushCell(g_UpgradeSellHandler, SellValue)

	ArrayPushCell(g_UpgradeMaxLevel, MaxLevel) // Max Level

	ArrayPushString(g_UpgradeVaultName, vaultname) // Vault name
	
	// Player Vars
	for(i = 1; i <= MaxClients; i++) {
		ArrayPushCell(g_PlayerUpgradeLevel[i], 0)
	}

	g_UpgradeCount++
	return (g_UpgradeCount-1);
}

// native zp_get_user_upgrade_lvl(index, upgrade_index);
public _get_user_upgrade_lvl(plugin_id, num_params) {
	new id, upgrade_index, CurLvl
	id = get_param(1);
	upgrade_index = get_param(2);

	if(!is_user_connected(id))
		return -1;

	CurLvl = ArrayGetCell(g_PlayerUpgradeLevel[id], upgrade_index);

	return CurLvl
}

// native zp_set_user_upgrade_lvl(index, upgrade_index, level);
public _set_user_upgrade_lvl(plugin_id, num_params) {
	new id, upgrade_index, new_lvl
	id = get_param(1);
	upgrade_index = get_param(2);
	new_lvl = get_param(3);

	if(!is_user_connected(id))
		return 0;

	ArraySetCell(g_PlayerUpgradeLevel[id], upgrade_index, new_lvl);
	return 1;
}

// native zp_get_upgrade_max_lvl(upgrade_index);
public _get_upgrade_max_lvl(plugin_id, num_params) {
	new upgrade_index
	upgrade_index = get_param(1);

	return (ArrayGetCell(g_UpgradeMaxLevel, upgrade_index));
}

public _add_text(plugin_id, num_params) {
	new Text[MAX_BUFFER_STRING]; get_string(1, Text, charsmax(Text))
	strcat(g_AdditionalText, Text, charsmax(g_AdditionalText))
}

public _add_note(plugin_id, num_params) {
	new Note[MAX_BUFFER_STRING]; get_string(1, Note, charsmax(Note))
	strcat(g_AdditionalNote, fmt("\w%L: %s^n", LANG_PLAYER, "ZP_MENU_NOTE", Note), charsmax(g_AdditionalNote))
}

/*--------------------------------*
* Client Info *
*--------------------------------*/
public client_putinserver(id) {
	get_user_name(id, szPlayerName[id], charsmax(szPlayerName[]));
	get_user_authid(id, szPlayerAuthid[id], charsmax(szPlayerAuthid[]));
	get_user_ip(id, szPlayerIP[id], charsmax(szPlayerIP[]), 1)

	if(!is_user_hltv(id) && !is_user_bot(id))
		LoadData(id);
}

public client_disconnected(id) {
	if(!is_user_hltv(id) && !is_user_bot(id))
		SaveData(id);

	g_damagedealt[id] = 0
	g_iPlayerXP[id] = 0
	g_iPlayerLevel[id] = 0
	g_PageUpgrades[id] = 0
}

public client_infochanged(id) {
	if(!is_user_connected(id)) 
		return PLUGIN_CONTINUE;

	get_user_info(id, "name", szPlayerName[id], charsmax(szPlayerName[]));
	
	return PLUGIN_CONTINUE;
}

/*--------------------------------*
* Class/Item/Weapon Level *
*--------------------------------*/
public zp_zombie_class_choosed_pre(id, classid) { // Zombie Class Level
	return check_class_item_level(id, classid, g_ZombieClassLevel);
}
public zp_human_class_choosed_pre(id, classid) { // Human Class Level
	return check_class_item_level(id, classid, g_HumanClassLevel);
}
public zp_extra_item_selected_pre(id, itemid) { // Extra Item Level
	return check_class_item_level(id, itemid, g_ItemLevel);
}
public zp_weapon_selected_pre(id, wpn_type, wpn_id) { // Player Weapon Level
	return check_class_item_level(id, wpn_id, (wpn_type == WPN_PRIMARY) ? g_WpnPrimaryLevel : g_WpnSecondaryLevel);
}
// Check Class/Item/Weapon Level
stock check_class_item_level(id, itemid, Array:Arr_Level) {
	// Prevent log error
	if(itemid < 0 || itemid >= ArraySize(Arr_Level))
		return PLUGIN_CONTINUE;
	
	static level
	level = ArrayGetCell(Arr_Level, itemid)
	if(g_iPlayerLevel[id] < level) {
		zp_menu_textadd(fmt("\r[%L %d]", id, "ZP_LEVEL", level))
		return ZP_PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

/*---------------*
* Hud *
*----------------*/
public zp_player_show_hud(id, target, SpHudType:hudtype) {	
	static xpnext
	if(target) {
		if(g_iPlayerLevel[target] >= MAXLEVEL)
			xpnext = g_mPlayerData[g_iPlayerLevel[target]][m_iRankXP] 
		else 
			xpnext = g_mPlayerData[g_iPlayerLevel[target]+1][m_iRankXP] 

		zp_add_hud_text(fmt("^n%L: %s - %L: %i / %i - %L: %i / %i", id, "ZP_RANK", GetRankName(target), id, "ZP_XP", g_iPlayerXP[target], xpnext, id, "ZP_LEVEL", g_iPlayerLevel[target], MAXLEVEL))
		return;
	}

	if(g_iPlayerLevel[id] >= MAXLEVEL)
		xpnext = g_mPlayerData[g_iPlayerLevel[id]][m_iRankXP] 
	else 
		xpnext = g_mPlayerData[g_iPlayerLevel[id]+1][m_iRankXP] 

	if(hudtype == HUD_DEFAULT || hudtype == HUD_CENTER || hudtype == HUD_UNDER_RADAR)
		zp_add_hud_text(fmt("^n[%L: %s]^n[%L: %i / %i]^n[%L: %i / %i]", id, "ZP_RANK", GetRankName(id), id, "ZP_XP", g_iPlayerXP[id], xpnext, id, "ZP_LEVEL", g_iPlayerLevel[id], MAXLEVEL))
	else if(hudtype == HUD_ANTRAX_STYLE || hudtype == HUD_CENTER_ANTRAX)
		zp_add_hud_text(fmt("^n[%L] [%i / %i] - [%L] [%i / %i]^n[%L] [%s]", id, "ZP_XP", g_iPlayerXP[id], xpnext, id, "ZP_LEVEL", g_iPlayerLevel[id], MAXLEVEL, id, "ZP_RANK", GetRankName(id)))
	else if(hudtype == HUD_CLASSIC)
		zp_add_hud_text(fmt("- %L: %s - %L: %i/%i - %L: %i/%i", id, "ZP_RANK", GetRankName(id), id, "ZP_XP", g_iPlayerXP[id], xpnext, id, "ZP_LEVEL", g_iPlayerLevel[id], MAXLEVEL))
}
/*---------------*
* Main Menu *
*----------------*/
public MainMenu(id) {
	if(!is_user_connected(id))
		return;

	static iMenu;
	iMenu = menu_create(fmt("%L %L", id, "ZP_XP_MENU_PREFIX", id, "ZP_XP_MAIN_MENU"), "MainMenuHandler")

	menu_additem(iMenu, fmt("\w%L", id, "MENU_ITEM_UPGRADES"), "1")
	menu_additem(iMenu, fmt("\w%L", id, "ZP_XP_MENU_LIST"), "2")

	if(get_user_flags(id) & MANAGE_ACESS) {
		menu_additem(iMenu, fmt("\w%L", id, "ZP_XP_MENU_MANAGE"), "3")
		menu_additem(iMenu, fmt("\w%L", id, "ZP_XP_MENU_RESET"), "4")
	}
	
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", id, "ZP_XP_MENU_EXIT"))
	menu_display(id, iMenu)
}

public MainMenuHandler(id, iMenu, iItem) {
	if(iItem != MENU_EXIT) {
		new iAccess, iCallback, iData[6], iName[64], key;
		menu_item_getinfo(iMenu, iItem, iAccess, iData, charsmax(iData), iName, charsmax(iName), iCallback);
	
		key = str_to_num(iData);
		switch(key) {
			case 1: MenuUpgrades(id);
			case 2: ListXPs(id);
			case 3: ManageData(id);
			case 4: ResetData(id);
		}
	}
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

/*---------------*
* Upgrades *
*----------------*/
new upgradeChoosed[33]
public MenuUpgrades(id) {
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;

	if(!g_UpgradeCount) {
		client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_XP_NO_UPGRADES");
		return PLUGIN_HANDLED
	}

	new UpgradeName[MAX_BUFFER_STRING], i, iMenu;
	iMenu = menu_create(fmt("%L %L", id, "ZP_XP_MENU_PREFIX", id, "ZP_XP_MENU_UPGRADES"), "MenuUpgradesHandler")
	for(i = 0; i < g_UpgradeCount; i++) {		
		ArrayGetString(g_UpgradeName, i, UpgradeName, charsmax(UpgradeName))
		if(ArrayGetCell(g_UpgradeUseLang, i))
			format(UpgradeName, charsmax(UpgradeName), "%L", id, UpgradeName)

		menu_additem(iMenu, fmt("\w%s", UpgradeName), fmt("%d", i))
	}
	menu_setprop(iMenu, MPROP_BACKNAME, fmt("%L", id, "ZP_XP_MENU_BACK"))
	menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%L", id, "ZP_XP_MENU_NEXT"))
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", id, "ZP_XP_MENU_EXIT"))

	g_PageUpgrades[id] = min(g_PageUpgrades[id], menu_pages(iMenu)-1)
	menu_display(id, iMenu, g_PageUpgrades[id])
	return PLUGIN_HANDLED
}

public MenuUpgradesHandler(id, iMenu, iItem) {
	if(!is_user_connected(id)) {
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}

	static menudummy; player_menu_info(id, menudummy, menudummy, g_PageUpgrades[id])

	if(iItem != MENU_EXIT) {
		new iAccess, iCallback, iData[6], iName[64];
		menu_item_getinfo(iMenu, iItem, iAccess, iData, charsmax(iData), iName, charsmax(iName), iCallback);
	
		upgradeChoosed[id] = str_to_num(iData);
		MenuBuyUpgrade(id);
	}
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public MenuBuyUpgrade(id) {
	if(!is_user_connected(id))
		return;

	new szText[500], Up_Index;
	szText = "";

	Up_Index = upgradeChoosed[id];

	g_AdditionalNote = ""
	ExecuteForward(g_forwards[FW_UPGRADE_MENU_OPEN], g_ReturnResult, id, Up_Index)

	if(g_ReturnResult >= ZP_PLUGIN_HANDLED) {
		MenuUpgrades(id);
		client_cmd(id, "spk %s", g_Sounds[SND_ERROR])
		return
	}

	new UpgradeName[MAX_BUFFER_STRING], Value, CurrentLevel, MaxLvl, Array:Arr_Value, Description[250], iMenu

	ArrayGetString(g_UpgradeName, Up_Index, UpgradeName, charsmax(UpgradeName))
	ArrayGetString(g_UpgradeDesc, Up_Index, Description, charsmax(Description))
	if(ArrayGetCell(g_UpgradeUseLang, Up_Index)) {
		format(UpgradeName, charsmax(UpgradeName), "%L", id, UpgradeName)
		format(Description, charsmax(Description), "%L", id, Description)
	}

	CurrentLevel = ArrayGetCell(g_PlayerUpgradeLevel[id], Up_Index)
	MaxLvl = ArrayGetCell(g_UpgradeMaxLevel, Up_Index)

	strcat(szText, fmt("%L %L^n^n", id, "ZP_XP_MENU_PREFIX", id, "ZP_XP_MENU_UPGRADES"), charsmax(szText))
	strcat(szText, fmt("\w%L^n", id, "ZP_UPGRADE_ITEM_NAME", UpgradeName), charsmax(szText))
	strcat(szText, fmt("\w%L^n", id, "ZP_UPGRADE_ITEM_LEVEL", CurrentLevel, MaxLvl), charsmax(szText))
	strcat(szText, fmt("\w%L^n^n", id, "ZP_UPGRADE_ITEM_DESC", Description), charsmax(szText))
	strcat(szText, fmt("\w%s\w^n", g_AdditionalNote), charsmax(szText))
	iMenu = menu_create(szText, "MenuBuyUpgradeHandler")
	
	g_AdditionalText = ""
	ExecuteForward(g_forwards[FW_UPGRADE_BUY_PRE], g_ReturnResult, id, Up_Index)
	if(CurrentLevel < MaxLvl) {
		Arr_Value = ArrayGetCell(g_UpgradePriceHandler, Up_Index)
		Value = ArrayGetCell(Arr_Value, CurrentLevel)
		
		if(g_ReturnResult >= ZP_PLUGIN_HANDLED || g_iPlayerXP[id] < Value)
			menu_additem(iMenu, fmt("\d%L \r[%d %L] %s", id, "ZP_ITEM_UPGRADE_BUY", Value, id, "ZP_XP", g_AdditionalText), "1", (1<<50))
		else 
			menu_additem(iMenu, fmt("\w%L \y[%d %L] %s", id, "ZP_ITEM_UPGRADE_BUY", Value, id, "ZP_XP", g_AdditionalText), "1")
	}
	else
		menu_additem(iMenu, fmt("\d%L \y[%L] %s", id, "ZP_ITEM_UPGRADE_BUY", id, "ZP_UPGRADE_MAX", g_AdditionalText), "1")

	g_AdditionalText = ""
	ExecuteForward(g_forwards[FW_UPGRADE_SELL_PRE], g_ReturnResult, id, Up_Index)
	if(CurrentLevel > 0) {
		Arr_Value = ArrayGetCell(g_UpgradeSellHandler, Up_Index)
		Value = ArrayGetCell(Arr_Value, CurrentLevel-1)
		
		if(g_ReturnResult >= ZP_PLUGIN_HANDLED)
			menu_additem(iMenu, fmt("\d%L \r[%d %L] %s", id, "ZP_ITEM_UPGRADE_SELL", Value, id, "ZP_XP", g_AdditionalText), "2", (1<<50))
		else 
			menu_additem(iMenu, fmt("\w%L \y[%d %L] %s", id, "ZP_ITEM_UPGRADE_SELL", Value, id, "ZP_XP", g_AdditionalText), "2")
	}
	else
		menu_additem(iMenu, fmt("\d%L \y[%L] %s", id, "ZP_ITEM_UPGRADE_SELL", id, "ZP_UPGRADE_MIN", g_AdditionalText), "2", (1<<50))

	menu_setprop(iMenu, MPROP_BACKNAME, fmt("%L", id, "ZP_XP_MENU_BACK"))
	menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%L", id, "ZP_XP_MENU_NEXT"))
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", id, "ZP_XP_MENU_EXIT"))

	menu_display(id, iMenu)
}

public MenuBuyUpgradeHandler(id, iMenu, iItem) {
	if(!is_user_connected(id)) {
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}

	if(iItem == MENU_EXIT) {
		MenuUpgrades(id);
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	new iAccess, iCallback, iData[6], iName[64], Up_Index, key;
	menu_item_getinfo(iMenu, iItem, iAccess, iData, charsmax(iData), iName, charsmax(iName), iCallback);
	key = str_to_num(iData);

	new UpgradeName[MAX_BUFFER_STRING], Value, CurrentLevel, MaxLvl, Array:Arr_Value;
	Up_Index = upgradeChoosed[id]

	ArrayGetString(g_UpgradeName, Up_Index, UpgradeName, charsmax(UpgradeName))
	if(ArrayGetCell(g_UpgradeUseLang, Up_Index)) {
		format(UpgradeName, charsmax(UpgradeName), "%L", id, UpgradeName)
	}

	CurrentLevel = ArrayGetCell(g_PlayerUpgradeLevel[id], Up_Index)
	MaxLvl = ArrayGetCell(g_UpgradeMaxLevel, Up_Index)
	
	if(key == 1) {
		ExecuteForward(g_forwards[FW_UPGRADE_BUY_PRE], g_ReturnResult, id, Up_Index)
		if(g_ReturnResult >= ZP_PLUGIN_HANDLED) {
			MenuBuyUpgrade(id);
			client_cmd(id, "spk %s", g_Sounds[SND_ERROR])
			menu_destroy(iMenu)
			return PLUGIN_HANDLED
		}
		if(CurrentLevel >= MaxLvl) {
			client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_XP_UPGRADE_MAX_BUY");
			MenuBuyUpgrade(id);
			client_cmd(id, "spk %s", g_Sounds[SND_ERROR])
			menu_destroy(iMenu)
			return PLUGIN_HANDLED
		}
		Arr_Value = ArrayGetCell(g_UpgradePriceHandler, Up_Index)
		Value = ArrayGetCell(Arr_Value, CurrentLevel)
		if(g_iPlayerXP[id] < Value) {
			client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_NOT_HAVE_ENGOUT_XP");
			MenuBuyUpgrade(id);
			client_cmd(id, "spk %s", g_Sounds[SND_ERROR])
			menu_destroy(iMenu)
			return PLUGIN_HANDLED
		}

		ArraySetCell(g_PlayerUpgradeLevel[id], Up_Index, CurrentLevel+1)
		RemoveXP(id, Value)
		ExecuteForward(g_forwards[FW_UPGRADE_BUY_POST], g_ReturnResult, id, Up_Index)
		client_cmd(id, "spk %s", g_Sounds[SND_BUY_UP])
		client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_UPGRADE_BUY_SUCCESS", UpgradeName, CurrentLevel+1);
	}
	else {
		ExecuteForward(g_forwards[FW_UPGRADE_SELL_PRE], g_ReturnResult, id, Up_Index)
		if(g_ReturnResult >= ZP_PLUGIN_HANDLED) {
			MenuBuyUpgrade(id);
			menu_destroy(iMenu)
			client_cmd(id, "spk %s", g_Sounds[SND_ERROR])
			return PLUGIN_HANDLED
		}
		if(CurrentLevel <= 0) {
			client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_XP_UPGRADE_MAX_SELL");
			MenuBuyUpgrade(id);
			menu_destroy(iMenu)
			client_cmd(id, "spk %s", g_Sounds[SND_ERROR])
			return PLUGIN_HANDLED
		}

		Arr_Value = ArrayGetCell(g_UpgradeSellHandler, Up_Index)
		Value = ArrayGetCell(Arr_Value, CurrentLevel-1)

		ArraySetCell(g_PlayerUpgradeLevel[id], Up_Index, CurrentLevel-1)
		AddXP(id, Value, 0)
		ExecuteForward(g_forwards[FW_UPGRADE_SELL_POST], g_ReturnResult, id, Up_Index)
		client_cmd(id, "spk %s", g_Sounds[SND_SELL_UP])
		client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_UPGRADE_SELL_SUCCESS", UpgradeName, CurrentLevel-1);
	}
	SaveUpgrades(id, Up_Index);
	CheckLevel(id)
	MenuBuyUpgrade(id);
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

/*---------------*
* Custom Menu *
*----------------*/
public ListXPs(id) {
	g_iPlayerMenu[id] = 1
	PlayerRank(id, ADMIN_ALL)
}
public ResetData(id) {
	g_iPlayerMenu[id] = 2
	PlayerRank(id, MANAGE_ACESS)
}

public ManageData(id) {
	g_iPlayerMenu[id] = 3
	PlayerRank(id, MANAGE_ACESS)
}

public PlayerRank(id, iFlag) {
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;

	if(!access(id, iFlag)) {
		client_print_color(id, print_team_default, "%L %L", id, "ZP_XP_PREFIX", id, "ZP_XP_NOACESS");
		return PLUGIN_HANDLED
	}
			
	new iPlayers[32], iPnum, szTitle[128], iMenu 
	
	switch (g_iPlayerMenu[id]) {
		case 2: 
			formatex(szTitle, charsmax(szTitle), "%L %L", id, "ZP_XP_MENU_PREFIX", id, "ZP_XP_MENU_RESET")
		case 3: 
			formatex(szTitle, charsmax(szTitle), "%L %L", id, "ZP_XP_MENU_PREFIX", id, "ZP_XP_MENU_MANAGE")
		default: 
			formatex(szTitle, charsmax(szTitle), "%L %L", id, "ZP_XP_MENU_PREFIX", id, "ZP_XP_MENU_LIST")
	}
	
	iMenu = menu_create(szTitle, "Handler")
	get_players(iPlayers, iPnum, "ch"); SortCustom1D(iPlayers, iPnum, "sort_players_by_xp")
	
	for(new szItem[1024], iPlayer, i; i < iPnum; i++) {
		iPlayer = iPlayers[i]
		formatex(szItem, charsmax(szItem), "\d[%i %L] \w%s \r[\y%L %i: %s\r]", g_iPlayerXP[iPlayer], id, "ZP_XP", szPlayerName[iPlayer], id, "ZP_LEVEL", g_iPlayerLevel[iPlayer], GetRankName(iPlayer));
		menu_additem(iMenu, szItem, fmt("%d", iPlayer))
	}
	
	menu_setprop(iMenu, MPROP_BACKNAME, fmt("%L", id, "ZP_XP_MENU_BACK"))
	menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%L", id, "ZP_XP_MENU_NEXT"))
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", id, "ZP_XP_MENU_EXIT"))

	menu_display(id, iMenu)
	return PLUGIN_HANDLED
}

public sort_players_by_xp(id1, id2) {
	return g_iPlayerXP[id2] - g_iPlayerXP[id1]
}

public Handler(id, iMenu, iItem) {
	if(iItem != MENU_EXIT && is_user_connected(id)) {
		new iAccess, iCallback, iData[6], iName[64];
		menu_item_getinfo(iMenu, iItem, iAccess, iData, charsmax(iData), iName, charsmax(iName), iCallback);
	
		new iPlayer = str_to_num(iData);
		
		switch (g_iPlayerMenu[id]) {
			case 2: 
				ResetPlayerRank(id, iPlayer);
			case 3: 
				ManagePlayerRank(id, iPlayer);
		}
	}
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public ResetPlayerRank(id, iPlayer) {
	if(!iPlayer)
		return PLUGIN_HANDLED;
	
	g_iPlayerXP[iPlayer] = 0
	g_iPlayerLevel[iPlayer] = 0

	new szKey[64], VaultName[MAX_BUFFER_STRING];

	switch(g_SaveType) {
		case 2: 
			formatex(szKey, charsmax(szKey), "%s-NAME", szPlayerName[iPlayer])
		case 3: 
			formatex(szKey, charsmax(szKey), "%s-IP", szPlayerIP[iPlayer])
		default: 
			formatex(szKey, charsmax(szKey), "%s-ID", szPlayerAuthid[iPlayer])
	}

	fvault_remove_key(VAULT_NAME, szKey) // Remove XP info

	// Reset Upgrades
	for(new i = 0; i < g_UpgradeCount; i++) {
		ArraySetCell(g_PlayerUpgradeLevel[iPlayer], i, 0) 
		ArrayGetString(g_UpgradeVaultName, i, VaultName, charsmax(VaultName))
		fvault_remove_key(VaultName, szKey)
	}

	Log("%L", LANG_SERVER, "ZP_XP_ADM_RESET_LOG", szPlayerName[id], szPlayerAuthid[id], szPlayerName[iPlayer], szPlayerAuthid[iPlayer]);
	client_print_color(0, print_team_default, "%L", LANG_PLAYER, "ZP_XP_ADM_RESET", szPlayerName[id], szPlayerName[iPlayer]);
	
	SaveData(iPlayer);
	return PLUGIN_CONTINUE;
}

public ManagePlayerRank(id, iPlayer) {
	if(!is_user_connected(id))
		return;

	new szTitle[128], iMenu;
	formatex(szTitle, charsmax(szTitle), "%L %L", id, "ZP_XP_MENU_PREFIX", id, "ZP_XP_MENU_MANAGE")
	
	iMenu = menu_create(szTitle, "Rank_Handler");
	
	for(new i = 0; i <= MAXLEVEL; i++) {
		menu_additem(iMenu, fmt("%s \r[%L %d]", g_mPlayerData[i][m_szRankName], id, "ZP_LEVEL", i), fmt("%d %d", iPlayer, i));
	}	
	menu_display(id, iMenu);
}

public Rank_Handler(id, iMenu, iItem) {
	if(iItem != MENU_EXIT) {
		new iAccess, iCallback, iData[20], iName[64], szPlayer[10], szLevel[10], iLvl, iTarget;
		menu_item_getinfo(iMenu, iItem, iAccess, iData, charsmax(iData), iName, charsmax(iName), iCallback);

		parse(iData, szPlayer, charsmax(szPlayer), szLevel, charsmax(szLevel))
		iTarget = str_to_num(szPlayer);
		iLvl = str_to_num(szLevel);
	
		g_iPlayerXP[iTarget] = g_mPlayerData[iLvl][m_iRankXP];
		g_iPlayerLevel[iTarget] = iLvl;
		client_cmd(iTarget, "spk %s", g_Sounds[SND_LVL_UP])
		SaveData(iTarget)
	
		Log("%L", LANG_SERVER, "ZP_XP_ADM_SET_LVL_LOG", szPlayerName[id], szPlayerAuthid[id], szPlayerName[iTarget], szPlayerAuthid[iTarget], g_iPlayerLevel[iTarget], GetRankName(iTarget));
		client_print_color(iTarget, print_team_default, "%L", iTarget, "ZP_XP_ADM_SET_LVL", szPlayerName[id], szPlayerName[iTarget], g_iPlayerLevel[iTarget], GetRankName(iTarget));
	}
	menu_destroy(iMenu)
}	

/*---------------*
* Cmds *
*----------------*/
// Give XP
public GiveEXP(id, nLevel, nCid) {
	if(!cmd_access(id, nLevel, nCid, 1)) 
		return PLUGIN_HANDLED
	
	static cTarget[32], cXP[6], iTarget, iXP
	
	read_argv(1, cTarget, charsmax(cTarget));
	read_argv(2, cXP, charsmax(cXP));
	
	iXP = str_to_num(cXP);
	
	iTarget = cmd_target(id, cTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);

	if(!cTarget[0] || !cXP[0]) {
		console_print(id, "%L", id, "ZP_XP_CMD_ERROR1");
		return PLUGIN_HANDLED
	}
	
	if(!iTarget) {
		console_print(id, "%L", id, "ZP_XP_CMD_ERROR2");
		return PLUGIN_HANDLED
	}
	
	AddXP(iTarget, iXP, 0)
	console_print(id, "%L", id, "ZP_XP_ADM_GIVE_XP_LOG", szPlayerName[id], szPlayerAuthid[id], iXP, szPlayerName[iTarget], szPlayerAuthid[iTarget]);
	Log("%L", LANG_SERVER, "ZP_XP_ADM_GIVE_XP_LOG", szPlayerName[id], szPlayerAuthid[id], iXP, szPlayerName[iTarget], szPlayerAuthid[iTarget]);
	
	client_print_color(0, print_team_default, "%L", LANG_PLAYER, "ZP_XP_ADM_GIVE_XP", szPlayerName[id], iXP, szPlayerName[iTarget]);
	client_print_color(iTarget, print_team_default, "%L %L ", iTarget, "ZP_XP_PREFIX", iTarget, "ZP_XP_REACHED", g_iPlayerXP[iTarget], g_mPlayerData[g_iPlayerLevel[iTarget]+ 1][m_iRankXP]);
		
	return PLUGIN_HANDLED
}

// Set Level
public SetLevels(id, nLevel, nCid) {
	if(!cmd_access(id, nLevel, nCid, 1))
		return PLUGIN_HANDLED
	
	static cTarget[32], cLevel[6], iTarget, iLevel
	
	read_argv(1, cTarget, charsmax(cTarget));
	read_argv(2, cLevel, charsmax(cLevel));
	
	iLevel = str_to_num(cLevel);
	
	iTarget = cmd_target(id, cTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS);

	if(!cTarget[0] || !cLevel[0]) {
		console_print(id, "%L", id, "ZP_XP_CMD_ERROR3");
		return PLUGIN_HANDLED
	}
	
	if(!iTarget) {
		console_print(id, "%L", id, "ZP_XP_CMD_ERROR2");
		return PLUGIN_HANDLED
	}
	
	if(iLevel > MAXLEVEL)
		iLevel = MAXLEVEL

	if(iLevel < 0)
		iLevel = 0
	
	g_iPlayerLevel[iTarget] = iLevel
	g_iPlayerXP[iTarget] = g_mPlayerData[g_iPlayerLevel[iTarget]][m_iRankXP] 
	client_cmd(iTarget, "spk %s", g_Sounds[SND_LVL_UP])
	SaveData(iTarget)
	
	console_print(id, "%L", id, "ZP_XP_ADM_SET_LVL_LOG", szPlayerName[id], szPlayerAuthid[id], szPlayerName[iTarget], szPlayerAuthid[iTarget], iLevel, GetRankName(iTarget));
	Log("%L", LANG_SERVER, "ZP_XP_ADM_SET_LVL_LOG", szPlayerName[id], szPlayerAuthid[id], szPlayerName[iTarget], szPlayerAuthid[iTarget], iLevel, GetRankName(iTarget));
	
	client_print_color(iTarget, print_team_default, "%L", iTarget, "ZP_XP_ADM_SET_LVL", szPlayerName[id], szPlayerName[iTarget], g_iPlayerLevel[iTarget], GetRankName(iTarget));
	client_print_color(iTarget, print_team_default, "%L %L", iTarget, "ZP_XP_PREFIX", iTarget, "ZP_RANK_REACHED", GetRankName(iTarget), g_iPlayerLevel[iTarget]);
		
	return PLUGIN_HANDLED
		
}

/*---------------*
* Rewards *
*----------------*/
// Killed Reward
public fw_PlayerKilled_Post(victim, attacker) {
	if(attacker == victim || !is_user_connected(attacker) || !is_user_connected(victim))
		return HAM_IGNORED;
	
	static XPAmount
	if(zp_get_human_special_class(victim) || zp_get_zombie_special_class(victim))
		XPAmount = get_pcvar_num(cvar_xp_kill_specials);
	else
		XPAmount = get_pcvar_num(cvar_xp_kill);

	AddXP(attacker, XPAmount)
	return HAM_IGNORED;
}
// Damage Reward
public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type) { // Ham Take Damage Forward
	if(!is_user_alive(victim))
		return HAM_IGNORED;

	new DmgGive = get_pcvar_num(cvar_xp_damage_give)
	new DmgNeeded = get_pcvar_num(cvar_xp_damage_needed)

	if(victim == attacker || isSameTeam(attacker, victim) || DmgNeeded <= 0 || DmgGive <= 0)
		return HAM_IGNORED;

	g_damagedealt[attacker] += floatround(damage)

	// Give rewards according to damage dealt [Like in zp 5.0]
	new how_many_rewards = g_damagedealt[attacker] / DmgNeeded
	
	if(how_many_rewards > 10)
		how_many_rewards = 10; // Limiting to prevent farm

	if(how_many_rewards > 0) {
		AddXP(attacker, DmgGive * how_many_rewards, 0)
		g_damagedealt[attacker] = 0
	}
	return HAM_IGNORED;
}

// Infect Reward
public zp_user_infected_post(victim, infector) {
	if(infector == victim || !is_user_connected(infector) || !is_user_connected(victim))
		return;

	AddXP(infector, get_pcvar_num(cvar_xp_infect))
}

// Disinfect Reward (Example: if you disinfect zombie with antidoter weapon)
public zp_user_humanized_post(victim, classid, attacker) {
	if(attacker == victim || !is_user_connected(attacker) || !is_user_connected(victim))
		return;

	AddXP(attacker, get_pcvar_num(cvar_xp_infect))
}

/*---------------*
* Check Levels *
*----------------*/
public CheckLevel(iPlayer) {
	if(g_iPlayerLevel[iPlayer] >= MAXLEVEL) {
		SaveData(iPlayer)
		return;
	}
	
	while(g_iPlayerXP[iPlayer] >= g_mPlayerData[g_iPlayerLevel[iPlayer]+1][m_iRankXP]) {
		g_iPlayerLevel[iPlayer]++;
		client_cmd(iPlayer, "spk %s", g_Sounds[SND_LVL_UP])
		ExecuteForward(g_forwards[FW_LEVEL_UP], g_ReturnResult, iPlayer, g_iPlayerLevel[iPlayer], g_iPlayerXP[iPlayer])
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "ZP_XP_PREFIX", LANG_PLAYER, "ZP_XP_PROMOTED", szPlayerName[iPlayer], g_iPlayerLevel[iPlayer], GetRankName(iPlayer));
	}
	SaveData(iPlayer)
}
			
/*---------------*
* SAVE/LOAD Data *
*----------------*/
stock SaveData(id) {
	new szKey[64], szData[256];

	switch(g_SaveType) {
		case 2: 
			formatex(szKey, charsmax(szKey), "%s-NAME", szPlayerName[id])
		case 3: 
			formatex(szKey, charsmax(szKey), "%s-IP", szPlayerIP[id])
		default: 
			formatex(szKey, charsmax(szKey), "%s-ID", szPlayerAuthid[id])
	}
	
	formatex(szData, charsmax(szData), "%i#%i#", g_iPlayerLevel[id], g_iPlayerXP[id])
	fvault_set_data(VAULT_NAME, szKey, szData)
}

stock SaveUpgrades(id, Up_Index) {
	new szKey[64], CurrentLevel, VaultName[MAX_BUFFER_STRING]
	switch(g_SaveType) {
		case 2: 
			formatex(szKey, charsmax(szKey), "%s-NAME", szPlayerName[id])
		case 3: 
			formatex(szKey, charsmax(szKey), "%s-IP", szPlayerIP[id])
		default: 
			formatex(szKey, charsmax(szKey), "%s-ID", szPlayerAuthid[id])
	}

	CurrentLevel = ArrayGetCell(g_PlayerUpgradeLevel[id], Up_Index)
	ArrayGetString(g_UpgradeVaultName, Up_Index, VaultName, charsmax(VaultName))
	fvault_set_data(VaultName, szKey, fmt("%d", CurrentLevel))
}

stock LoadData(id) {
	new szKey[64], szData[256], szXP[32], szLevel[32];
	
	switch(g_SaveType) {
		case 2: 
			formatex(szKey, charsmax(szKey), "%s-NAME", szPlayerName[id]);
		case 3: 
			formatex(szKey, charsmax(szKey), "%s-IP", szPlayerIP[id]);
		default: 
			formatex(szKey, charsmax(szKey), "%s-ID", szPlayerAuthid[id]);
	}
	
	//formatex(szData, charsmax(szData), "%i#%i#", g_iPlayerLevel[id], g_iPlayerXP[id])
	if(fvault_get_data(VAULT_NAME, szKey, szData, charsmax(szData))) {
		replace_string(szData, charsmax(szData), "#", " ")
		parse(szData, szLevel, charsmax(szLevel), szXP, charsmax(szXP))
		g_iPlayerLevel[id] = str_to_num(szLevel)
		g_iPlayerXP[id] = str_to_num(szXP)
	}

	new VaultName[MAX_BUFFER_STRING], MaxLevel, Level, szData2[10]
	for(new i = 0; i < g_UpgradeCount; i++) {
		szData2[0] = 0

		ArrayGetString(g_UpgradeVaultName, i, VaultName, charsmax(VaultName))
		if(fvault_get_data(VaultName, szKey, szData2, charsmax(szData2)))
			Level = str_to_num(szData2)
		else 
			Level = 0

		MaxLevel = ArrayGetCell(g_UpgradeMaxLevel, i);
		if(Level > MaxLevel)
			Level = MaxLevel

		if(Level < 0)
			Level = 0
	
		ArraySetCell(g_PlayerUpgradeLevel[id], i, Level)
	}
}


/*--------------*
* Load Itens *
*---------------*/
// Load Level Class/Itens/Weapons
public load_level_itens() {
	// Create Arrays
	g_ItemLevel = ArrayCreate(1, 1)
	g_ZombieClassLevel = ArrayCreate(1, 1)
	g_HumanClassLevel = ArrayCreate(1, 1)
	g_WpnPrimaryLevel = ArrayCreate(1, 1)
	g_WpnSecondaryLevel = ArrayCreate(1, 1)

	static index, count, real_name[32], level, start, Array:Temp_Array, loaded

	// Zombie Class Level
	count = zp_get_zclass_count()
	for (index = 0; index < count; index++) {
		zp_get_zombie_class_realname(index, real_name, charsmax(real_name))
		
		level = 0
		if(!amx_load_setting_int(ZP_ZOMBIECLASSES_FILE, real_name, "LEVEL", level))
			amx_save_setting_int(ZP_ZOMBIECLASSES_FILE, real_name, "LEVEL", level)

		ArrayPushCell(g_ZombieClassLevel, level)
	}

	// Human Class Level
	count = zp_get_hclass_count()
	for (index = 0; index < count; index++) {
		zp_get_human_class_realname(index, real_name, charsmax(real_name))
		
		level = 0
		if(!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "LEVEL", level))
			amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "LEVEL", level)

		ArrayPushCell(g_HumanClassLevel, level)
	}

	// Extra Item
	count = zp_get_extra_item_count()
	start = zp_get_custom_extra_start()
	Temp_Array = ArrayCreate(1, 1)
	loaded = amx_load_setting_int_arr(ZP_CUSTOMIZATION_FILE, "Extra Items: Weapons and their costs", "LEVEL ITENS", Temp_Array)
	for (index = 0; index < count; index++) {
		zp_get_extra_item_realname(index, real_name, charsmax(real_name))

		level = 0	
		if(index < EXTRA_WEAPONS_STARTID) {
			strtoupper(real_name)
			if (!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Hard Coded Items Costs", fmt("%s LEVEL", real_name), level))
				amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Hard Coded Items Costs", fmt("%s LEVEL", real_name), level)
		}	
		else if(index < start) {
			if(!loaded) {
				ArrayPushCell(Temp_Array, 0)
				if((index + 1) >= start) {
					amx_save_setting_int_arr(ZP_CUSTOMIZATION_FILE, "Extra Items: Weapons and their costs", "LEVEL ITENS", Temp_Array)
					ArrayDestroy(Temp_Array)
				}
			}
			else {
				level = ArrayGetCell(Temp_Array, index-EXTRA_WEAPONS_STARTID)
			}
		}
		else {
			if (!amx_load_setting_int(ZP_EXTRAITEMS_FILE, real_name, "LEVEL", level))
				amx_save_setting_int(ZP_EXTRAITEMS_FILE, real_name, "LEVEL", level)
		}
		
		ArrayPushCell(g_ItemLevel, level)
	}
	
	// Player Primary Weapons (Include Main Plugin Player Weapons)
	count = zp_weapon_count(WPN_PRIMARY, 0)
	start = zp_weapon_count(WPN_PRIMARY, 2)
	Temp_Array = ArrayCreate(1, 1)
	loaded = amx_load_setting_int_arr(ZP_CUSTOMIZATION_FILE, "Buy Menu Weapons", "PRIMARY LEVELS", Temp_Array)
	for (index = 0; index < count; index++) {
		zp_get_weapon_realname(WPN_PRIMARY, index, real_name, charsmax(real_name))
		
		level = 0

		if(index >= start) {
			format(real_name, charsmax(real_name), "Pri:%s", real_name)
			if (!amx_load_setting_int(ZP_WEAPONS_FILE, real_name, "LEVEL", level))
				amx_save_setting_int(ZP_WEAPONS_FILE, real_name, "LEVEL", level)
		}
		else {
			if(!loaded) {
				ArrayPushCell(Temp_Array, 0)
				if((index + 1) >= start) {
					amx_save_setting_int_arr(ZP_CUSTOMIZATION_FILE, "Buy Menu Weapons", "PRIMARY LEVELS", Temp_Array)
					ArrayDestroy(Temp_Array)
				}
			}
			else {
				level = ArrayGetCell(Temp_Array, index)
			}
		}
		
		ArrayPushCell(g_WpnPrimaryLevel, level)
	}
	
	// Player Secondary Weapons (Include Main Plugin Player Weapons)
	count = zp_weapon_count(WPN_SECONDARY, 0)
	start = zp_weapon_count(WPN_SECONDARY, 2)
	Temp_Array = ArrayCreate(1, 1)
	loaded = amx_load_setting_int_arr(ZP_CUSTOMIZATION_FILE, "Buy Menu Weapons", "SECONDARY LEVELS", Temp_Array)
	for (index = 0; index < count; index++) {
		zp_get_weapon_realname(WPN_SECONDARY, index, real_name, charsmax(real_name))
		level = 0		

		if(index >= start) {
			format(real_name, charsmax(real_name), "Sec:%s", real_name)
			if (!amx_load_setting_int(ZP_WEAPONS_FILE, real_name, "LEVEL", level))
				amx_save_setting_int(ZP_WEAPONS_FILE, real_name, "LEVEL", level)
		}
		else {
			if(!loaded) {
				ArrayPushCell(Temp_Array, 0)
				if((index + 1) >= start) {
					amx_save_setting_int_arr(ZP_CUSTOMIZATION_FILE, "Buy Menu Weapons", "SECONDARY LEVELS", Temp_Array)
					ArrayDestroy(Temp_Array)
				}
			}
			else {
				level = ArrayGetCell(Temp_Array, index)
			}
		}
		
		ArrayPushCell(g_WpnSecondaryLevel, level)
	}
}


/*--------------*
* STOCKS *
*---------------*/
stock Log(const message_fmt[], any:...) {
	static message[256];
	vformat(message, charsmax(message), message_fmt, 2);
	
	static filename[96], log_file[64];
	static dir[64];
	if(!dir[0]) {
		get_basedir(dir, charsmax(dir));
		add(dir, charsmax(dir), "/logs");
	}
	
	format_time(filename, charsmax(filename), "%m-%d-%Y");
	formatex(log_file, charsmax(log_file), "%s/zpsp_xp_system_%s.log", dir, filename); /* Much faster than what format() can do */
	log_to_file(log_file, "%s", message);
}

stock register_say_cmd(szsay[], szfunction[], flags = -1)
{
	register_clcmd(fmt("say /%s", szsay), szfunction, flags);
	register_clcmd(fmt("say .%s", szsay), szfunction, flags);
	register_clcmd(fmt("say %s", szsay), szfunction, flags);
	register_clcmd(fmt("say_team /%s", szsay), szfunction, flags);
	register_clcmd(fmt("say_team %s", szsay), szfunction, flags);
	register_clcmd(fmt("say_team .%s", szsay), szfunction, flags);
}
stock isSameTeam(id1, id2) {
	if(!is_user_connected(id1) || !is_user_connected(id2))
		return 0;

	static IsZombie_1, IsZombie_2
	IsZombie_1 = zp_get_user_zombie(id1)
	IsZombie_2 = zp_get_user_zombie(id2)

	if(IsZombie_1 && IsZombie_2 || !IsZombie_1 && !IsZombie_2)
		return 1;

	return 0;
}

stock AddXP(id, amount, bonus=1) {
	if(!is_user_connected(id))
		return;

	if(bonus && (get_user_flags(id) & g_VipFlag))
		amount += get_pcvar_num(cvar_vip_bonus_xp)

	set_hudmessage(0, 255, 50, random_float(0.30, 0.70), random_float(0.30, 0.50), 1, 3.0, 3.0)
	ShowSyncHudMsg(id, g_HudSync, "+%d %L", amount, id, "ZP_XP")

	g_iPlayerXP[id] += amount;
	CheckLevel(id);
}

stock RemoveXP(id, amount) {
	if(!is_user_connected(id))
		return;

	set_hudmessage(0, 255, 50, random_float(0.30, 0.70), random_float(0.30, 0.50), 1, 3.0, 3.0)
	ShowSyncHudMsg(id, g_HudSync, "-%d %L", amount, id, "ZP_XP")

	g_iPlayerXP[id] -= amount;
	CheckLevel(id);
}