#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

#pragma semicolon 1

// #define ALLOW_CT_DAMAGE

public plugin_init() {
	register_plugin("Immortal Hostage", "1.1", "Javekson");
	RegisterHam(Ham_TakeDamage, "hostage_entity", "fwd_hostage_damage", 0);
}

public fwd_hostage_damage(victim, inflictor, attacker) {
	#if defined ALLOW_CT_DAMAGE
	if(is_user_alive(attacker) && cs_get_user_team(attacker) == CS_TEAM_CT) {
		return HAM_IGNORED;
	}
	#endif
	return HAM_SUPERCEDE;
}
