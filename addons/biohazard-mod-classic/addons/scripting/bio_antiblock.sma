#include <amxmodx>
#include <fakemeta>
#tryinclude <biohazard>

#if !defined _biohazard_included
        #assert Biohazard functions file required!
#endif

enum CsTeams
{
	CS_TEAM_UNASSIGNED	= 0,
	CS_TEAM_T 		= 1,
	CS_TEAM_CT 		= 2,
	CS_TEAM_SPECTATOR 	= 3
}

#define OFFSET_TEAM 114
#define cs_get_user_team(%1) CsTeams:get_pdata_int(%1, OFFSET_TEAM)

new cvar_antiblock, Float:g_lasttimetouched[33] // lol
public plugin_init()
{
	register_plugin("anti block", "0.2", "cheap_suit")
	is_biomod_active() ? plugin_init2() : pause("ad")
}

public plugin_init2()
{
	register_forward(FM_Touch, "fwd_touch")
	register_forward(FM_PlayerPreThink, "fwd_playerprethink")
	cvar_antiblock = register_cvar("bh_antiblock", "1")
}

public fwd_playerprethink(id)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	static solid; solid = pev(id, pev_solid)
	if(solid == SOLID_NOT && (get_gametime() - g_lasttimetouched[id]) > 0.34)
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
	
	return FMRES_IGNORED
}

public fwd_touch(blocker, id)
{
	if(!is_user_alive(blocker) || !is_user_alive(id) || !get_pcvar_num(cvar_antiblock))
		return FMRES_IGNORED
	
	static button[2]
	button[0] = pev(id, pev_button), button[1] = pev(blocker, pev_button)
	
	if(button[0] & IN_USE || button[1] & IN_USE)
	{
		static CsTeams:team[2]
		team[0] = cs_get_user_team(id), team[1] = cs_get_user_team(blocker)
	
		if(team[0] != team[1])
			return FMRES_IGNORED
		
		set_pev(blocker, pev_solid, SOLID_NOT), set_pev(id, pev_solid, SOLID_NOT)
		
		static Float:gametime; gametime = get_gametime()
		g_lasttimetouched[id] = gametime, g_lasttimetouched[blocker] = gametime
	}
	return FMRES_IGNORED
}
	