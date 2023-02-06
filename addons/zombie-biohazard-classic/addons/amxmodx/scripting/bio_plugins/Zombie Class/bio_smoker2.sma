#include <amxmodx>
#include <biohazard>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

#define PLUGIN  "[Bio] Zombie: Smoker"
#define AUTHOR  "TEST"
#define VERSION "1.0"

#define ICON_HIDE 0
#define ICON_SHOW 1
#define ICON_FLASH 2

#define D_ZOMBIE_NAME "Zombie Smoker [Drag]"
#define D_ZOMBIE_DESC "Can drag players Press [F]"
#define D_PLAYER_MODEL "models/player/linkcs_zombie4/linkcs_zombie4.mdl"
#define D_CLAWS "models/player/linkcs_zombie4/v_knife_zombie_smoker.mdl"

//Sounds
new g_sndMiss[] = "biohazard/smoker/Smoker_TongueHit_miss.wav"
new g_sndDrag[] = "biohazard/smoker/Smoker_TongueHit_drag.wav"


//Some vars
new g_hooked[33], g_hooksLeft[33], g_unable2move[33], g_ovr_dmg[33]
new Float:g_lastHook[33]
new bool: g_bind_use[33] = false, bool: g_drag_i[33] = false

//Cvars
new cvar_maxdrags, cvar_dragspeed, cvar_cooldown, cvar_dmg2stop, cvar_mates, cvar_unb2move;

//Menu keys
new g_class
new g_Line

new const Tag[  ] = "[BIO-SMOKER]";

public plugin_precache( )
{
	precache_model(D_PLAYER_MODEL)
	precache_model(D_CLAWS)
	precache_sound(g_sndDrag)
	precache_sound(g_sndMiss)
	g_Line = precache_model("sprites/zbeam4.spr")
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	is_biomod_active(  ) ? plugin_init2(  ) : pause( "ad" );
}

public plugin_init2(  ) {
	
	cvar_dragspeed = register_cvar("bio_smoker_dragspeed", "230")
	cvar_maxdrags = register_cvar("bio_smoker_maxdrags", "3")
	cvar_cooldown = register_cvar("bio_smoker_cooldown", "10")
	cvar_dmg2stop = register_cvar("bio_smoker_dmg2stop", "75")
	cvar_mates = register_cvar("bio_smoker_mates", "0")
	cvar_unb2move = register_cvar("bio_smoker_unable_move", "1")

	register_clcmd("+drag","drag_start", ADMIN_USER, "bind ^"key^" ^"+drag^"")
	register_clcmd("-drag","drag_end")
	
	register_event("ResetHUD", "newSpawn", "b")
	register_event("DeathMsg", "smoker_death", "a")
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	g_class = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)
	
	if(g_class != -1)
	{
		set_class_data(g_class, DATA_HEALTH, 250.0)
		set_class_data(g_class, DATA_SPEED, 300.0)
		set_class_data(g_class, DATA_GRAVITY, 1.0)
		set_class_data(g_class, DATA_ATTACK, 1.6)
		set_class_data(g_class, DATA_REGENDLY, 0.15)
		set_class_data(g_class, DATA_KNOCKBACK, 1.0)
		set_class_pmodel(g_class, D_PLAYER_MODEL)
		set_class_wmodel(g_class, D_CLAWS)
	}
	
}

// added by YONTU
public plugin_natives()
{
	// Player specific natives
	register_native("bio_set_user_drag", "native_set_user_drag", 1);
	register_native("bio_get_user_drag", "native_get_user_drag", 1);
}

public native_set_user_drag(id, value) g_hooksLeft[id] = value;
public native_get_user_drag(id) return g_hooksLeft[id];

public event_infect(victim, infector) {
	
	if(get_user_class(victim) == g_class){
		
		g_hooksLeft[victim] = get_pcvar_num(cvar_maxdrags)
		ColorChat(victim,"!g%s!y You are now a !tZombie Smoker. !yPress !g[F] !yto drag !tHumans.", Tag)
		client_cmd( victim, "bind F +drag" );
	}

	// bug fixed by YONTU
	if(get_user_class(infector) == g_class && g_hooked[victim] && is_user_zombie(victim))
		drag_end(victim);
	
	return PLUGIN_CONTINUE
}

