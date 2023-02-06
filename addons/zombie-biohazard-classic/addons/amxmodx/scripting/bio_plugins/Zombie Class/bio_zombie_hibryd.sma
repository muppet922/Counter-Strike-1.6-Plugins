#include <amxmodx>
#include <biohazard>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>

#define IsPlayer(%1)	(1<=%1<=32)

#define PWNTIME get_pcvar_num(eye_pwntime)
#define EYETIMES get_pcvar_num(eye_times)
#define RADIUS get_pcvar_num(eye_radius)
#define DELAY get_pcvar_float(eye_firedelay)

#define R get_pcvar_num(g_cvar_red)
#define G get_pcvar_num(g_cvar_green)
#define B get_pcvar_num(g_cvar_blue)

new g_BodyHits[33][33]
new bool:g_restart_attempt[33];
new bool:g_bEyeUser[33];
new bool:g_bInRadius[33];
new g_last_weapon[33];
new g_last_clip[33];
new g_sprite_bullet;
new gEyeCount[33];
new g_iMaxPlayers;

new g_cvar_shotguninacc;
new g_cvar_shotgunburst;
new g_cvar_inacc;
new g_cvar_bulletspeed;
new g_cvar_sniperspeed;
new g_cvar_red;
new g_cvar_green;
new g_cvar_blue;
new g_cvar_intensity;
new eye_pwntime;
new eye_times;
new eye_radius;
new eye_glow;
new eye_team;
new eye_firedelay

#define PLUGIN  "[Bio] Zombie: Hibryd"
#define AUTHOR  "TR&UG"
#define VERSION "1.0"

#define ZOMBIE_NAME	"\wZombie Experiment\r[\yHibryd\r]"					//Zombie Name
#define ZOMBIE_DESC	"Time Freeze + Fast Run"	//Zombie Description
#define ZOMBIE_MODEL	"models/player/bio30_zombie/bio30_zombie.mdl"    //Zombie Model
#define ZOMBIE_CLAWS	"models/player/bio30_metamorph/v_zm2.mdl"	//Claws Model

#define ZOMBIE_HEALTH		200.0	//Health value
#define ZOMBIE_SPEED		300.0	//Speed value
#define ZOMBIE_GRAVITY		0.9	//Gravity multiplier
#define ZOMBIE_ATTACK		1.5	//Zombie damage multiplier
#define ZOMBIE_REGENDLY		0.20	//Regeneration delay value
#define ZOMBIE_KNOCKBACK	0.85	//Knockback multiplier

#define TASKID_FASTRUN_HEARTBEAT	12314
#define TASKID_START_POWER		2131

new FastRun_Sound[][] = {
	"bio32/FastRunStart.wav"
}

new const Tag[  ] = "[Biohazard]";

new Class, FastRun[33], FastRun_Countdown[33]
new cvar_fastrun_duration, cvar_fastrun_countdown, cvar_fastrun_speed;

//############   stocks      #####################

public fm_set_user_hitzones(index, target, body)
{
	if ( !index && !target ) 
	{
		for ( new i = 1 ; i <= g_iMaxPlayers ; i++ ) 
			for (new j = 1 ; j <= g_iMaxPlayers ; j++ ) 
				g_BodyHits[i][j] = body
	}
	else if ( !index && target )
	{
		for ( new i = 1 ; i <= g_iMaxPlayers ; i++ ) 
			g_BodyHits[i][target] = body
	}
	else if ( index && !target ) 
	{
		for ( new i = 1 ; i <= g_iMaxPlayers ; i++ ) 
			g_BodyHits[index][i] = body
	}
	else if ( index && target ) 
	{
		g_BodyHits[index][target] = body
	}
}

public fm_hitzones_reset(index)
{
	for ( new i = 1 ; i <= g_iMaxPlayers ; i++ )
	{
		g_BodyHits[index][i] =	(1<<HIT_GENERIC) | (1<<HIT_HEAD) | (1<<HIT_CHEST) | 
					(1<<HIT_STOMACH) | (1<<HIT_LEFTARM) | (1<<HIT_RIGHTARM)| 
					(1<<HIT_LEFTLEG) | (1<<HIT_RIGHTLEG)
	}
				
} 
//################end of stocks###################

