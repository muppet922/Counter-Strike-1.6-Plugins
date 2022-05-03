/*============================================
		[ZPSp] XP Upgrade: Knockback

		* Description:
			- Reduces knockback taken

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_KNOCKBACK_NAME"
new const up_description[] = "UPGRADE_KNOCKBACK_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_knockback"

new const Float:Percent[up_max_level] = { 
	0.9,	// Level 1
	0.8,	// Level 2
	0.7,	// Level 3
	0.6,	// Level 4
	0.5		// Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Knockback", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public zp_player_spawn_post(id) set_knockback(id, 0);
public zp_user_infected_post(id) set_knockback(id, 0);
public zp_upgrade_buy_post(id) set_knockback(id, 0);
public zp_upgrade_sell_post(id) set_knockback(id, 1);

public set_knockback(id, reset) {
	if(!zp_get_user_zombie(id))
		return;

	static level; level = zp_get_user_upgrade_lvl(id, g_UpgradeId)
	if(level)
		zp_set_user_knockback(id, zp_get_default_knockback(id) * Percent[level-1]);
	else if(reset)
		zp_reset_user_knockback(id);
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_KNOCKBACK_NOTE", floatround(100 - (Percent[level-1] * 100))))
	}	
}