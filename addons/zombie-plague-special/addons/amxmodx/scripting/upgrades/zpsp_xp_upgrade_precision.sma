/*=======================================================
		[ZPSp] XP Upgrade: Precision

		* Description:
			- Reduces recoil according to upgrade level

		* Changelog:
			- 1.0: First Release

=======================================================*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <zombie_plague_special>
#include <zpsp_xp_system>

new const up_name[] = "UPGRADE_PRECISION_NAME"
new const up_description[] = "UPGRADE_PRECISION_DESC"
const up_max_level = 5
new const up_prices[up_max_level] = { 100, 200, 300, 400, 500 }
new const up_sell_values[up_max_level] = { 50, 100, 150, 200, 250 }
new const up_vault_name[] = "zpsp_upgrade_precision"

new const wpnClass[][] = { "", "weapon_p228", "", "weapon_scout", "", "weapon_xm1014", "", "weapon_mac10", "weapon_aug", "", "weapon_elite", "weapon_fiveseven", "weapon_ump45", 
"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", 
"weapon_tmp", "weapon_g3sg1", "", "weapon_deagle", "weapon_sg552", "weapon_ak47", "", "weapon_p90" }

new const Float:Percent[up_max_level] = { 
	10.0, // Level 1
	20.0, // Level 2
	30.0, // Level 3
	40.0, // Level 4
	50.0   // Level 5
}

new g_UpgradeId, Float:cl_pushangle[33];
public plugin_init() {
	register_plugin("[ZPSp] XP Upgrade: Precision", "1.0", "Perf. Scrash")
	register_dictionary("zpsp_xp_upgrades.txt")

	for (new i = 0; i < sizeof wpnClass; i++)
	{
		if(!wpnClass[i][0])
			continue;
	
		RegisterHam(Ham_Weapon_PrimaryAttack, wpnClass[i], "fw_PrimaryAttack")
		RegisterHam(Ham_Weapon_PrimaryAttack, wpnClass[i], "fw_PrimaryAttack_Post", 1)
	}

	g_UpgradeId = zp_register_upgrade(up_name, up_description, up_prices, up_sell_values, up_max_level, up_vault_name, 1);
}

public fw_PrimaryAttack(ent) {
	static id;
	id = pev(ent, pev_owner)
	pev(id, pev_punchangle, cl_pushangle[id])
	
	return HAM_IGNORED
}

public fw_PrimaryAttack_Post(ent)
{
	static id, Float:push[3], level;

	id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED;
	
	level = zp_get_user_upgrade_lvl(id, g_UpgradeId)

	if(!level)
		return HAM_IGNORED;

	if(zp_get_user_zombie(id) || zp_get_human_special_class(id))
		return HAM_IGNORED;

	pev(id, pev_punchangle, push)
	xs_vec_sub(push, cl_pushangle[id], push)
	
	xs_vec_mul_scalar(push, (1.0 - (Percent[level-1]/100.0)), push)
	xs_vec_add(push, cl_pushangle[id], push)
	set_pev(id, pev_punchangle, push)

	return HAM_IGNORED
	
	
}

public zp_upgrade_menu_open(id, Up_id) {
	static level
	if(Up_id == g_UpgradeId) {
		level = zp_get_user_upgrade_lvl(id, Up_id)
		if(level)
			zp_upgrade_menu_add_note(fmt("%L", id, "UPGRADE_PRECISION_NOTE", floatround(Percent[level-1])))
	}	
}