public fw_TraceLine(Float:v1[3], Float:v2[3], NoMonsters, shooter, ptr)
{

	if ( !g_bInRadius[shooter])
		return FMRES_IGNORED
	if ( !IsPlayer(shooter) )
		return FMRES_IGNORED

	new iPlayerHit = get_tr2(ptr,TR_pHit)
	
	if ( !IsPlayer(iPlayerHit) )
		 return FMRES_IGNORED
		 
	new iHitzone = get_tr2(ptr,TR_iHitgroup)
	
	if ( !(g_BodyHits[shooter][iPlayerHit] & (1 << iHitzone)) )
		set_tr2(ptr,TR_flFraction,1.0)
	

	return FMRES_IGNORED
}

public fwdPlayerSpawn(id){
	if(is_user_alive(id) ) {
		gEyeCount[id] = 0
		removeeye(id)
	}
	if (g_restart_attempt[id])
	{
		g_restart_attempt[id] = false;
		return;
	}
}


public client_connect(id)
{
	fm_hitzones_reset(id);
}

public Eye(id) {
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	if( g_bEyeUser[id]) {
		client_print(id,print_chat,"You are allready using Time Freeze !")
		return PLUGIN_HANDLED
	} else  {
		for( new i = 1; i <= g_iMaxPlayers; i++ )
		{
			if(is_user_alive(i)) {
				if( (id != i) && (i != id) && entity_range(i, id) <= RADIUS ) {
					if (g_bEyeUser[i]) {
						client_print(id,print_chat,"Someone is already using the Time Freeze in %d unit radius!", RADIUS)
						return PLUGIN_HANDLED
					}
				}
			}
		}
	}

		
	if( gEyeCount[id] <= EYETIMES ) { 
		gEyeCount[id]++
		if( (EYETIMES - gEyeCount[id]) < 0 ) {
			client_print(id,print_chat,"You cant use the Time Freeze anymore in this round!")
			return PLUGIN_HANDLED
		}
		g_bInRadius[id] = true;
		fm_set_user_hitzones(id, 0, 0);
		fm_set_user_hitzones(0, id, 0);
		set_task(10.0,"removeeye",id)
		g_bEyeUser[id] = true;
		client_print(id,print_chat,"Time Freeze is enabled , you have %d seconds to do it !",  PWNTIME)
		if(EYETIMES != 1)	
			client_print(id,print_chat," %d Time Freeze usages left !", EYETIMES - gEyeCount[id] )

		for( new i = 1; i <= g_iMaxPlayers; i++ )
		{
			if(is_user_alive(i) && (id != i) && (i != id)) {
				if( (entity_range(i, id) <= RADIUS) && ( (get_pcvar_num( eye_team ) && get_user_team(id) != get_user_team(i) ) || !(get_pcvar_num( eye_team )) )  ) {
					seteye(i)
					set_task(10.0,"removeeye",i)
					static name[32];
					get_user_name(id, name, 31);
					client_print(i,print_chat," You are under the Time Freeze effect by %s!", name )
				}
				else g_bInRadius[i] = false;
			}
		}


	}
	else {
		client_print(id,print_chat,"You cant use the Time Freeze anymore in this round!")
	}

	return PLUGIN_HANDLED
}

public seteye(id) {
	g_bInRadius[id] = true;
	fm_set_user_hitzones(id, 0, 0);
	fm_set_user_hitzones(0, id, 0);
	if(get_pcvar_num(eye_glow) && !g_bEyeUser[id] )
		set_user_rendering(id,kRenderFxGlowShell, R, G, B,kRenderNormal,50);
	if(get_pcvar_num(eye_glow) && g_bEyeUser[id] )
		set_user_rendering(id,kRenderFxGlowShell, G, R, B,kRenderNormal,50);
	set_pev(id, pev_maxspeed, 120.0)	
	set_pev(id, pev_gravity, 0.3) 
}

public removeeye(id) {
	if ( g_bInRadius[id] )
		client_print(id,print_chat,"Time Freeze was disabled!")
	g_bEyeUser[id] = false;
	g_bInRadius[id] = false;

	if(get_pcvar_num(eye_glow) && is_user_alive(id) )
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0,kRenderNormal,50);
	set_pev(id, pev_gravity, 1.0) 
	set_pev(id, pev_maxspeed, 250.0)
	fm_set_user_hitzones(id, 0, 255);
	fm_set_user_hitzones(0, id, 255);
}


