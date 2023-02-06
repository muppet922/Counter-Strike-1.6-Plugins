#include < amxmodx >
#include < hamsandwich >
#include < engine >
#include < fakemeta >
#include < biohazard >
#include < ColorChat >
#include < fun >

#define PLUGIN_NAME	"[Bio] Gameplay: Last Human"
#define PLUGIN_VERSION	"2.2"
#define PLUGIN_AUTHOR	"TEST"

#define TASK_REMOVEPOWERS	123
#define TASK_GLOWSHELL	 	2011
#define TASK_CHECK		124
#define TASK_SURVIVOR		531
#define TASK_LIGHTS		213

#define PA_LOW	10.0
#define PA_HIGH	70.0

const PRIMARY_WEAPONS_BIT_SUM = ( ( 1<<CSW_SCOUT ) | ( 1<<CSW_XM1014 ) | ( 1<<CSW_MAC10 ) | ( 1<<CSW_AUG ) | ( 1<<CSW_UMP45 ) | ( 1<<CSW_SG550 ) | ( 1<<CSW_GALIL ) | ( 1<<CSW_FAMAS ) | ( 1<<CSW_AWP ) | ( 1<<CSW_MP5NAVY ) | ( 1<<CSW_M249 ) | ( 1<<CSW_M3 ) | ( 1<<CSW_M4A1 ) | ( 1<<CSW_TMP ) | ( 1<<CSW_G3SG1 ) | ( 1<<CSW_SG552 ) | ( 1<<CSW_AK47 ) | ( 1<<CSW_P90 ) )

new const g_szTag[  ] = "[BIO-WAR]";

new const LastHumanSoundDeath[  ]	= "biohazard/bio_lastman/lasthuman_death.wav";
new const LastHumanSound[  ]		= "biohazard/bio_lastman/lasthuman_1.wav";
new const LastHumanSoundPain1[  ]	= "biohazard/bio_lastman/human_pain1.wav";
new const LastHumanSoundPain2[  ]	= "biohazard/bio_lastman/human_pain2.wav";

new const g_LastHumanModel[  ] = { "models/player/umbrella1/umbrella1.mdl" };
new g_LastHumanPumpkin[ 33 ];

new bool:g_PlayerIsLastHuman[ 33 ];
new Lightning, Smoke;

new SyncHudMessage;
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

new  g_iCvarLastHumanSpeed, 
	g_iCvarLastHumanHealth, 
	g_iCvarLastHumanArmor, 
	g_iCvarLastHumanGravity, 
	g_iCvarLastHumanChangeModel,
	g_iCvarLastHumanPainShockFree;

	
new PrimaryWeapons[][]={
	"M4A1 Rifle",
	"AK47 Rifle",
	"XM1014 Auto Shotgun",
	"M3 Pump Shotgun"
}

new SecondaryWeapons[][]={
	"Deagle",
	"USP",
	"Dual Elites"
}

public plugin_init(  ) {

	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	is_biomod_active(  ) ? plugin_init2(  ) : pause( "ad" );
}

public plugin_init2(  ) {

	register_event( "DeathMsg", "event_DeathMsg", "a" );
	register_event( "Damage", "event_Damage", "b" );
	register_event( "Damage" , "event_Damage2" , "b" , "2>0" );

	register_logevent( "logevent_RoundStart", 2 , "1=Round_Start" );

	RegisterHam( Ham_Spawn, "player", "Ham_PlayerSpawnPost", 1 );
	RegisterHam( Ham_Player_ResetMaxSpeed, "player", "Ham_ResetMaxSpeedPost", 1 );

	g_iCvarLastHumanSpeed	= register_cvar( "bio_lasthuman_speed", "300.0" );
	g_iCvarLastHumanHealth 	= register_cvar( "bio_lasthuman_hp", "250" );	// 50 * nr. de zombii in viata + acest cvar
	g_iCvarLastHumanArmor	= register_cvar( "bio_lasthuman_ap", "100" );
	g_iCvarLastHumanGravity 	= register_cvar( "bio_lasthuman_gravity", "0.75" );
	g_iCvarLastHumanChangeModel = register_cvar( "bio_lasthuman_change_model", "0" );
	g_iCvarLastHumanPainShockFree = register_cvar( "bio_lasthuman_pain_shock", "0" );

	SyncHudMessage = CreateHudSyncObj(  );
}

public plugin_precache(  ) {

	precache_sound( LastHumanSoundDeath );
	precache_sound( LastHumanSound );
	precache_sound( LastHumanSoundPain1 );
	precache_sound( LastHumanSoundPain2 );

	precache_model( g_LastHumanModel );
	precache_model( "models/rpgrocket.mdl" );

	Lightning = precache_model( "sprites/lgtning.spr" );
	Smoke = precache_model( "sprites/steam1.spr" );
}

