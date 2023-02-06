/*
*   _______     _      _  __          __
*  | _____/    | |    | | \ \   __   / /
*  | |         | |    | |  | | /  \ | |
*  | |         | |____| |  | |/ __ \| |
*  | |   ___   | ______ |  |   /  \   |
*  | |  |_  |  | |    | |  |  /    \  |
*  | |    | |  | |    | |  | |      | |
*  | |____| |  | |    | |  | |      | |
*  |_______/   |_|    |_|  \_/      \_/
*
*
*
*  Last Edited: 12-31-07
*
*  ============
*   Changelog:
*  ============
*
*  v2.0
*    -Added color to floating weapons
*
*  v1.0
*    -Initial Release
*
*/

#define VERSION	"2.0"

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fun>

new maxplayers
new speed_pcvar
new toggle_pcvar

public plugin_init()
{
	register_plugin("UT Style Floating Weapons",VERSION,"GHW_Chronic")

	speed_pcvar = register_cvar("FW_speed","25.0")
	toggle_pcvar = register_cvar("FW_enabled","1")

	register_forward(FM_SetModel,"W_Model_Hook",1)
	register_touch("weaponbox","worldspawn","touch")
	set_task(1.0,"newgame")

	set_task(0.1,"force_spin",0,"",0,"b")

	maxplayers = get_maxplayers()
}

public W_Model_Hook(ent,model[])
{
	if(get_pcvar_num(toggle_pcvar) && pev_valid(ent))
	{
		static classname[32]
		pev(ent,pev_classname,classname,31)
		if(equali(classname,"weaponbox"))
		{
			set_pev(ent,pev_renderfx,kRenderFxGlowShell)
			switch(random_num(1,4))
			{
				case 1: set_pev(ent,pev_rendercolor,Float:{0.0,0.0,255.0})
				case 2: set_pev(ent,pev_rendercolor,Float:{0.0,255.0,0.0})
				case 3: set_pev(ent,pev_rendercolor,Float:{255.0,0.0,0.0})
				case 4: set_pev(ent,pev_rendercolor,Float:{255.0,255.0,255.0})
			}
			static Float:angles[3]
			pev(ent,pev_angles,angles)
			angles[0] -= 90.0
			angles[1] += 45.0
			set_pev(ent,pev_angles,angles)
		}
	}
}

public touch(weaponbox,worldspawn)
{
	if(get_pcvar_num(toggle_pcvar) && pev_valid(weaponbox))
	{
		
		set_pev(weaponbox,pev_movetype,MOVETYPE_FLY)
		static Float:origin[3]
		pev(weaponbox,pev_origin,origin)
		origin[2] += 30.0
		set_pev(weaponbox,pev_origin,origin)
	}
}

public force_spin()
{
	if(get_pcvar_num(toggle_pcvar))
	{
		static ent, classname[16], Float:angles[3]
		ent = engfunc(EngFunc_FindEntityInSphere,maxplayers,Float:{0.0,0.0,0.0},4800.0)
		while(ent)
		{
			if(pev_valid(ent))
			{
				pev(ent,pev_classname,classname,15)
				if(containi(classname,"armoury")!=-1 || containi(classname,"weaponbox")!=-1)
				{
					pev(ent,pev_angles,angles)
					angles[1] += get_pcvar_float(speed_pcvar) / 10.0
					if(angles[1]>=180.0)
					{
						angles[1] -= 360.0
					}
					set_pev(ent,pev_angles,angles)
				}
			}
			ent = engfunc(EngFunc_FindEntityInSphere,ent,Float:{0.0,0.0,0.0},4800.0)
		}
	}
}

public newgame()
{
	if(get_pcvar_num(toggle_pcvar))
	{
		static ent, classname[8], Float:angles[3]
		ent = engfunc(EngFunc_FindEntityInSphere,maxplayers,Float:{0.0,0.0,0.0},4800.0)
		while(ent)
		{
			if(pev_valid(ent))
			{
				pev(ent,pev_classname,classname,7)
				if(containi(classname,"armoury")!=-1)
				{
					set_pev(ent,pev_renderfx,kRenderFxGlowShell)
					switch(random_num(1,4))
					{
						case 1: set_pev(ent,pev_rendercolor,Float:{0.0,0.0,255.0})
						case 2: set_pev(ent,pev_rendercolor,Float:{0.0,255.0,0.0})
						case 3: set_pev(ent,pev_rendercolor,Float:{255.0,0.0,0.0})
						case 4: set_pev(ent,pev_rendercolor,Float:{255.0,255.0,255.0})
					}
					pev(ent,pev_angles,angles)
					angles[0] -= 90.0
					angles[1] += 45.0
					set_pev(ent,pev_angles,angles)
					touch(ent,0)
				}
			}
			ent = engfunc(EngFunc_FindEntityInSphere,ent,Float:{0.0,0.0,0.0},4800.0)
		}
	}
}