public FwdCmdStart( id, ucHandle ) {
	if( !is_user_alive( id )  ) {
		return FMRES_IGNORED
	}
	static buttons, Float:jumpoff_time[33] ;
	buttons = get_uc( ucHandle, UC_Buttons );
	/* FAIL :(
	oldbuttons = pev(id, pev_oldbuttons); 
	ammo = cs_get_weapon_ammo( get_pdata_cbase( id, 373 ) );
	if ( buttons & IN_ATTACK && !(oldbuttons & IN_ATTACK)  ) { 
		buttons &= ~IN_ATTACK
		set_uc(ucHandle,UC_Buttons,buttons)
		set_animation(id, 0)
		if (ammo > 0 )
			cs_set_weapon_ammo(get_pdata_cbase( id, 373 ), ammo - 1)
		shottime[id] = get_gametime()

	} 
	*/
	for( new i = 1; i <= g_iMaxPlayers; i++ )
	{
		if(g_bEyeUser[i] && i != id && id != i && is_user_alive( i )  )  {

			if(  !g_bInRadius[id] && !g_bEyeUser[id] 
			&& ( (get_pcvar_num( eye_team ) && get_user_team(id) != get_user_team(i) ) || !(get_pcvar_num( eye_team )) ) ) 
			{
				if ( entity_range(id, i) <= RADIUS)  {
					g_bInRadius[id] = true
					seteye(id)
					client_print(id,print_chat,"You got into Time Freeze radius!")
				}
			} 
			else if(g_bInRadius[id] && ( entity_range(id, i) >= RADIUS && (id != i) && (i != id)) && !g_bEyeUser[id] ) {
				client_print(id,print_chat,"You got away from Time Freeze radius!")
				removeeye(id)
			}
			
		} 

	}
	if( !g_bInRadius[id] || g_bEyeUser[id]) {
		return FMRES_IGNORED
	}

	if(  pev( id, pev_flags ) & FL_ONGROUND  &&  buttons & IN_JUMP  ) {
		set_pev(id, pev_gravity, 1.0) ;
		jumpoff_time[id] = 0.0;
		jumpoff_time[id] = get_gametime( );
	}
	if( 0.02 > jumpoff_time[id] &&  !(pev( id, pev_flags ) & FL_ONGROUND) ) {
		set_pev(id, pev_gravity, 0.1);
	}
	else if( 0.8 > jumpoff_time[id]  ) 
		jumpoff_time[id] = 0.0;

	return FMRES_IGNORED
}




public clcmd_fullupdate()
{
	return PLUGIN_HANDLED_MAIN;
}


public event_restart_attempt()
{
	new num, p;
	static players[32];
	get_players(players, num, "a");

	for (p = 0; p < num; ++p)
		g_restart_attempt[players[p]] = true;
}


