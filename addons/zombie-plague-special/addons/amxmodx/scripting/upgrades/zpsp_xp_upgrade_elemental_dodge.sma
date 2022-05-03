/*============================================
		[ZPSp] XP Upgrade: Elemental Dodge

		* Description:
			- Chance of escaping to get frozen/burn

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_ELDODGE_NAME"
new const up_description[] = "UPGRADE_ELDODGE_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_eldodge"

new const Chance[up_max_level] = { 
	150,    // Level 1
	125,    // Level 2
	100,    // Level 3
	75,     // Level 4
	50      // Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Elemental Shoot", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public zp_user_frozen_pre(id) return escape_elemental(id);
public zp_user_burn_pre(id) return escape_elemental(id);

stock escape_elemental(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;

	if(!zp_get_user_zombie(id))
		return PLUGIN_CONTINUE;

	static level
	level = zp_get_user_upgrade_lvl(id, g_UpgradeId)
	if(!level)
		return PLUGIN_CONTINUE;

	if(random_num(1, Chance[level-1]) != 1)
		return PLUGIN_CONTINUE;

	return ZP_PLUGIN_HANDLED;
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_ELDODGE_NOTE", Chance[level-1]))
	}	
}
