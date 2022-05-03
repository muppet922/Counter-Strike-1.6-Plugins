/*============================================
		[ZPSp] XP Upgrade: Damage H/Z

		* Description:
			- Grenade in X seconds

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_GRENADE_NAME"
new const up_description[] = "UPGRADE_GRENADE_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_grenade"

new const Float:Seconds[up_max_level] = { 
	180.0, // Level 1
	150.0,  // Level 2
	120.0, // Level 3
	90.0,  // Level 4
	60.0  // Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Grenade", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public zp_player_spawn_post(id) task_set(id);
public zp_user_humanized_post(id) task_set(id);
public zp_user_infected_post(id) remove_task(id);
public client_disconnected(id) remove_task(id);
public zp_upgrade_buy_post(id, Up_Id) if(g_UpgradeId == Up_Id) task_set(id);
public zp_upgrade_sell_post(id, Up_Id) if(g_UpgradeId == Up_Id) task_set(id);

public task_set(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_user_zombie(id) || zp_get_human_special_class(id))
		return;

	static level
	level = zp_get_user_upgrade_lvl(id, g_UpgradeId)
	if(level) {
		remove_task(id)
		set_task(Seconds[level-1], "give_grenade", id)
	}
}

public give_grenade(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_user_zombie(id) || zp_get_human_special_class(id))
		return;

	task_set(id);

	static HasFire, HasFrost, HasLight
	HasFire = user_has_weapon(id, CSW_HEGRENADE)
	HasFrost = user_has_weapon(id, CSW_FLASHBANG)
	HasLight = user_has_weapon(id, CSW_SMOKEGRENADE)

	if(HasFire && HasFrost && HasLight)
		return;

	if(HasFire && HasFrost && !HasLight)
		zp_give_item(id, "weapon_smokegrenade")
	
	else if(!HasFire && HasFrost && HasLight)
		zp_give_item(id, "weapon_hegrenade")

	else if(HasFire && !HasFrost && HasLight)
		zp_give_item(id, "weapon_flashbang")

	else if(!HasFire && HasFrost && !HasLight)
		zp_give_item(id, (random_num(0, 1) == 1) ? "weapon_smokegrenade" : "weapon_hegrenade")

	else if(HasFire && !HasFrost && !HasLight)
		zp_give_item(id, (random_num(0, 1) == 1) ? "weapon_flashbang" : "weapon_smokegrenade")
	
	else if(!HasFire && !HasFrost && HasLight)
		zp_give_item(id, (random_num(0, 1) == 1) ? "weapon_flashbang" : "weapon_hegrenade")

	else {
		switch(random_num(0, 2)) {
			case 0: zp_give_item(id, "weapon_smokegrenade");
			case 1: zp_give_item(id, "weapon_hegrenade");
			case 2: zp_give_item(id, "weapon_flashbang");
		}
	}
}
public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_GRENADE_NOTE", floatround(Seconds[level-1])))
	}	
}