public event_weaponfire(id)
{
	if ( !g_bInRadius[id])
		return;

	
	new weapon = read_data(2);
	new clip = read_data(3);


	if (g_last_weapon[id] == 0)
		g_last_weapon[id] = weapon;

	if ((g_last_clip[id] > clip) && (g_last_weapon[id] == weapon))
	{
		new inacc=floatround(get_pcvar_num(g_cvar_bulletspeed)*(1.0/float(get_pcvar_num(g_cvar_inacc))));
		new shots=1;
		if(weapon==CSW_M3||weapon==CSW_XM1014){
			shots=get_pcvar_num(g_cvar_shotgunburst);
			inacc=floatround(get_pcvar_num(g_cvar_bulletspeed)*(1.0/float(get_pcvar_num(g_cvar_shotguninacc))));
		}
		new i;
		new entity
		for(i=0;i<shots;++i){
			
			entity = fm_create_entity("info_target");
			if (entity > 0)
			{
				new Float:angle[3], Float:origin[3], Float:aimvec[3];
				new Float:minbox[3] = {-1.0, -1.0, -1.0};
				new Float:maxbox[3] = {1.0, 1.0, 1.0};

				pev(id, pev_origin, origin);
				origin[2] += 12.0;

				set_pev(entity, pev_classname, "bullet_x");
				fm_entity_set_model(entity, "models/shell.mdl");

				static weaponname[32];
				get_weaponname(weapon, weaponname, sizeof(weaponname));
				set_pev(entity, pev_targetname, weaponname);

				pev(id, pev_v_angle, angle);

				fm_entity_set_size(entity, minbox, maxbox);
				fm_entity_set_origin(entity, origin);

				set_pev(entity, pev_angles, angle);
				set_pev(entity, pev_v_angle, angle);

				set_pev(entity, pev_effects, 2);
				set_pev(entity, pev_solid, SOLID_TRIGGER);
				set_pev(entity, pev_movetype, MOVETYPE_FLY);
				set_pev(entity, pev_owner, id);
				
				if (weapon != CSW_SCOUT && weapon != CSW_SG550 && weapon != CSW_AWP && weapon != CSW_G3SG1){
					velocity_by_aim(id, get_pcvar_num(g_cvar_bulletspeed), aimvec);
					aimvec[0]+=inacc/2-random(inacc);
					aimvec[1]+=inacc/2-random(inacc);
					aimvec[2]+=inacc/2-random(inacc);
				}
				else{
					velocity_by_aim(id, get_pcvar_num(g_cvar_sniperspeed), aimvec);
				}
				
				set_pev(entity, pev_velocity, aimvec);

				message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
				write_byte(TE_BEAMFOLLOW);
				write_short(entity);			// Entity to follow
				write_short(g_sprite_bullet);		// Sprite index
				write_byte(20);				// Life
				write_byte(2);				// Line width
				write_byte(get_pcvar_num(g_cvar_red));	// Red
				write_byte(get_pcvar_num(g_cvar_green));// Green
				write_byte(get_pcvar_num(g_cvar_blue));	// Blue
				write_byte(get_pcvar_num(g_cvar_intensity));			// Brightness
				message_end();
			}
		}
	}

	g_last_weapon[id] = weapon;
	g_last_clip[id] = clip;

	if(DELAY <= 1.0 || !weapon || weapon==6 || weapon==29 || weapon>30 || g_bEyeUser[id] ){ 
		return
	} else {
		static weaponname[32],Ent
		get_weaponname(weapon,weaponname,31)
		Ent = fm_find_ent_by_owner(-1,weaponname,id)
		if(Ent)
		{
			static Float:Delay,Float:M_Delay
			Delay = get_pdata_float( Ent, 46, 4) * DELAY
			M_Delay = get_pdata_float( Ent, 47, 4) * DELAY
			if (Delay > 0.0)
			{
				set_pdata_float( Ent, 46, Delay, 4)
				set_pdata_float( Ent, 47, M_Delay, 4)
			}
		}
	}
}

public forward_touch(id, toucher, touched)
{
	for( new i = 1; i <= g_iMaxPlayers; i++ )
	{
		if(!g_bInRadius[i] && i != id && id != i && is_user_alive( id ) )
			return FMRES_IGNORED;
	}

	if ( !pev_valid(toucher)  )
		return FMRES_IGNORED;

	if (pev_valid(toucher) && touched >= 0)
	{
		if(!pev_valid(touched) ) {
			return touched = 0
		}
		!pev_valid(toucher)
		static classname[32];
		static classname2[32];

		pev(toucher, pev_classname, classname, sizeof(classname));
		if (touched>0){ pev(touched, pev_classname, classname2, sizeof(classname2)); }
			

		if(equal(classname, "bullet_x"))
		{
			new attacker = pev(toucher, pev_owner);

			if (touched>0){
				if (is_user_connected(touched) && equal(classname2, "player"))
				{
					if(attacker==touched){
						return FMRES_IGNORED;
					}
					static targetname[32];
					pev(touched, pev_targetname, targetname, sizeof(targetname));

					util_damage(attacker, touched, targetname);
				}
				else if (equal(classname2, "func_breakable")){
					fm_force_use(attacker, touched);
				}else if (equal(classname2, "bullet_x")){
					return FMRES_IGNORED;
				}
			}
			fm_remove_entity(toucher);
		}
	}

	return FMRES_IGNORED;
}

util_damage(attacker, victim, weapon[])
{
	new damage = random_num(15, 30);

	if (equal(weapon[7], "scout") || equal(weapon[7], "sg550") || equal(weapon[7], "g3sg1"))
		damage = random_num(45, 75);
	else if (equal(weapon[7], "awp"))
		damage = random_num(90, 120);

	if (get_user_health(victim) - damage <= 0)
		util_kill(attacker, victim, weapon);
	else if (get_user_team(attacker) != get_user_team(victim) || (get_user_team(attacker) == get_user_team(victim) && get_cvar_num("mp_friendlyfire") == 1))
	{
		fm_fakedamage(victim, weapon, float(damage), DMG_BULLET);

		static origin[3];
		get_user_origin(victim, origin, 0);

		message_begin(MSG_ONE, get_user_msgid("Damage"), {0, 0, 0}, victim);
		write_byte(0);		 // Damage save
		write_byte(damage);	 // Damage take
		write_long(DMG_BULLET);	 // Damage type
		write_coord(origin[0]);	 // X
		write_coord(origin[1]);	 // Y
		write_coord(origin[2]);	 // Z
		message_end();

		if (get_user_team(attacker) == get_user_team(victim))
		{
			static name[32];
			get_user_name(attacker, name, sizeof(name));

			client_print(0, print_chat, "%s attacked a teammate", name);
		}
	}
}

