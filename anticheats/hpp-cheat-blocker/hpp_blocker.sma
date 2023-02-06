#include <amxmodx>
#include <fakemeta>

#define PLUGIN  "HPP_BLOCK"
#define AUTHOR  "UNKNOWN + bristol"
#define VERSION "1.1"

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	create_cvar(PLUGIN, VERSION, (FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED));
}

public client_putinserver(id)
{
    engfunc(EngFunc_SetPhysicsKeyValue, id, "pi", "aye");
}