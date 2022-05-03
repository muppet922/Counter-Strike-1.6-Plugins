/*============================================
		[ZPSp] XP Upgrade: Damage H/Z

		* Description:
			- Increment Clip in X Seconds

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <engine>
#include <cstrike>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_AMMO_NAME"
new const up_description[] = "UPGRADE_AMMO_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_ammo"

new const g_MaxClipAmmo[] = { 0, 13, 0, 10, 0, 7, 0, 30, 30, 0, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 0, 7, 30, 30, 0, 50 }
new const wpnClass[][25] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10", "weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", 
"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", 
"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

new const Float:Seconds[up_max_level] = { 
	4.0,  // Level 1
	3.5,  // Level 2
	3.0,  // Level 3
	2.5,  // Level 4
	2.0   // Level 5
}

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Ammo", "1.0", "Perf. Scrash")
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
		set_task(Seconds[level-1], "give_ammo", id)
	}
}

public give_ammo(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_user_zombie(id) || zp_get_human_special_class(id))
		return;

	task_set(id);

	static oldAmmo, wpnType, newAmmo, ent;
	wpnType = get_user_weapon(id, oldAmmo)
	
	if(g_MaxClipAmmo[wpnType] != 0 && oldAmmo != g_MaxClipAmmo[wpnType]) {
		ent = find_ent_by_owner(-1, wpnClass[wpnType], id)
		if(ent) {
			newAmmo = oldAmmo + 1
			if (newAmmo < g_MaxClipAmmo[wpnType])
				cs_set_weapon_ammo(ent, newAmmo)
			else
				cs_set_weapon_ammo(ent, g_MaxClipAmmo[wpnType])
			
		}
	}
}
public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_AMMO_NOTE", floatround(Seconds[level-1])))
	}	
}
