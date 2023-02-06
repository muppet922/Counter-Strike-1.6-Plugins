#define NE_UA_VERSION "1.0.1"

/*
	New-Era_UnlimitedAmmo by New-Era Scripting Team members:
		Alican Çubukçuoðlu (AKA AlicanC and Shaman)
	
	You can reach us from Steam Community group "#n.E Scripting Team"
*/

/*---------------+
|    Includes    |
+---------------*/
#include <amxmodx>
#include <amxmisc>
#include <cstrike>

/*--------------+
|    Globals    |
+--------------*/
new CSW_MAXAMMO[33]= {-2, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100, -1, -1}
new cvar_enable

/*----------------------------+
|    Plugin Initialization    |
+----------------------------*/
public plugin_init()
{
	/*--------------------------+
	|    Plugin Registration    |
	+--------------------------*/
	register_plugin("New-Era_UnlimitedAmmo", NE_UA_VERSION, "TEST")
	register_cvar("ne_uammo_version", NE_UA_VERSION, FCVAR_SPONLY)
	
	/*------------+
	|    CVars    |
	+------------*/
	cvar_enable= register_cvar("ne_uammo_enable", "1")
	
	/*-------------+
	|    Events    |
	+-------------*/
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	
	/*---------------+
	|    Commands    |
	+---------------*/
}

public event_curweapon(id)
{
	//Check if the plugin is enabled and player is alive
	if(!get_pcvar_num(cvar_enable) || !is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	//Get and check weapon ID
	new weaponID= read_data(2)
	if(weaponID==CSW_C4 || weaponID==CSW_KNIFE || weaponID==CSW_HEGRENADE || weaponID==CSW_SMOKEGRENADE || weaponID==CSW_FLASHBANG)
		return PLUGIN_CONTINUE;
	
	if(cs_get_user_bpammo(id, weaponID)!=CSW_MAXAMMO[weaponID])
		cs_set_user_bpammo(id, weaponID, CSW_MAXAMMO[weaponID])
	
	return PLUGIN_CONTINUE;
}
