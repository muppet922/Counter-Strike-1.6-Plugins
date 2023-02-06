#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

public plugin_init()
{
     register_plugin("Game Namer","Version 1.0","NeuroToxin");
     register_cvar("amx_gamename","Counter - Strike");
     register_forward(FM_GetGameDescription,"GameDesc");
}

public GameDesc()
{
	new gamename[32];
	get_cvar_string("amx_gamename",gamename,31);
	forward_return(FMV_STRING,gamename);
	return FMRES_SUPERCEDE;
}