public plugin_cfg(  )
	set_cvar_float( "sv_maxspeed", 1000.0 );

public client_putinserver( id )
	g_PlayerIsLastHuman[ id ] = false;

public client_disconnect( id ) {

	g_PlayerIsLastHuman[ id ] = false;

	remove_task( TASK_CHECK );
	set_task( 1.0, "task_check", TASK_CHECK );

	client_cmd( id, "cl_sidespeed 400" );
	client_cmd( id, "cl_forwardpeed 400" );
	client_cmd( id, "cl_backspeed 400" );
	client_cmd( id, "cl_lw 1" );
}

public event_DeathMsg(  ) {

	set_task( 1.0, "task_check", TASK_CHECK );

	new iKiller = read_data( 1 );
	new iVictim = read_data( 2 );

	if( !is_user_connected( iVictim ) || iKiller == iVictim )
		return 1;

	if( is_user_zombie( iVictim ) )
		return 1;

	if( g_PlayerIsLastHuman[ iVictim ] ) {

		emit_sound( 0, CHAN_ITEM, LastHumanSoundDeath, 1.0, ATTN_NORM, 0, PITCH_NORM );
  		ColorChat( 0, GREEN, "%s^x01 The last human on earth ^x03[%s]^x01 was anihilated by ^x03[%s]^x01 !", g_szTag, get_name( iVictim ), get_name( iKiller ) );

		if( get_pcvar_num( g_iCvarLastHumanChangeModel ) ) {

			remove_entity( g_LastHumanPumpkin[ iVictim ] );
			g_LastHumanPumpkin[ iVictim ] = 0;
		}
	}

	return 0;
}

public event_Damage( id ) {

	if( fm_get_user_health( id ) < 1 && !is_user_zombie( id ) ) {

		remove_task( TASK_CHECK );
		set_task( 1.0, "task_check", TASK_CHECK );
	}
}

// thx TalRasha, Remake fl0wer for this public
public event_Damage2( id ) {

	if( get_pcvar_num( g_iCvarLastHumanPainShockFree ) == 0 )
		return;

	if( !is_user_alive( id ) || is_user_bot( id ) )
		return;

	new iWeaponId, Attacker = get_user_attacker( id , iWeaponId );

	if( !is_user_connected( Attacker ) )
		return;

	if( iWeaponId == CSW_KNIFE ) {

		if( !is_user_zombie( id ) ) {

			new Float:fVec[ 3 ];
			fVec[ 0 ] = random_float( PA_LOW, PA_HIGH );
			fVec[ 1 ] = random_float( PA_LOW, PA_HIGH );
			fVec[ 2 ] = random_float( PA_LOW, PA_HIGH );

			entity_set_vector( id, EV_VEC_punchangle, fVec );

			message_begin( MSG_ONE_UNRELIABLE, get_user_msgid( "ScreenFade" ), _, id );
			write_short( 1<<10 );
			write_short( 1<<10 );
			write_short( 1<<12 );
			write_byte( 0 );
			write_byte( 0 );
			write_byte( 0 );
			write_byte( 0 );
			message_end(  );

			switch( random_num( 0, 1 ) ) {

				case 0: emit_sound( id, CHAN_ITEM, LastHumanSoundPain1, 1.0, ATTN_NORM, 0, PITCH_NORM );
				case 1: emit_sound( id, CHAN_ITEM, LastHumanSoundPain2, 1.0, ATTN_NORM, 0, PITCH_NORM );
			}
		}
	}
}

public event_infect( victim, attacker ) {

	if( victim == attacker )
		return 1;

  	remove_task( TASK_CHECK)
	set_task( 1.0, "task_check", TASK_CHECK );

	return 0;
}

public logevent_RoundStart(  ) {

	new szPlayers[ 32 ], iNum;
	get_players( szPlayers, iNum, "p" );

	for( new i = 0; i < iNum; i++) {

		remove_task( szPlayers[ i ] + TASK_LIGHTS );
		remove_task( TASK_CHECK );
		remove_task( TASK_SURVIVOR );
	}
}

public Ham_PlayerSpawnPost( id ) {

	if( !is_user_alive( id ) )
		return HAM_IGNORED;

	set_task( 1.0, "task_RemovePowers", id + TASK_REMOVEPOWERS );

	return HAM_IGNORED;
}

