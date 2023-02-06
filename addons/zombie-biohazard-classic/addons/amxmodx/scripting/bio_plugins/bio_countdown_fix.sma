#include <amxmodx>
#include <dhudmessage>

const TASK_SOUND = 887

#define ID_SOUND (taskid - TASK_SOUND)

static const sound_list[][] =
{
	"biohazard/new_count/timer01.wav",
	"biohazard/new_count/timer02.wav",
	"biohazard/new_count/timer03.wav",
	"biohazard/new_count/timer04.wav",
	"biohazard/new_count/timer05.wav",
	"biohazard/new_count/timer06.wav",
	"biohazard/new_count/timer07.wav",
	"biohazard/new_count/timer08.wav",
	"biohazard/new_count/timer09.wav",
	"biohazard/new_count/timer10.wav"
}

static const sound_list2[] = "biohazard/new_count/zombie_start.wav"

new g_count, g_time

public plugin_precache()
{
	for(new i = 0 ; i < sizeof sound_list ; i++)
		precache_sound(sound_list[i])
	precache_sound(sound_list2)
}

public plugin_init() 
{
	register_plugin("[Bio] Countdown Fix", "1.0", "P.Of.Pw")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
}

public event_round_start(id)
{
	remove_task(id+TASK_SOUND)
	
	g_time = 10
	g_count = 9

	set_task(1.0, "countdown_sound", id+TASK_SOUND, _, _, "b")
}

public client_disconnect(id)
	remove_task(id+TASK_SOUND)

public countdown_sound(taskid)
{
	static id
	id = ID_SOUND

	client_cmd(id, "spk %s", sound_list[g_count])
	g_count--
	
	set_dhudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1)
	show_dhudmessage(id, "[%i]^nPrepare for Zombie Outbreak", g_time) 
	
	--g_time
	
	if(g_time < 1)
	{
		client_cmd(id, "spk %s", sound_list2)
		remove_task(id+TASK_SOUND)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