util_kill(killer, victim, weapon[])
{
	if (get_user_team(killer) != get_user_team(victim))
	{
		user_silentkill(victim);
		make_deathmsg(killer, victim, 0, weapon);

		set_user_frags(killer, get_user_frags(killer) + 1);

		new money = cs_get_user_money(killer) + 300;
		if (money >= 16000)
			cs_set_user_money(killer, 16000);
		else
			cs_set_user_money(killer, money, 1);
	}
	else
	{
		if (get_cvar_num("mp_friendlyfire") == 1)
		{
			user_silentkill(victim);
			make_deathmsg(killer, victim, 0, weapon);

			set_user_frags(killer, get_user_frags(killer) - 1);

			new money = cs_get_user_money(killer) - 3300;
			if (money <= 0)
				cs_set_user_money(killer, 0);
			else
				cs_set_user_money(killer, money, 1);
		}
	}

	message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"));
	write_byte(killer);			 // Destination
	write_short(get_user_frags(killer));	 // Frags
	write_short(cs_get_user_deaths(killer)); // Deaths
	write_short(0);				 // Player class
	write_short(get_user_team(killer));	 // Team
	message_end();

	message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"));
	write_byte(victim);			 // Destination
	write_short(get_user_frags(victim));	 // Frags
	write_short(cs_get_user_deaths(victim)); // Deaths
	write_short(0);				 // Player class
	write_short(get_user_team(victim));	 // Team
	message_end();

	static kname[32];
	static vname[32];
	static kteam[10];
	static vteam[10];
	static kauthid[32];
	static vauthid[32];

	get_user_name(killer, kname, sizeof(kname));
	get_user_team(killer, kteam, sizeof(kteam));
	get_user_authid(killer, kauthid, sizeof(kauthid));

	get_user_name(victim, vname, sizeof(vname));
	get_user_team(victim, vteam, sizeof(vteam));
	get_user_authid(victim, vauthid, sizeof(vauthid));

	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
	kname, get_user_userid(killer), kauthid, kteam, 
 	vname, get_user_userid(victim), vauthid, vteam, weapon);
}

public plugin_init() {         
	register_plugin(PLUGIN,AUTHOR,VERSION)
	is_biomod_active() ? plugin_init2() : pause("ad")

	RegisterHam( Ham_Spawn, "player", "fwdPlayerSpawn", 1 ); 
	register_clcmd("say /eye", "Eye")
	register_clcmd("walk", "Eye")
	register_clcmd("fullupdate", "clcmd_fullupdate");
	g_cvar_inacc=register_cvar("bt_inacc","25");
	g_cvar_shotguninacc=register_cvar("eye_shotguninacc","5");
	g_cvar_shotgunburst=register_cvar("eye_shotgunburst","6");
	g_cvar_bulletspeed = register_cvar("eye_bulletspeed", "2000");
	g_cvar_sniperspeed = register_cvar("eye_sniperspeed", "3000");
	g_cvar_red = register_cvar("eye_red", "0");
	g_cvar_green = register_cvar("eye_green", "0");
	g_cvar_blue = register_cvar("eye_blue", "0");
	g_cvar_intensity = register_cvar("eye_intensity", "180");
	eye_pwntime = register_cvar("eye_pwntime", "10");
	eye_times = register_cvar("eye_times", "3");
	eye_glow = register_cvar("eye_glow", "0");
	eye_team = register_cvar("eye_team", "0");
	eye_firedelay = register_cvar("eye_firedelay", "7.7");
	eye_radius = register_cvar("eye_radius", "1000");
	register_event("TextMsg", "event_restart_attempt", "a", "2=#Game_will_restart_in");
	register_event("CurWeapon", "event_weaponfire", "be", "1=1", "2!4", "2!6", "2!9", "2!25", "2!29");
	register_forward(FM_TraceLine,"fw_traceline",1);
	register_forward(FM_Touch,"forward_touch");
	register_forward( FM_CmdStart, "FwdCmdStart" );
	g_iMaxPlayers = get_maxplayers( );
}