public Ham_ResetMaxSpeedPost( id ) {

	if( is_user_alive( id ) && fm_get_user_maxspeed( id ) != 1.0 ) {

  		new Float:flMaxSpeed;

		if( g_PlayerIsLastHuman[ id ] )
   			flMaxSpeed = float( get_pcvar_num( g_iCvarLastHumanSpeed ) );

  		if( flMaxSpeed > 0.0 )
   			fm_set_user_maxspeed( id, flMaxSpeed );
	}
}

public task_RemovePowers( id ) {

	id -= TASK_REMOVEPOWERS;

	if( !is_user_connected( id ) )
		return 1;

	if( g_PlayerIsLastHuman[ id ] ) {

		fm_set_user_gravity( id, 1.0 );
		fm_set_user_armor( id, 0 );

		if( get_pcvar_num( g_iCvarLastHumanChangeModel ) ) {

			remove_entity( g_LastHumanPumpkin[ id ] );
			g_LastHumanPumpkin[ id ] = 0;
		}
	}

	g_PlayerIsLastHuman[ id ] = false;

	return 0;
}

// thx cheap.suit for this code
public task_check(  ) {

	static Survivor; Survivor = last_survivor(  );

	if( Survivor ) {

		static g_Params[ 1 ];
		g_Params[ 0 ] = Survivor;

		set_task( 1.0, "CheckLastHuman", TASK_SURVIVOR, g_Params, 1 );
	}
}

public CheckLastHuman( g_Params[  ] ) {

	static id; id = g_Params[ 0 ];

  	if( g_PlayerIsLastHuman[ id ] )
		return 1;

  	if( is_user_infected( id ) )
		return 1;

  	g_PlayerIsLastHuman[ id ] = true;

  	ColorChat( 0, GREEN, "%s^x03 [%s]^x01 is the last human on planet EARTH ! ", g_szTag, get_name( id ) );
  	ColorChat( 0, GREEN, "%s^x01 His goal is to anihilate all the ZOMBIES and save the human race !", g_szTag );

  	set_hudmessage( 0, 255, 0, -1.0, -1.0, 0, 0.0, 5.0, 0.0, 1.0, 3 );
  	ShowSyncHudMsg( 0, SyncHudMessage, "[%s] became the last human !^n PREPARE FOR BIO-WAR", get_name( id ) );

	fm_set_user_maxspeed( id, get_pcvar_float( g_iCvarLastHumanSpeed ) );
	fm_set_user_gravity( id, get_pcvar_float( g_iCvarLastHumanGravity ) );
  	fm_set_user_armor( id, get_pcvar_num( g_iCvarLastHumanArmor ) );
  	fm_set_user_health( id, 50 * GetAliveZombies(  ) + get_pcvar_num( g_iCvarLastHumanHealth ) );

	set_task( 1.0, "SelectYourWeapons", id );
	set_task( 30.0, "SetLastHumanLights", TASK_LIGHTS );

	if( get_pcvar_num( g_iCvarLastHumanChangeModel ) )
		ChangeModel( id );

	ShakeScreen( id, 2.0 );
	FadeScreen( id, 3.0, 125, 170, 255, 153 );
	GlowShell( id );
	CreateThunder( id );
	CreateSmoke( id );

  	new szCommand[ 128 ];
  	formatex( szCommand, sizeof( szCommand ) - 1, "cl_forwardspeed %.1f;cl_sidespeed %.1f;cl_backspeed %.1f", 
		float( get_pcvar_num( g_iCvarLastHumanSpeed ) ), 
		float( get_pcvar_num( g_iCvarLastHumanSpeed ) ), 
		float( get_pcvar_num( g_iCvarLastHumanSpeed ) ) );

  	client_cmd( id, szCommand );
	client_cmd( id, "cl_lw 0" );
  	client_cmd( 0, "spk sound/%s", LastHumanSound );

	return 0;
}

//Recently added

public SelectYourWeapons(id){
	new menu = menu_create("You are the last Survivor!!^nPrimary Weapons:", "SYWHandler");
	
	for ( new i ; i < sizeof PrimaryWeapons; i++ )
		menu_additem(menu, PrimaryWeapons[i]);
		
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;	
}

public SYWHandler(id, menu, item){
	if( item == MENU_EXIT )
	{
		menu_cancel(id);
		Secondary(id);
		return PLUGIN_HANDLED;
	}

	
	new command[6], name[64], access, callback;

	menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback);
	
	switch(item)
	{
		case 0:
		{
			//give M4
			strip_user_weapons(id);
			give_item(id, "weapon_knife")
			give_item(id, "weapon_m4a1")
		}
		case 1:
		{
			//give Ak
			strip_user_weapons(id);
			give_item(id, "weapon_knife")
			give_item(id, "weapon_ak47")
		}
		
		case 2:
		{
			//give auto shottie
			strip_user_weapons(id);
			give_item(id, "weapon_knife")
			give_item(id, "weapon_xm1014")
		}
		case 3:
		{
			//give pump shotgun
			strip_user_weapons(id);
			give_item(id, "weapon_knife")
			give_item(id, "weapon_m3")
		}
	}
	
	Secondary(id);
	
	return PLUGIN_HANDLED;
	
}

