#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <reapi>

new Float:g_wallorigin[MAX_CLIENTS + 1][3], climb_speed, climb_mode, bool:climb_buy, climb_buy_money, climb_team[4];
new bool:g_wallclimb[MAX_CLIENTS + 1];

public plugin_init() {
	register_plugin("Wall Climb", "0.0.1", "PurposeLess");

	register_clcmd("say /climb", "@clcmd_climb");

	register_touch("worldspawn", "player", "@Touch_Wall");

	RegisterHookChain(RG_PM_Move, "@PM_Move", .post = false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn", .post = true);

	bind_pcvar_num(create_cvar("climb_speed", "240"), climb_speed);
	bind_pcvar_num(create_cvar("climb_mode", "1"), climb_mode);
	bind_pcvar_num(create_cvar("climb_buy", "0"), climb_buy);
	bind_pcvar_num(create_cvar("climb_buy_money", "2000"), climb_buy_money);
	bind_pcvar_string(create_cvar("climb_team", "any"), climb_team, charsmax(climb_team));

	register_dictionary("wallclimb.txt");
}

@CBasePlayer_Spawn(const pPlayer) {
	if(!is_user_alive(pPlayer)) {
		return;
	}

	if(CheckPlayerTeam(pPlayer)) {
		g_wallclimb[pPlayer] = true;
	}
	else {
		g_wallclimb[pPlayer] = false;
	}
}

@clcmd_climb(pPlayer) {
	if(climb_buy) {
		if(g_wallclimb[pPlayer]) {
			client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "WALLCLIMB_YOU_HAVE_ALREADY");
			return PLUGIN_HANDLED;
		}

		if(climb_buy_money) {
			if(get_member(pPlayer, m_iAccount) < climb_buy_money) {
				client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "WALLCLIMB_NOT_ENOUGH_MONEY");
				return PLUGIN_HANDLED;
			}

			rg_add_account(pPlayer, -climb_buy_money, AS_ADD);
		}

		client_print_color(pPlayer, pPlayer, "%L", LANG_PLAYER, "WALLCLIMB_BOUGHT");
		g_wallclimb[pPlayer] = true;
	}
	return PLUGIN_HANDLED;
}

@Touch_Wall(pTouched, pToucher) {
	if(!g_wallclimb[pToucher]) {
		return;
	}

	get_entvar(pToucher, var_origin, g_wallorigin[pToucher]);
}

@PM_Move(const pPlayer) {
	if(get_pmove(pm_dead) || !g_wallclimb[pPlayer] || get_pmove(pm_onground) == 0) {
		return;
	}

	static button;
	button = get_entvar(pPlayer, var_button);

	if(!CheckMode(button)) {
		return;
	}

	static Float:flOrigin[3];
	get_pmove(pm_origin, flOrigin);

	if(get_distance_f(flOrigin, g_wallorigin[pPlayer]) > 25.0) {
		return;
	}

	if(button & IN_FORWARD) {
		static Float:flVelocity[3];
		velocity_by_aim(pPlayer, climb_speed, flVelocity);
		set_pmove(pm_velocity, flVelocity);
	}
	else if(button & IN_BACK) {
		static Float:flVelocity[3];
		velocity_by_aim(pPlayer, -climb_speed, flVelocity);
		set_pmove(pm_velocity, flVelocity);
	}
}

bool:CheckPlayerTeam(const pPlayer) {
    switch(climb_team[0]) {
        case 'C','c': {
            return bool:(get_member(pPlayer, m_iTeam) == TEAM_CT);
        }
        case 'T','t': {
            return bool:(get_member(pPlayer, m_iTeam) == TEAM_TERRORIST);
        }
    }
    return true;
}

bool:CheckMode(const button) {
	switch(climb_mode) {
		case 1: {
			if(button & IN_USE) {
				return true;
			}
		}
		case 2: {
			if(button & IN_JUMP) {
				return true;
			}
		}
		case 3: {
			if(button & (IN_USE | IN_JUMP)) {
				return true;
			}
		}
		default: {
			return true;
		}
	}
	return false;
}