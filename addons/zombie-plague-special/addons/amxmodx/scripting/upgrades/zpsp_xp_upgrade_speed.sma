/*============================================
		[ZPSp] XP Upgrade: Speed H/Z

		* Description:
			- More speed of according with upgrade level

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name_h[] = "UPGRADE_SPEED_NAME_H"
new const up_name_z[] = "UPGRADE_SPEED_NAME_Z"
new const up_description[] = "UPGRADE_SPEED_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name_z[] = "zpsp_upgrade_speed_z"
new const up_vault_name_h[] = "zpsp_upgrade_speed_h"

new const Float:Speed_Add_H[up_max_level] = { 
	10.0, // Level 1
	15.0, // Level 2
	20.0, // Level 3
	25.0, // Level 4
	30.0  // Level 5
}

new const Float:Speed_Add_Z[up_max_level] = { 
	10.0, // Level 1
	20.0, // Level 2
	30.0, // Level 3
	40.0, // Level 4
	50.0  // Level 5
}

new g_UpgradeId_H, g_UpgradeId_Z
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Speed", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	g_UpgradeId_H = zp_register_upgrade(up_name_h, up_description, up_prices, up_sell_values, up_max_level, up_vault_name_h, 1);
	g_UpgradeId_Z = zp_register_upgrade(up_name_z, up_description, up_prices, up_sell_values, up_max_level, up_vault_name_z, 1);
}

public zp_player_spawn_post(id) {
	set_speed(id);
}
public zp_user_humanized_post(id) {
	set_speed(id);
}
public zp_user_infected_post(id) {
	set_speed(id);
}
public zp_upgrade_buy_post(id, Up_id) {
	if(Up_id == g_UpgradeId_Z || Up_id == g_UpgradeId_H)
		set_speed(id);
}
public zp_upgrade_sell_post(id, Up_id) {
	if(Up_id == g_UpgradeId_Z || Up_id == g_UpgradeId_H)
		set_speed(id);
}
public zp_upgrade_menu_open(id, Up_id) {
	static level

	if(Up_id == g_UpgradeId_Z || Up_id == g_UpgradeId_H) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_SPEED_NOTE", floatround((Up_id == g_UpgradeId_Z) ? Speed_Add_Z[level-1] : Speed_Add_H[level-1])))
	}	
}
public set_speed(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_zombie_special_class(id) || zp_get_human_special_class(id))
		return;

	static level, Float:Spd, IsZombie;
	level = 0;
	IsZombie = zp_get_user_zombie(id);
	if(IsZombie)
		level = zp_get_user_upgrade_lvl(id, g_UpgradeId_Z)
	else 
		level = zp_get_user_upgrade_lvl(id, g_UpgradeId_H)

	if(level <= 0)
		return;

	Spd = IsZombie ? Speed_Add_Z[level-1] : Speed_Add_H[level-1];
	zp_set_user_maxspeed(id, (zp_get_user_default_maxspeed(id) + Spd))
}