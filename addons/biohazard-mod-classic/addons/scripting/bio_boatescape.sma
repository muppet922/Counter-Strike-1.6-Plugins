#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#tryinclude <biohazard>

#if !defined _biohazard_included
        #assert Biohazard functions file required!
#endif

#define ROCK_HEALTH "2500"
#define BOAT_SPEED "265"
#define LIFT_DELAY "5"

#define REMOVE_BLOCKADE 1
#define DELAY_CHOPPER 1
#define TASKID_ARRIVAL 646

enum
{
	STATUS_NONE = 0,
	STATUS_ARRIVING,
	STATIS_ARRIVED
}

new g_messages[][] = 
{
	"%s has called for rescue. The chopper will be arriving shortly!",
	"The chopper is on its way!",
	"The chopper is arriving!"
}

new g_sounds[][] = 
{
	"events/tutor_msg.wav",
	"radio/getout.wav"
}

new g_button, g_status, g_mapname[32], cvar_rescuetime

public plugin_precache()
{
	register_plugin("boat escape", "0.1", "cheap_suit")	
	is_biomod_active() ? plugin_precache2() : pause("ad")
}

public plugin_precache2()
{
	get_mapname(g_mapname, 31)
	
	if(equali(g_mapname, "zm_boatescape"))
	{
		register_forward(FM_KeyValue, "fwd_keyvalue")
		
		for(new i = 0; i < sizeof g_sounds; i++)
			precache_sound(g_sounds[i])
	}
}

#if DELAY_CHOPPER
public plugin_init()
{
	if(equali(g_mapname, "zm_boatescape") && is_biomod_active())
	{
		cvar_rescuetime = register_cvar("bh_rescuetime", "20.0")
		register_event("HLTV", "event_newround", "a", "1=0", "2=0")
		RegisterHam(Ham_Use, "func_button", "bacon_use")
	}
}
#endif

public bacon_use(ent, caller, activator, use_type, Float:value)
{
	if(ent != g_button)
		return HAM_IGNORED
	
	if(is_user_zombie(caller))
		return HAM_SUPERCEDE
	
	if(g_status == STATIS_ARRIVED)
		return HAM_IGNORED
	
	switch(g_status)
	{
		case 0:
		{
			g_status = STATUS_ARRIVING
			
			static name[32]
			get_user_name(caller, name, 31)
			
			client_print(0, print_chat, g_messages[0], name)
			client_cmd(0, "spk %s", g_sounds[0])
			
			set_task(get_pcvar_float(cvar_rescuetime), "task_arrival", TASKID_ARRIVAL)
		}
		case 1: client_print(caller, print_chat, g_messages[1])
	}
	return HAM_SUPERCEDE
}

public task_arrival()
{
	if(g_status != STATUS_ARRIVING)
		return
	
	g_status = STATIS_ARRIVED

	client_print(0, print_chat, g_messages[2])
	client_cmd(0, "spk %s", g_sounds[1])
	
	ExecuteHam(Ham_Use, g_button, 0, 0, 2, 1.0)
}

public event_newround()
{
	g_status = STATUS_NONE
	remove_task(TASKID_ARRIVAL)
}

public fwd_keyvalue(ent, kvd) 
{
	if(!pev_valid(ent))
		return FMRES_IGNORED
	
        static classname[32]
	get_kvd(kvd, KV_ClassName, classname, 31)

	static keyname[32]
	get_kvd(kvd, KV_KeyName, keyname, 31)
	
	static value[32]
        get_kvd(kvd, KV_Value, value, 31)
	
	if(equal(classname, "func_button"))
	{
		if(equal(keyname, "delay"))
			set_kvd(kvd, KV_Value, LIFT_DELAY)
		
		if(equal(value, "BEPTUK"))
			g_button = ent
	}
	
	if(equal(classname, "func_breakable"))
	{
		if(equal(keyname, "health"))
		{
			if(equal(value, "600"))
				set_kvd(kvd, KV_Value, ROCK_HEALTH)
			#if REMOVE_BLOCKADE
			else if(equal(value, "1"))
			{
				engfunc(EngFunc_RemoveEntity, ent)
				return FMRES_SUPERCEDE
			}
			#endif
		}
	}
	else if(equal(classname, "func_tracktrain") || equal(classname, "path_track"))
	{
		static bool:chopper = false
		if(equal(keyname, "targetname") && equal(value, "Vertolet"))
			chopper = true
		
		else if(equal(keyname, "speed") && !chopper)
			set_kvd(kvd, KV_Value, BOAT_SPEED)
	}
	return FMRES_IGNORED
}