public newSpawn(id)
{
	if (g_hooked[id])
		drag_end(id)
}
public drag_start(id) // starts drag, checks if player is Smoker, checks cvars
{		
	if (is_user_zombie(id) && (get_user_class(id) == g_class) && !g_drag_i[id]) {
		
		static Float:cdown
		cdown = get_pcvar_float(cvar_cooldown)
		
		if (!is_user_alive(id)) {
			ColorChat(id,"!g%s!t You can't drag if you are dead !", Tag)
			return PLUGIN_HANDLED
		}
		
		if (g_hooksLeft[id] <= 0) {
			ColorChat(id,"!g%s!t You can't drag anymore !", Tag)
			return PLUGIN_HANDLED
		}
		
		if (get_gametime() - g_lastHook[id] < cdown) {
			ColorChat(id,"!g%s!y Wait !t[%.f] sec.!y to drag again.", Tag, get_pcvar_float(cvar_cooldown) - (get_gametime() - g_lastHook[id]))
			return PLUGIN_HANDLED
		}
		
		new hooktarget, body
		get_user_aiming(id, hooktarget, body)
		
		if (is_user_alive(hooktarget)) {
			if (!is_user_zombie(hooktarget))
			{
				
				g_hooked[id] = hooktarget
				emit_sound(hooktarget, CHAN_BODY, g_sndDrag, 1.0, ATTN_NORM, 0, PITCH_HIGH)
			}
			else
			{
				if (get_pcvar_num(cvar_mates) == 1)
				{
					g_hooked[id] = hooktarget
					emit_sound(hooktarget, CHAN_BODY, g_sndDrag, 1.0, ATTN_NORM, 0, PITCH_HIGH)
				}
				else
				{
					ColorChat(id,"!g%s!t You can't drag zombies!", Tag)
					return PLUGIN_HANDLED
				}
			}
			
			if (get_pcvar_float(cvar_dragspeed) <= 0.0)
				cvar_dragspeed = 1
			
			new parm[2]
			parm[0] = id
			parm[1] = hooktarget
			
			set_task(0.1, "smoker_reelin", id, parm, 2, "b")
			harpoon_target(parm)
			
			g_hooksLeft[id]--
			ColorChat(id,"!g%s!y You can drag !t[%d]!y more times!", Tag, g_hooksLeft[id])
			g_drag_i[id] = true
			
			if(get_pcvar_num(cvar_unb2move) == 1)
				g_unable2move[hooktarget] = true
			
			if(get_pcvar_num(cvar_unb2move) == 2)
				g_unable2move[id] = true
			
			if(get_pcvar_num(cvar_unb2move) == 3)
			{
				g_unable2move[hooktarget] = true
				g_unable2move[id] = true
			}
			} else {
			g_hooked[id] = 33
			noTarget(id)
			emit_sound(hooktarget, CHAN_BODY, g_sndMiss, 1.0, ATTN_NORM, 0, PITCH_HIGH)
			g_drag_i[id] = true
			g_hooksLeft[id]--
			ColorChat(id,"!g%s!y You can drag !t %d!y more times!", Tag, g_hooksLeft[id] )
		}
	}
	else
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}
public smoker_reelin(parm[]) // dragging player to smoker
{
	new id = parm[0]
	new victim = parm[1]
	
	if (!g_hooked[id] || !is_user_alive(victim))
	{
		drag_end(id)
		return
	}
	
	new Float:fl_Velocity[3]
	new idOrigin[3], vicOrigin[3]
	
	get_user_origin(victim, vicOrigin)
	get_user_origin(id, idOrigin)
	
	new distance = get_distance(idOrigin, vicOrigin)
	
	if (distance > 1) {
		new Float:fl_Time = distance / get_pcvar_float(cvar_dragspeed)
		
		fl_Velocity[0] = (idOrigin[0] - vicOrigin[0]) / fl_Time
		fl_Velocity[1] = (idOrigin[1] - vicOrigin[1]) / fl_Time
		fl_Velocity[2] = (idOrigin[2] - vicOrigin[2]) / fl_Time
		} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}
	
	entity_set_vector(victim, EV_VEC_velocity, fl_Velocity) //<- rewritten. now uses engine
}

