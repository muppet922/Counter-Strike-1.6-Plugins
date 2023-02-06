#include <amxmodx>
#include <engine>

#define PLUGIN_VERSION "1.0"

new const g_iSnowyMonths[] = { 1, 12 }
new g_szMonth[3], g_iMonth

public plugin_init()
{
	register_plugin("Let it Snow!", PLUGIN_VERSION, "OciXCrom")
	register_cvar("LetitSnow", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
}

public plugin_precache()
{
	get_time("%m", g_szMonth, charsmax(g_szMonth))
	g_iMonth = str_to_num(g_szMonth)
		
	for(new i = 0; i < sizeof(g_iSnowyMonths); i++)
	{
		if(g_iSnowyMonths[i] == g_iMonth)
			create_entity("env_snow")
	}
}