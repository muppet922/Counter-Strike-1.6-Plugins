#include <amxmodx>
#include <hamsandwich>
#tryinclude <biohazard>

#if !defined _biohazard_included
        #assert Biohazard functions file required!
#endif

new autoinfection_max,autoinfection_min, autoinfection_zombies
public plugin_init()
{
	register_plugin("Auto Zombie Infection", "0.1", "cheap_suit")
	is_biomod_active() ? plugin_init2() : pause("ad")
}

public plugin_init2()
{
	autoinfection_max = register_cvar("bh_autoinfection_max", "2")
	autoinfection_min = register_cvar("bh_autoinfection_min", "20")
	autoinfection_zombies = register_cvar("bh_autoinfection_zombies", "2")
	RegisterHam(Ham_Spawn, "player", "player_respawned")
}

public player_respawned()
{
	static players[32], num
	num = get_playersnum()
	if (num >= get_pcvar_num(autoinfection_min))
	{
		get_players(players, num, "e", "T")
		if (num <= get_pcvar_num(autoinfection_zombies))
		{
			static id
			for (new i = 0; i < get_pcvar_num(autoinfection_max); i++)
			{
				get_players(players, num, "ae", "CT")
				id = players[random_num(0, num - 1)]
				infect_user(id, 0)
				client_print(id, print_center, "You are chosen to be a minion.")
			}
		}
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