public drag_end(id) // drags end function
{
	g_hooked[id] = 0
	beam_remove(id)
	remove_task(id)
	
	if (g_drag_i[id])
		g_lastHook[id] = get_gametime()
	
	g_drag_i[id] = false
	g_unable2move[id] = false
}

public smoker_death() // if smoker dies drag off
{
	new id = read_data(2)
	
	beam_remove(id)
	
	if (g_hooked[id])
		drag_end(id)
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage) // if take damage drag off
{
	if (is_user_alive(attacker) && (get_pcvar_num(cvar_dmg2stop) > 0))
	{
		g_ovr_dmg[victim] = g_ovr_dmg[victim] + floatround(damage)
		if (g_ovr_dmg[victim] >= get_pcvar_num(cvar_dmg2stop))
		{
			g_ovr_dmg[victim] = 0
			drag_end(victim)
			return HAM_IGNORED;
		}
	}
	
	return HAM_IGNORED;
}
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	
	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	
	if (g_bind_use[id] && is_user_zombie(id) && get_user_class(id) == g_class)
	{
		if (!(oldbutton & IN_USE) && (button & IN_USE))
			drag_start(id)
		
		if ((oldbutton & IN_USE) && !(button & IN_USE))
			drag_end(id)
	}
	
	if (!g_drag_i[id]) {
		g_unable2move[id] = false
	}
	
	if (g_unable2move[id] && get_pcvar_num(cvar_unb2move) > 0)
	{
		set_pev(id, pev_maxspeed, 1.0)
	}
	
	return PLUGIN_CONTINUE
}
public harpoon_target(parm[]) // set beam (ex. tongue:) if target is player
{
	new id = parm[0]
	new hooktarget = parm[1]
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)	// TE_BEAMENTS
	write_short(id)
	write_short(hooktarget)
	write_short(g_Line)	// sprite index
	write_byte(0)	// start frame
	write_byte(0)	// framerate
	write_byte(200)	// life
	write_byte(8)	// width
	write_byte(1)	// noise
	write_byte(155)	// r, g, b
	write_byte(155)	// r, g, b
	write_byte(55)	// r, g, b
	write_byte(90)	// brightness
	write_byte(10)	// speed
	message_end()
}

public noTarget(id) // set beam if target isn't player
{
	new endorigin[3]
	
	get_user_origin(id, endorigin, 3)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte( TE_BEAMENTPOINT ); // TE_BEAMENTPOINT
	write_short(id)
	write_coord(endorigin[0])
	write_coord(endorigin[1])
	write_coord(endorigin[2])
	write_short(g_Line) // sprite index
	write_byte(0)	// start frame
	write_byte(0)	// framerate
	write_byte(200)	// life
	write_byte(8)	// width
	write_byte(1)	// noise
	write_byte(155)	// r, g, b
	write_byte(155)	// r, g, b
	write_byte(55)	// r, g, b
	write_byte(75)	// brightness
	write_byte(0)	// speed
	message_end()
}

public beam_remove(id) // remove beam
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)	//TE_KILLBEAM
	write_short(id)	//entity
	message_end()
}

stock ColorChat(const id, const input[], any:...) {
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
	
	replace_all(msg, 190, "!g", "^4");
	replace_all(msg, 190, "!y", "^1");
	replace_all(msg, 190, "!t", "^3");
	
	if(id) players[0] = id;
	else get_players(players, count, "ch"); {
		for(new i = 0; i < count; i++) {
			if(is_user_connected(players[i])) {
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	} 
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