public Secondary(id){
	new menu = menu_create("You are the last Survivor!!^nSecondary Weapons:", "SWHandler");
	
	for ( new i ; i < sizeof SecondaryWeapons ; i++ )
		menu_additem(menu, SecondaryWeapons[i]);
		
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;	
}

public SWHandler(id, menu, item){
	if( item == MENU_EXIT )
	{
		menu_cancel(id);
		return PLUGIN_HANDLED;
	}

	
	new command[6], name[64], access, callback;

	menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback);
	
	switch(item)
	{
		case 0:
		{
			//deag
			give_item(id, "weapon_deagle")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_hegrenade")
			give_item(id, "weapon_smokegrenade")
		}
		case 1:
		{
			//give USP
			give_item(id, "weapon_usp")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_hegrenade")
			give_item(id, "weapon_smokegrenade")
		}
		case 2:
		{
			//give ELITE
			give_item(id, "weapon_elite")
			give_item(id, "weapon_flashbang")
			give_item(id, "weapon_hegrenade")
			give_item(id, "weapon_smokegrenade")
		}
	}
	

	return PLUGIN_HANDLED;
}

// thx 'Ilya Akhremchik' for this code([CSO Like] Halloween Pumpkin)
public ChangeModel( id ) {

	g_LastHumanPumpkin[ id ] = create_entity( "info_target" );
	entity_set_model( g_LastHumanPumpkin[ id ], g_LastHumanModel );

	set_pev( g_LastHumanPumpkin[ id ], pev_movetype, 12 );	// 12 = MOVETYPE_FOLLOW
	set_pev( g_LastHumanPumpkin[ id ], pev_owner, id );
	set_pev( g_LastHumanPumpkin[ id ], pev_aiment, id) ;
	set_pev( g_LastHumanPumpkin[ id ], pev_body, 9 );	// 9 = MOVETYPE_FLYMISSILE
}

public SetLastHumanLights( taskid ) {

	set_player_light( TASK_LIGHTS, "z" );	// Set light player for can see the zombies
}

CreateThunder( id ) {

	new fOrigin[ 3 ], iStartPos[ 3 ];
	get_user_origin( id, fOrigin );
	
	fOrigin[ 2 ] -= 26;
	iStartPos[ 0 ] = fOrigin[ 0 ] + 150;
	iStartPos[ 1 ] = fOrigin[ 1 ] + 150;
	iStartPos[ 2 ] = fOrigin[ 2 ] + 800;

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
	write_byte( TE_BEAMPOINTS ); 
	write_coord( iStartPos[ 0 ] ); 
	write_coord( iStartPos[ 1 ] ); 
	write_coord( iStartPos[ 2 ] ); 
	write_coord( fOrigin[ 0 ] ); 
	write_coord( fOrigin[ 1 ] ); 
	write_coord( fOrigin[ 2 ] ); 
	write_short( Lightning ); // sprite id
	write_byte( 1 );	// startring frame
	write_byte( 5 );	// frame rate in 0.1's
	write_byte( 7 );	// life in 0.1's
	write_byte( 20 );	// line width in 0.1's
	write_byte( 30 );	// noise amplitude in 0.01's
	write_byte( 255 ); // red
	write_byte( 251 );	// green
	write_byte( 176 );	// blue
	write_byte( 200 );	// brightness
	write_byte( 200 );	// scroll speed in 0.1's
	message_end(  );
	
	message_begin( MSG_PVS, SVC_TEMPENTITY, fOrigin );
	write_byte( TE_SPARKS );
	write_coord( fOrigin[ 0 ] );
	write_coord( fOrigin[ 1 ] );
	write_coord( fOrigin[ 2 ] );
	message_end(  );
}

CreateSmoke( id ) {

	new fOrigin[ 3 ];
	get_user_origin( id, fOrigin );
	
	fOrigin[ 2 ] += 25;

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SMOKE ); // TE id
	write_coord( fOrigin[ 0 ] );	// start pos x
	write_coord( fOrigin[ 1 ] );	// start pos y
	write_coord( fOrigin[ 2 ] );	// start pos z
	write_short( Smoke );  // Sprite id
	write_byte( 10 );  // scale in 0.1's
	write_byte( 10 ); // framerate
	message_end(  );
}

