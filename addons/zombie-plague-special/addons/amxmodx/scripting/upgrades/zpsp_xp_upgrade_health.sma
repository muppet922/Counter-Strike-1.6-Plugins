/*============================================
		[ZPSp] XP Upgrade: Health H/Z

		* Description:
			- More Health on Respawn

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <fun>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name_h[] = "UPGRADE_HEALTH_NAME_H"
new const up_name_z[] = "UPGRADE_HEALTH_NAME_Z"
new const up_description[] = "UPGRADE_HEALTH_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name_z[] = "zpsp_upgrade_health_z"
new const up_vault_name_h[] = "zpsp_upgrade_health_h"

new const Float:Health_Multi[up_max_level] = { 
	1.1, // Level 1
	1.2, // Level 2
	1.3, // Level 3
	1.4, // Level 4
	1.5  // Level 5
}

new g_UpgradeId_H, g_UpgradeId_Z
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Health", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	g_UpgradeId_H = zp_register_upgrade(up_name_h, up_description, up_prices, up_sell_values, up_max_level, up_vault_name_h, 1);
	g_UpgradeId_Z = zp_register_upgrade(up_name_z, up_description, up_prices, up_sell_values, up_max_level, up_vault_name_z, 1);
}

public zp_player_spawn_post(id) {
	set_task(0.2, "set_hp", id)
}
public zp_user_humanized_post(id) {
	set_task(0.2, "set_hp", id)
}
public zp_user_infected_post(id) {
	set_task(0.2, "set_hp", id)
}
public set_hp(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_zombie_special_class(id) || zp_get_human_special_class(id))
		return;

	static level, Float:MaxHP
	level = 0;
	if(zp_get_user_zombie(id))
		level = zp_get_user_upgrade_lvl(id, g_UpgradeId_Z)
	else 
		level = zp_get_user_upgrade_lvl(id, g_UpgradeId_H)

	if(level <= 0)
		return;

	MaxHP = zp_get_user_maxhealth(id) * Health_Multi[level-1]
	set_user_health(id, floatround(MaxHP))
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId_Z || Up_id == g_UpgradeId_H) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_HEALTH_NOTE", floatround(100-((Health_Multi[level-1]-1) * 100))))
	}	
}