/*============================================
		[ZPSp] XP Upgrade: Elemental Shoot

		* Description:
			- Chance of shoot fire or ice on enemies

		* Changelog:
			- 1.0: First Release
			- 1.1: Fix bug that zombies can frost/burn others zombies (Thanks 8K300FPS) for repoort

=============================================*/

#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_ELSHOOT_NAME"
new const up_description[] = "UPGRADE_ELSHOOT_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_elshoot"

new const Chance[up_max_level] = { 
	200,    // Level 1
	150,    // Level 2
	100,    // Level 3
	75,     // Level 4
	50      // Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Elemental Shoot", "1.1", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage") // More Damage on players

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, dmg_type) { // Ham Take Damage Forward
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED;

	if(!zp_get_user_zombie(victim) || zp_get_human_special_class(attacker) || zp_get_user_zombie(attacker))
		return HAM_IGNORED;

	static level; level = zp_get_user_upgrade_lvl(attacker, g_UpgradeId)
	if(!level)
		return HAM_IGNORED;

	if(random_num(1, Chance[level-1]) != 1)
		return HAM_IGNORED;
	
	if(random_num(1, 4) == 1 && !zp_get_zombie_special_class(victim))
		zp_set_user_frozen(victim, SET)
	else 
		zp_set_user_burn(victim, SET)

	return HAM_IGNORED;
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_ELSHOOT_NOTE", Chance[level-1]))
	}	
}
