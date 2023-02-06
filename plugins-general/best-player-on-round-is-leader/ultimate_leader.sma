/*

|----[Связь с автором]----|
|VK: 		vk.com/nunfy  |
|TELEGRAM:	t.me/Nunfy    |
|-------------------------|

*/
#include <amxmodx>
#include <reapi>

#define is_client(%0) (1 <= %0 <= MaxClients)

new const VERSION[] = 			"2.1";

const MAX_MODELS = 				1; 										// Максимальное количество моделей

new const model_path[8][MAX_MODELS][] =
{
	{	// terror
		"models/player/terror_leader/terror_leader.mdl",
	},
	{ 	// leet
		"models/player/leet_leader/leet_leader.mdl",
	},
	{ 	// arctic
		"models/player/arctic_leader/arctic_leader.mdl",
	},
	{ 	// guerilla
		"models/player/guerilla_leader/guerilla_leader.mdl",
	},
	{	// urban
		"models/player/urban_leader/urban_leader.mdl",
	},
	{	// gsg9
		"models/player/gsg9_leader/gsg9_leader.mdl",
	},
	{	// sas
		"models/player/sas_leader/sas_leader.mdl",
	},
	{	// gign
		"models/player/gign_leader/gign_leader.mdl"
	}
};

new const default_model[8][MAX_MODELS][] =
{
	{	// terror
		"terror",
	},
	{
		// leet
		"leet",
	},
	{
		// arctic
		"arctic",
	},
	{
		// guerilla
		"guerilla",
	},
	{
		// urban
		"urban",
	},
	{
		// gsg9
		"gsg9",
	},
	{
		// sas
		"sas",
	},
	{
		// gign
		"gign"
	}
};

new const custom_model[8][MAX_MODELS][] =
{
	{	// terror
		"terror_leader",
	},
	{
		// leet
		"leet_leader",
	},
	{
		// arctic
		"arctic_leader",
	},
	{
		// guerilla
		"guerilla_leader",
	},
	{
		// urban
		"urban_leader",
	},
	{
		// gsg9
		"gsg9_leader",
	},
	{
		// sas
		"sas_leader",
	},
	{
		// gign
		"gign_leader"
	}
};

enum cvar_data
{
	cvar_mode
}

enum
{
	dId,
	dKills,
	dDamage
}

enum user_data
{
	udModel,
	udKills,
	udDamage
};

enum leader_data
{
	ldId,
	ldKills,
	ldDamage,
	ldPast_id
};

new cd[cvar_data],
	ud[MAX_CLIENTS + 1][user_data],
	ld[leader_data];

public plugin_init()
{
	register_plugin("Ultimate Leader", VERSION, "Nunf");
	register_dictionary("ultimate_leader.txt");
	bind_pcvar_num(create_cvar("ul_mode", "0", FCVAR_NONE, fmt("%l", "UL_CVAR_MODE_DESCRIPTION"), true, 0.0, true, 1.0), cd[cvar_mode]);
	AutoExecConfig(true, "ultimate_leader");
	RegisterHookChain(RG_HandleMenu_ChooseAppearance, 			"user_choose_appearance", 	true);
	RegisterHookChain(RG_CBasePlayer_Killed, 					"user_killed", 				true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, 				"user_take_damage", 		true);
	RegisterHookChain(RG_RoundEnd, 								"round_end", 				true);
	RegisterHookChain(RG_CBasePlayer_Spawn, 					"user_spawn", 				true);
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoModel, 	"set_user_model", 			false);
}

public plugin_precache()
{
	for(new i; i < sizeof model_path; i++)
	{
		for(new n; n < MAX_MODELS; n++)
		{
			if(file_exists(model_path[i][n]))
			{
				precache_model(model_path[i][n]);
			}
			else
			{
				set_fail_state("^n\
				[ERROR]: FILE NOT EXISTS(array ^"model_path^")^n\
				[FILE PATH]: %s",
				model_path[i][n]);
			}
		}
	}
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	ud[id][udModel] = 0;
	ud[id][udKills] = 0;
	ud[id][udDamage] = 0;
	if(id == ld[ldId])
	{
		ld[ldId] = 0;
		ld[ldKills] = 0;
		ld[ldDamage] = 0;
	}
	else if(id == ld[ldPast_id])
	{
		ld[ldPast_id] = 0;
	}
}

public user_choose_appearance(const id, slot)
{
	switch(get_member(id, m_iModelName))
	{
		case MODEL_T_TERROR:
		{
			ud[id][udModel] = 0;
		}
		case MODEL_T_LEET:
		{
			ud[id][udModel] = 1;
		}
		case MODEL_T_ARCTIC:
		{
			ud[id][udModel] = 2;
		}
		case MODEL_T_GUERILLA:
		{
			ud[id][udModel] = 3;
		}
		case MODEL_CT_URBAN:
		{
			ud[id][udModel] = 4;
		}
		case MODEL_CT_GSG9:
		{
			ud[id][udModel] = 5;
		}
		case MODEL_CT_SAS:
		{
			ud[id][udModel] = 6;
		}
		case MODEL_CT_GIGN:
		{
			ud[id][udModel] = 7;
		}
	}
}

