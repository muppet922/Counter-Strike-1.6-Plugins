/*============================================
		[ZPSp] XP Upgrade: Protection

		* Description:
			- Reduces damage taken

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_PROTECTION_NAME"
new const up_description[] = "UPGRADE_PROTECTION_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_protection"

new const Float:Protection_Percent[up_max_level] = { 
	0.9,	// Level 1
	0.85,	// Level 2
	0.8,	// Level 3
	0.75,	// Level 4
	0.7		// Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Protection", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage") // Take damage forward

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) { // Ham Take Damage Forward
	if(!is_user_alive(victim))
		return HAM_IGNORED;

	if(!zp_get_user_zombie(victim) || zp_get_zombie_special_class(victim))
		return HAM_IGNORED;

	static level; level = zp_get_user_upgrade_lvl(victim, g_UpgradeId)
	if(level)
		SetHamParamFloat(4, damage * Protection_Percent[level-1])
	
	return HAM_IGNORED;
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_PROTECTION_NOTE", floatround(100 - (Protection_Percent[level-1] * 100))))
	}	
}
