#include <amxmodx>
//#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <biohazard>

#define PLUGIN "[Bio] Zombie: Light"
#define VERSION "1.0"
#define AUTHOR "TEST" // Original: SonTung0

#define D_ZOMBIE_NAME	"Zombie Ghost"
#define D_ZOMBIE_DESC	"Can be invisible Press [G]"
#define D_PLAYER_MODEL	"models/player/bio30_light/bio30_light.mdl"
#define D_CLAWS		"models/player/bio30_light/claws_light.mdl"
#define D_CLAWS_INVISIBLE	"models/player/bio30_light/claws_light_invisible.mdl"

new g_zclass_light

new cvar_invisible_time, cvar_invisible_timewait, cvar_invisible_dmg
new cvar_invisible_speed, cvar_invisible_gravity, cvar_invisible_alpha

new const zombie_sound_invisible[] = "Biohazard30/bio30_light/light_pressure_start.wav"

new g_invisible[33], g_invisible_wait[33]

// Task offsets
enum (+= 100)
{
	TASK_INVISIBLE = 2000,
	TASK_WAIT_INVISIBLE,
	TASK_BOT_USE_SKILL
}
// IDs inside tasks
#define ID_INVISIBLE (taskid - TASK_INVISIBLE)
#define ID_WAIT_INVISIBLE (taskid - TASK_WAIT_INVISIBLE)
#define ID_INVISIBLE_SOUND (taskid - TASK_INVISIBLE_SOUND)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

new const Tag[  ] = "[Biohazard]";

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	is_biomod_active(  ) ? plugin_init2(  ) : pause( "ad" );
}

public plugin_init2(  ) {
	
	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	// Client Cmd
	register_clcmd("drop", "cmd_invisible")
	
	// Register Cvars
	cvar_invisible_time = register_cvar("bio_invisible_time", "10.0")
	cvar_invisible_timewait = register_cvar("bio_invisible_timewait", "20.0")
	cvar_invisible_dmg = register_cvar("bio_invisible_dmg", "50")
	cvar_invisible_speed = register_cvar("bio_invisible_speed", "390.0")
	cvar_invisible_gravity = register_cvar("bio_invisible_gravity", "0.7")
	cvar_invisible_alpha = register_cvar("bio_invisible_alpha", "1.0")
	
	// Register Class
	register_class_zombie()
}
public plugin_precache()
{
	// wpn model
	engfunc(EngFunc_PrecacheModel, D_PLAYER_MODEL)
	engfunc(EngFunc_PrecacheModel,D_CLAWS)
	engfunc(EngFunc_PrecacheModel, D_CLAWS_INVISIBLE)
	engfunc(EngFunc_PrecacheSound, zombie_sound_invisible)
}

public register_class_zombie()
{
	g_zclass_light = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)

	if(g_zclass_light != -1)
	{
		set_class_data(g_zclass_light, DATA_HEALTH, 480.0)
		set_class_data(g_zclass_light, DATA_SPEED, 320.0)
		set_class_data(g_zclass_light, DATA_GRAVITY, 0.81)
		set_class_data(g_zclass_light, DATA_ATTACK, 1.0)
		set_class_data(g_zclass_light, DATA_REGENDLY, 1.1)
		set_class_data(g_zclass_light, DATA_KNOCKBACK, 1.75)
		set_class_data(g_zclass_light, DATA_NOFLASH, 0.0)
		set_class_data(g_zclass_light, DATA_ONLYVIP, 0.0)
		set_class_pmodel(g_zclass_light, D_PLAYER_MODEL)
		set_class_wmodel(g_zclass_light, D_CLAWS)
	}	
}

public event_infect(victim, assSssa)
{
	if(is_user_zombie(victim) && get_user_class(victim) == g_zclass_light) {

		color_saytext(victim, "^x04%s ^x01Press^x03 [G]^x01 to become invisible. Everytime you use your power, you will sacrifice some of your Health.", Tag)
	}
}

public event_round_start()
{
	for (new id = 0; id < get_maxplayers(); id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
	}
}
public logevent_round_start()
{
	for (new id = 0; id < get_maxplayers(); id++)
	{
		if (!is_user_connected(id)) continue;
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}
	}
}
public Death()
{
	new victim = read_data(2) 
	reset_value_player(victim)
}
public client_connect(id)
{
	reset_value_player(id)
}
public client_disconnect(id)
{
	reset_value_player(id)
}
reset_value_player(id)
{
	if (task_exists(id+TASK_INVISIBLE)) remove_task(id+TASK_INVISIBLE)
	if (task_exists(id+TASK_WAIT_INVISIBLE)) remove_task(id+TASK_WAIT_INVISIBLE)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)

	g_invisible[id] = 0
	g_invisible_wait[id] = 0
}

// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_invisible(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

// #################### INVISIBLE PUBLIC ####################
// cmd invisible
public cmd_invisible(id)
{
	if (!is_user_alive(id)) return PLUGIN_CONTINUE

	new health = get_user_health(id) - get_pcvar_num(cvar_invisible_dmg)
	if (is_user_zombie(id) && get_user_class(id) == g_zclass_light && health > 0 && !g_invisible[id] && !g_invisible_wait[id])
	{
		// set invisible
		g_invisible[id] = 1
		set_wpnmodel(id)
		
		// set task
		if (task_exists(id+TASK_INVISIBLE)) remove_task(id+TASK_INVISIBLE)
		set_task(get_pcvar_float(cvar_invisible_time), "RemoveInvisible", id+TASK_INVISIBLE)
		
		// set health when invisible
		fm_set_user_health(id, health)
		
		// play sound
		PlayEmitSound(id, zombie_sound_invisible)

		color_saytext(id, "^x04%s^x01 You are^x03 Invisible.^x01 You will be visible After^x03 %i^x01 seconds.", Tag, fnFloatToNum(get_pcvar_float(cvar_invisible_time)))
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public RemoveInvisible(taskid)
{
	new id = ID_INVISIBLE
	
	// remove invisible
	g_invisible[id] = 0
	set_wpnmodel(id)
	fm_set_rendering(id)
	if (task_exists(taskid)) remove_task(taskid)
	
	// send msg
	color_saytext(id, "^x04%s^x01 You have became^x03 Visible^x01. Humans can see you, watch out !", Tag)

	// set speed & gravity
	set_pev(id, pev_maxspeed, get_class_data(g_zclass_light, DATA_SPEED))
	set_pev(id, pev_gravity, get_class_data(g_zclass_light, DATA_GRAVITY))
	
	// set time wait
	g_invisible_wait[id] = 1
	if (task_exists(id+TASK_WAIT_INVISIBLE)) remove_task(id+TASK_WAIT_INVISIBLE)
	set_task(get_pcvar_float(cvar_invisible_timewait), "RemoveWaitInvisible", id+TASK_WAIT_INVISIBLE)
}
public RemoveWaitInvisible(taskid)
{
	new id = ID_WAIT_INVISIBLE
	g_invisible_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) return;
	
	if (is_user_zombie(id) && get_user_class(id) == g_zclass_light)
	{
		// check invisible
		if (g_invisible[id] && !g_invisible_wait[id])
		{
			// set invisible
			new Float:velocity[3], velo, alpha
			pev(id, pev_velocity, velocity)
			velo = sqroot(floatround(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2]))/10
			alpha = floatround(float(velo)*get_pcvar_num(cvar_invisible_alpha))
			fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, alpha)	
		}

	}

	return;
}
// set speed
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id)) return;
	
	if (is_user_zombie(id) && get_user_class(id) == g_zclass_light && g_invisible[id])
	{
		// set gravity speed when invisible
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_invisible_speed))
		set_pev(id, pev_gravity, get_pcvar_float(cvar_invisible_gravity))
	}
}
set_wpnmodel(id)
{
	if (!is_user_alive(id)) return;
	
	// set model wpn invisible
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		if (g_invisible[id]) set_pev(id, pev_viewmodel2, D_CLAWS_INVISIBLE)
		else set_pev(id, pev_viewmodel2, D_CLAWS)
	}
	
}
PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}
fnFloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)
	
	return num
}
fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}

stock color_saytext( const id, const input[  ], any:... ) {

	new iCount = 1, szPlayers[ 32 ];
	static szMsg[ 191 ];

	vformat( szMsg, 190, input, 3 );

	replace_all( szMsg, 190, "!4", "^4" );
	replace_all( szMsg, 190, "!1", "^1" );
	replace_all( szMsg, 190, "!3", "^3" );

	if( id ) {
		szPlayers[ 0 ] = id;
	} else {
		get_players( szPlayers, iCount, "ch" );
	}

	for( new i = 0; i < iCount; i++ ) {

		if( is_user_connected( szPlayers[ i ] ) ) {

			message_begin( MSG_ONE_UNRELIABLE, get_user_msgid( "SayText" ), _, szPlayers[ i ] );
			write_byte( szPlayers[ i ] );
			write_string( szMsg );
			message_end(  );
		}
	}
}