GlowShell( id ) {

	fm_set_rendering( id );
	fm_set_rendering( id, kRenderFxGlowShell, 42, 170, 255, kRenderNormal, 0 );

	if( task_exists( id + TASK_GLOWSHELL ) )
		remove_task( id + TASK_GLOWSHELL );

	set_task( 10.0, "task_RemoveGlowShell", id + TASK_GLOWSHELL );
}

public task_RemoveGlowShell( taskid ) {

	new id = taskid - TASK_GLOWSHELL;

	fm_set_rendering( id );
	
	if( task_exists( taskid ) )
		remove_task( taskid );
}

stock drop_weapons( id ) {

	new szWeapons[ 32 ], iNum;
	get_user_weapons( id, szWeapons, iNum );

	for( new i = 0; i < iNum; i++ ) {

		if( PRIMARY_WEAPONS_BIT_SUM & ( 1<<szWeapons[ i ] ) ) {

			static szWeaponName[ 32 ];

			get_weaponname( szWeapons[ i ], szWeaponName, sizeof szWeaponName - 1 );
			engclient_cmd( id, "drop", szWeaponName );
		}
	}
}

stock get_name( id ) {

	new szName[ 32 ];
	get_user_name( id, szName, sizeof( szName ) - 1 );

	return szName;
}

stock FadeScreen( id, const Float:iSeconds, const iRed, const iGreen, const iBlue, const iAlpha ) {

	message_begin( MSG_ONE, get_user_msgid( "ScreenFade" ), _, id );
	write_short( floatround( 4096.0 * iSeconds, floatround_round ) );
	write_short( floatround( 4096.0 * iSeconds, floatround_round ) );
	write_short( 0x0000 );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( iAlpha );
	message_end(  );
}

stock ShakeScreen( id, const Float:iSeconds ) {

	message_begin( MSG_ONE, get_user_msgid( "ScreenShake" ), { 0, 0, 0 }, id );
	write_short( floatround( 4096.0 * iSeconds, floatround_round ) );
	write_short( floatround( 4096.0 * iSeconds, floatround_round ) );
	write_short( 1<<13 );
	message_end(  );
}

// thx cheap.suit for this code
stock last_survivor(  ) {

	static id, iCount, Survivor[ 33 ]; iCount = 0;

	for( id = 1; id <= get_maxplayers(  ); id++ ) {

		if( is_user_alive( id ) && !is_user_zombie( id ) )
			Survivor[ iCount++ ] = id;
	}

	return iCount == 1 ? Survivor[ 0 ] : 0;
}

GetAliveZombies(  ) {

	static iZm, id;
	iZm = 0
	
	for( id = 1; id <= get_maxplayers(  ); id++ ) {

		if( is_user_alive( id ) ) {
		
			if( get_user_team( id ) == 1 )
				iZm++;
		}
	}

	return iZm;
}

// stocks from fakemeta_util
stock fm_set_user_health( id, health )
	( health > 0 ) ? set_pev( id, pev_health, float( health ) ) : dllfunc( DLLFunc_ClientKill, id );

stock fm_get_user_health( index ) {

	new health;
	pev( index, pev_health, health );

	return health;
}

stock fm_set_user_armor( index, armor ) {

	set_pev( index, pev_armorvalue, float( armor ) );

	return 1;
}

stock fm_set_user_maxspeed( index, Float:speed = -1.0 ) {

	engfunc( EngFunc_SetClientMaxspeed, index, speed );

	set_pev( index, pev_maxspeed, speed );

	return 1;
}

stock Float:fm_get_user_maxspeed( index ) {

	new Float:speed;
	pev( index, pev_maxspeed, speed );

	return speed;
}

stock fm_set_user_gravity( index, Float:gravity = 1.0 ) {

	set_pev( index, pev_gravity, gravity );

	return 1;
}

stock fm_set_rendering( entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16 ) {

	new Float:RenderColor[ 3 ];
	RenderColor[ 0 ] = float( r );
	RenderColor[ 1 ] = float( g );
	RenderColor[ 2 ] = float( b );

	set_pev( entity, pev_renderfx, fx );
	set_pev( entity, pev_rendercolor, RenderColor );
	set_pev( entity, pev_rendermode, render );
	set_pev( entity, pev_renderamt, float( amount ) );

	return 1;
}

// thx Dias Leon for this stock
public set_player_light( id, const LightStyle[  ] ) {

	if( !is_user_connected( id ) )
		return;

	message_begin( MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id );
	write_byte( 0 );
	write_string( LightStyle );
	message_end(  );
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
