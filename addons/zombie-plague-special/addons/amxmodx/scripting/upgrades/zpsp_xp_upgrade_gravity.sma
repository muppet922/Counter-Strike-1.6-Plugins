/*============================================
		[ZPSp] XP Upgrade: Gravity H/Z

		* Description:
			- 5% Low Gravity

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <fun>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name_h[] = "UPGRADE_GRAVITY_NAME_H"
new const up_name_z[] = "UPGRADE_GRAVITY_NAME_Z"
new const up_description[] = "UPGRADE_GRAVITY_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name_z[] = "zpsp_upgrade_gravity_z"
new const up_vault_name_h[] = "zpsp_upgrade_gravity_h"

new const Float:Gravity_Value[up_max_level] = { 
	0.95, // Level 1
	0.9, // Level 2
	0.85, // Level 3
	0.8, // Level 4
	0.7  // Level 5
}

new g_UpgradeId_H, g_UpgradeId_Z
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Gravity", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	g_UpgradeId_H = zp_register_upgrade(up_name_h, up_description, up_prices, up_sell_values, up_max_level, up_vault_name_h, 1);
	g_UpgradeId_Z = zp_register_upgrade(up_name_z, up_description, up_prices, up_sell_values, up_max_level, up_vault_name_z, 1);
}

public zp_player_spawn_post(id) {
	set_task(0.1, "set_gravity", id)
}
public zp_user_humanized_post(id) {
	set_task(0.1, "set_gravity", id)
}
public zp_user_infected_post(id) {
	set_task(0.1, "set_gravity", id)
}
public set_gravity(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_zombie_special_class(id) || zp_get_human_special_class(id))
		return;

	static level, Float:Gravity
	level = 0;
	if(zp_get_user_zombie(id))
		level = zp_get_user_upgrade_lvl(id, g_UpgradeId_Z)
	else 
		level = zp_get_user_upgrade_lvl(id, g_UpgradeId_H)

	if(level <= 0) {
		zp_reset_user_gravity(id);
		return;
	}

	Gravity = zp_get_user_default_gravity(id) * Gravity_Value[level-1]
	zp_set_user_gravity(id, Gravity)
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId_Z || Up_id == g_UpgradeId_H) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_GRAVITY_NOTE", floatround(100 - (Gravity_Value[level-1] * 100))))
	}	
}

public zp_upgrade_buy_post(id, Up_id) {
	if(Up_id == g_UpgradeId_Z || Up_id == g_UpgradeId_H)
		set_gravity(id)
}
public zp_upgrade_sell_post(id, Up_id) {
	if(Up_id == g_UpgradeId_Z || Up_id == g_UpgradeId_H)
		set_gravity(id)
}