#include <amxmodx>
#include <fun>
#define PLUGIN_VERSION "1.0.1"
new g_pSpeed
public plugin_init()
{
	register_plugin("Fast Knife", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXFastKnife", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_event("CurWeapon", "OnSelectKnife", "be", "1=1", "2=29")
	g_pSpeed = register_cvar("fastknife_speed", "50.0")
}
public OnSelectKnife(id)
{
	if(is_user_alive(id))
	{
		set_user_maxspeed(id, get_user_maxspeed(id) + get_pcvar_float(g_pSpeed))
	}
}