public plugin_init2() {
	Class = register_class(ZOMBIE_NAME, ZOMBIE_DESC )
	
	set_class_pmodel(Class, ZOMBIE_MODEL)
	set_class_wmodel(Class, ZOMBIE_CLAWS)
	
	set_class_data(Class, DATA_HEALTH, ZOMBIE_HEALTH);
	set_class_data(Class, DATA_SPEED, ZOMBIE_SPEED);
	set_class_data(Class, DATA_GRAVITY, ZOMBIE_GRAVITY);
	set_class_data(Class, DATA_ATTACK, ZOMBIE_ATTACK);
	set_class_data(Class, DATA_REGENDLY, ZOMBIE_REGENDLY);
	set_class_data(Class, DATA_KNOCKBACK, ZOMBIE_KNOCKBACK);
	
	register_clcmd( "drop", "CMD_FastRun");
	
	register_event("DeathMsg", "EVENT_Death", "a")
	
	register_forward(FM_PlayerPreThink,"FWD_PlayerPreThink")
	
	RegisterHam(Ham_Spawn, "player", "HAM_Spawn_Post", 1);
	
	cvar_fastrun_duration = register_cvar("bio_fastrun_duration", "10.0")
	cvar_fastrun_countdown = register_cvar("bio_fastrun_countdown", "15.0")
	cvar_fastrun_speed = register_cvar("bio_fastrun_speed", "640.0")		
}

public plugin_precache() {

	precache_model(ZOMBIE_CLAWS)
	precache_model(ZOMBIE_MODEL)
	
	for(new i = 0; i < sizeof FastRun_Sound; i++ )
		precache_sound(FastRun_Sound[i]);

	precache_model("models/shell.mdl");
	g_sprite_bullet = precache_model("sprites/zbeam4.spr");
}

public EVENT_Death() {
	FastRun[read_data(2)] = 0
	FastRun_Countdown[read_data(2)] = 0
}

public event_infect(victim, attacker) {
	if(get_user_class(victim) == Class) {
		FastRun[victim] = 0
		FastRun_Countdown[victim] = 0
		remove_task(victim + TASKID_FASTRUN_HEARTBEAT)
		ColorChat(victim, "^x04%s^x01 Apasa pe G^x03 pentru a folosi ^x01 Viteza si Shift^x03  pentru a folosii TimeFreeze^x01.", Tag)
	}
}

public FWD_PlayerPreThink(id) {
	if(is_user_alive(id) && FastRun[id]) {
		if(fm_get_user_maxspeed(id) < get_pcvar_float(cvar_fastrun_speed) && fm_get_user_maxspeed(id) > 1.0)
			fm_set_user_maxspeed(id, get_pcvar_float(cvar_fastrun_speed))
	}
	if(get_user_weapon(id) != CSW_KNIFE && task_exists(id + TASKID_START_POWER))
		remove_task(id + TASKID_START_POWER)
}

public HAM_Spawn_Post(id) {	
	FastRun[id] = 0
	FastRun_Countdown[id] = 0
}