public user_killed(const id, attacker_id, iGib)
{
	if(is_client(attacker_id) && id != attacker_id)
	{
		ud[attacker_id][udKills]++;
	}
}

public user_take_damage(const id, pevInflictor, attacker_id, Float: damage, bitsDamageType)
{
	if(is_client(attacker_id) && id != attacker_id)
	{
		if(GetHookChainReturn(ATYPE_INTEGER) == 1)
		{
			ud[attacker_id][udDamage] += floatround(damage);
		}
		else if(get_member(attacker_id, m_iTeam) != get_member(attacker_id, m_iTeam))
		{
			ud[attacker_id][udDamage] += floatround(damage) + get_user_health(id);
		}	
	}
}

public round_end(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	set_task(0.1, "task_round_end");
}

public user_spawn(id)
{
	if(id == ld[ldId])
	{
		rg_set_user_model(ld[ldId], custom_model[ud[id][udModel]][random(sizeof custom_model[])]);
	}
	else if(id == ld[ldPast_id])
	{
		rg_set_user_model(ld[ldId], default_model[ud[id][udModel]][random(sizeof default_model[])]);
	}
}

public set_user_model(id, infobuffer[], new_model[])
{
	if(id == ld[ldId])
	{
		SetHookChainArg(3, ATYPE_STRING, custom_model[ud[id][udModel]][random(sizeof custom_model[])]);
	}
	else if(id == ld[ldPast_id])
	{
		SetHookChainArg(3, ATYPE_STRING, default_model[ud[id][udModel]][random(sizeof default_model[])]);
	}
}

public task_round_end()
{
	new u_i[MAX_CLIENTS],
		u_n;
	get_players(u_i, u_n, "h");
	new data[3];
	data[dId] = u_i[0];
	data[dKills] = ud[u_i[0]][udKills];
	data[dDamage] = ud[u_i[0]][udDamage];
	ud[u_i[0]][udKills] = 0;
	ud[u_i[0]][udDamage] = 0;
	if(cd[cvar_mode] == 0)
	{
		for(new i = 1; i < u_n; i++)
		{
			if(ud[u_i[i]][udKills] > data[dKills] || ud[u_i[i]][udKills] == data[dKills] && ud[u_i[i]][udDamage] > data[dDamage])
			{
				data[dId] = u_i[i];
				data[dKills] = u_i[i];
				data[dDamage] = u_i[i];
			}
			ud[u_i[i]][udKills] = 0;
			ud[u_i[i]][udDamage] = 0;
		}
		if(data[dKills] > ld[ldKills] || data[dKills] == ld[ldKills] && data[dDamage] > ld[ldDamage])
		{
			if(data[dId] == ld[ldId])
			{
				ld[ldKills] = data[dKills];
				ld[ldDamage] = data[dDamage];
				client_print_color(0, print_team_default, "%l", "UL_LEADER_OUTDONE_HIMSELF", data[dId], data[dKills], data[dDamage]);
			}
			else
			{
				ld[ldPast_id] = ld[ldId];
				ld[ldId] = data[dId];
				ld[ldKills] = data[dKills];
				ld[ldDamage] = data[dDamage];
				client_print_color(0, print_team_default, "%l", "UL_NEW_LEADER", data[dId], data[dKills], data[dDamage]);
			}
		}
		else
		{
			if(!is_client(ld[ldId]))
			{
				client_print_color(0, print_team_default, "%l", "UL_NO_LEADER");
			}
			else
			{
				client_print_color(0, print_team_default, "%l", "UL_NOBODY_SUPPARSED_LEADER", ld[ldId]);
			}
		}
	}
	else
	{
		for(new i = 1; i < u_n; i++)
		{
			if(ud[u_i[i]][udDamage] > data[dDamage] || ud[u_i[i]][udDamage] == data[dDamage] && ud[u_i[i]][udKills] > data[dKills])
			{
				data[dId] = u_i[i];
				data[dKills] = u_i[i];
				data[dDamage] = u_i[i];
			}
			ud[u_i[i]][udKills] = 0;
			ud[u_i[i]][udDamage] = 0;
		}
		if(data[dDamage] > ld[ldDamage] || data[dDamage] == ld[ldDamage] && data[dKills] > ld[ldKills])
		{
			if(data[dId] == ld[ldId])
			{
				ld[ldKills] = data[dKills];
				ld[ldDamage] = data[dDamage];
				client_print_color(0, print_team_default, "%l", "UL_LEADER_OUTDONE_HIMSELF", data[dId], data[dKills], data[dDamage]);
			}
			else
			{
				ld[ldPast_id] = ld[ldId];
				ld[ldId] = data[dId];
				ld[ldKills] = data[dKills];
				ld[ldDamage] = data[dDamage];
				client_print_color(0, print_team_default, "%l", "UL_NEW_LEADER", data[dId], data[dKills], data[dDamage]);
			}
		}
		else
		{
			if(!is_client(ld[ldId]))
			{
				client_print_color(0, print_team_default, "%l", "UL_NO_LEADER");
			}
			else
			{
				client_print_color(0, print_team_default, "%l", "UL_NOBODY_SUPPARSED_LEADER", ld[ldId]);
			}
		}
	}
}