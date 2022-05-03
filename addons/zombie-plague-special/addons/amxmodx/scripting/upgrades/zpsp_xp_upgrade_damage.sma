/*============================================
		[ZPSp] XP Upgrade: Damage H/Z

		* Description:
			- More damage when upgrade

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_DAMAGE_NAME"
new const up_description[] = "UPGRADE_DAMAGE_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_damage"

new const Float:Damage_Multi[up_max_level] = { 
	1.05, // Level 1
	1.1,  // Level 2
	1.15, // Level 3
	1.2,  // Level 4
	1.25  // Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Damage", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage") // More Damage on players
	RegisterHam(Ham_TakeDamage, "func_breakable", "fw_TakeDamage") // More damage on breakable objects
	RegisterHam(Ham_TakeDamage, "info_target", "fw_TakeDamage") // More damage on boss entitities

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) { // Ham Take Damage Forward
	if(!is_user_alive(attacker))
		return HAM_IGNORED;

	if(zp_get_user_zombie(attacker) || zp_get_human_special_class(attacker))
		return HAM_IGNORED;

	static level; level = zp_get_user_upgrade_lvl(attacker, g_UpgradeId)
	if(level)
		SetHamParamFloat(4, damage * Damage_Multi[level-1])
	
	return HAM_IGNORED;
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_DAMAGE_NOTE", floatround((Damage_Multi[level-1] * 100) - 100)))
	}	
}