public CMD_FastRun(id) {
	new Float:NextAttack = get_pdata_float(id, 83, 5);
	if(is_user_alive(id) && get_user_class(id) == Class && is_user_zombie(id) && get_user_weapon(id) == CSW_KNIFE && NextAttack <= 0.0) {
		if(!FastRun[id] && !FastRun_Countdown[id]) {
			set_pdata_float(id, 83, 1.6, 5);
			set_weapon_anim(id, 9)
			set_task(1.50, "StartRun", id + TASKID_START_POWER);
		}
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public StartRun(id) {
	id -= TASKID_START_POWER
	
	engclient_cmd(id, "weapon_knife");
	set_pdata_float(id, 83, 1.56, 5);
	set_weapon_anim(id, 10)
	EffectFastrun(id, 95)
	emit_sound(id, CHAN_VOICE, FastRun_Sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	FastRun[id] = get_pcvar_num(cvar_fastrun_duration);
	
	if(FastRun[id]) {
		new Message[256];
		formatex(Message,sizeof(Message)-1,"Fast Run^n(%d second%s remaining).",FastRun[id], FastRun[id] > 1 ? "s" : "");
		
		HudMessage(id, Message, _, _, _, _, _, _, _, 0.9);
		set_task(1.0, "TASK_CountDown", id);
	}
}

public TASK_CountDown(id) {
	if (!is_user_alive(id) || !is_user_zombie(id) || get_user_class(id) != Class) {
		FastRun[id] = 0
	}
	else if(is_user_alive(id) && FastRun[id] > 1) {
		FastRun[id] --;
		new Message[256];
		formatex(Message,sizeof(Message)-1,"Fast Run^n(%d second%s remaining).",FastRun[id], FastRun[id] > 1 ? "s" : "");
		
		HudMessage(id, Message, _, _, _, _, _, _, _, 0.9);
		set_task(1.0, "TASK_CountDown", id);
	}
	else if(FastRun[id] <= 1) {
		FastRun[id] = 0
		fm_set_user_maxspeed(id, ZOMBIE_SPEED)
		EffectFastrun(id)
		
		FastRun_Countdown[id] = get_pcvar_num(cvar_fastrun_countdown)
		
		if(FastRun_Countdown[id]) {
			new Message[256];
			formatex(Message,sizeof(Message)-1,"Fast Run not ready.^n(%d second%s remaining).",FastRun_Countdown[id], FastRun_Countdown[id] > 1 ? "s" : "");
			
			HudMessage(id, Message, _, _, _, _, _, _, _, 0.9);
			set_task(1.0, "TASK_CountDown2", id);
		}
	}
}

public TASK_CountDown2(id) {
	if (!is_user_alive(id) || !is_user_zombie(id) || get_user_class(id) != Class)
		FastRun_Countdown[id] = 0
	else if(is_user_alive(id) && FastRun_Countdown[id] > 1) {
		FastRun_Countdown[id] --;
		new Message[256];
		formatex(Message,sizeof(Message)-1,"Fast Run not ready.^n(%d second%s remaining).",FastRun_Countdown[id], FastRun_Countdown[id] > 1 ? "s" : "");
		
		HudMessage(id, Message, _, _, _, _, _, _, _, 0.9);
		set_task(1.0, "TASK_CountDown2", id);
	}
	else if(FastRun_Countdown[id] <= 1) {
		new Message[256];
		formatex(Message,sizeof(Message)-1,"Fast Run is ready.");
		
		HudMessage(id, Message, _, _, _, _, _, _, _, 0.9);
		FastRun_Countdown[id] = 0;
	}
}

EffectFastrun(id, num = 90) {
	if(is_user_connected(id)) {
		message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
		write_byte(num)
		message_end()
	}
}

stock FixedUnsigned16(Float:flValue, iScale) {
	new iOutput;
	
	iOutput = floatround(flValue * iScale);
	if ( iOutput < 0 )
		iOutput = 0;
	
	if ( iOutput > 0xFFFF )
		iOutput = 0xFFFF;
	return iOutput;
}

stock set_weapon_anim(id, anim) {
	set_pev(id, pev_weaponanim, anim);
	if(is_user_connected(id)) {
		message_begin(MSG_ONE, SVC_WEAPONANIM, _, id);
		write_byte(anim);
		write_byte(pev(id, pev_body));
		message_end();
	}
}

#define clamp_byte(%1)       ( clamp( %1, 0, 255 ) )
#define pack_color(%1,%2,%3) ( %3 + ( %2 << 8 ) + ( %1 << 16 ) )

stock HudMessage(const id, const message[], red = 0, green = 160, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 0.01, Float:holdtime = 3.0, Float:fadeintime = 0.01, Float:fadeouttime = 0.01) {
	new count = 1, players[32];
	
	if(id) players[0] = id;
	else get_players(players, count, "ch"); {
		for(new i = 0; i < count; i++) {
			if(is_user_connected(players[i])) {	
				new color = pack_color(clamp_byte(red), clamp_byte(green), clamp_byte(blue))
				
				message_begin(MSG_ONE_UNRELIABLE, SVC_DIRECTOR, _, players[i]);
				write_byte(strlen(message) + 31);
				write_byte(DRC_CMD_MESSAGE);
				write_byte(effects);
				write_long(color);
				write_long(_:x);
				write_long(_:y);
				write_long(_:fadeintime);
				write_long(_:fadeouttime);
				write_long(_:holdtime);
				write_long(_:fxtime);
				write_string(message);
				message_end();
			}
		}
	}
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
