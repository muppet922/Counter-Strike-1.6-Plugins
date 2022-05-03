/*============================================
		[ZPSp] XP Upgrade: Reload

		* Description:
			- Reduces reload time

		* Changelog:
			- 1.0: First Release

=============================================*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_RELOAD_NAME"
new const up_description[] = "UPGRADE_RELOAD_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_reload"

new const Float:Ratio[up_max_level] = { 
	0.9,	// Level 1
	0.8,	// Level 2
	0.7,	// Level 3
	0.6,	// Level 4
	0.5		// Level 5
}

// Consts
const OFFSET_WEAPONOWNER = 41; // CS Weapon CBase Offsets (win32)
const OFFSET_LINUX = 5; // offsets 5 higher in Linux builds
const OFFSET_LINUX_WEAPONS = 4; // weapon offsets are only 4 steps higher on Linux
const m_flTimeWeaponIdle = 48;
const m_flNextAttack = 83;

new const wpnClass[][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10", "weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", 
"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", 
"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

new g_UpgradeId
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Reload", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	for (new i = 0; i < sizeof wpnClass; i++) {
		if(wpnClass[i][0])
			RegisterHam(Ham_Weapon_Reload, wpnClass[i], "fw_WeaponReload_Post", 1);
	}

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public fw_WeaponReload_Post(wpn_ent) {
	if(!pev_valid(wpn_ent))
		return HAM_IGNORED;

	static id, Float:CurrentTime;
	id = get_pdata_cbase(wpn_ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)

	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(zp_get_user_zombie(id))
		return HAM_IGNORED;

	static level; level = zp_get_user_upgrade_lvl(id, g_UpgradeId)
	if(!level)
		return HAM_IGNORED;

	CurrentTime = get_pdata_float(wpn_ent, m_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS)
	set_pdata_float(wpn_ent, m_flTimeWeaponIdle, (CurrentTime * Ratio[level-1]), OFFSET_LINUX_WEAPONS)

	CurrentTime = get_pdata_float(id, m_flNextAttack, OFFSET_LINUX)
	set_pdata_float(id, m_flNextAttack, (CurrentTime * Ratio[level-1]), OFFSET_LINUX)

	return HAM_IGNORED;
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_RELOAD_NOTE", floatround(100 - (Ratio[level-1] * 100))))

		zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_RELOAD_NOTE2"))
	}	
}
