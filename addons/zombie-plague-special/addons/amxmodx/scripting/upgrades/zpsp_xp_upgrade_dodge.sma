/*============================================
		[ZPSp] XP Upgrade: Dodge

		* Description:
			- Can dodge of shoots

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_DODGE_NAME"
new const up_description[] = "UPGRADE_DODGE_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_dodge"

new const Chance[up_max_level] = { 
	150,	// Level 1
	100,	// Level 2
	75,		// Level 3
	50,		// Level 4
	25		// Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Dodge", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack") // More Damage on players

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}


public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], traceresult, damagebits) { // Ham Take Damage Forward
	if(!is_user_alive(victim))
		return HAM_IGNORED;

	if(!zp_get_user_zombie(victim) || zp_get_zombie_special_class(victim))
		return HAM_IGNORED;

	static level; level = zp_get_user_upgrade_lvl(victim, g_UpgradeId)
	if(!level)
		return HAM_IGNORED;

	if(random_num(1, Chance[level-1]) == 1) {
		ScreenFade(victim, 1, { 0, 100, 255 }, 100)
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_DODGE_NOTE", Chance[level-1]))
	}	
}

stock ScreenFade(id, Timer, Colors[3], Alpha) {
	if(!is_user_connected(id) && id)
		return;

	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
} 