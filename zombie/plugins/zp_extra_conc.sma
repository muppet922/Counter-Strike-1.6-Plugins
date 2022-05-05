
#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < fun >
#include < zombie_plague_special >

// Plugin version
#define VERSION "1.4"

// Defines
#define MAXPLAYERS 	32
#define FCVAR_FLAGS 	( FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED )
#define OFFSET_PLAYER	41
#define OFFSET_ACTIVE	373
#define LINUX_DIFF	5
#define NADE_TYPE_CONC	7000
#define FFADE_IN	0x0000
#define REPEAT		0.2 // Time when next screen fade/shake message is being sent
#define TASK_AFFECT	666
#define ID_AFFECT	( taskid - TASK_AFFECT )
#define OFFSET_FLAMMO	387

// Grenade cost
#define GRENADE_COST	15

// Grenade models
new const grenade_model_p [ ] = "models/p_grenade_conc.mdl"
new const grenade_model [ ] = "models/v_grenade_conc.mdl"
new const grenade_model_w [ ] = "models/w_grenade_conc.mdl"

// Sounds
new const explosion_sound [ ] = "zombie_plague/concgren_blast1.wav"
new const purchase_sound [ ] = "items/gunpickup2.wav"
new const purchase_sound2 [ ] = "items/9mmclip1.wav"

// Cached sprite indexes
new m_iTrail, m_iRing

// Item ID
new g_conc

// Player variables
new g_NadeCount [ MAXPLAYERS+1 ]

// Message ID's
new g_msgScreenFade, g_msgScreenShake, g_msgAmmoPickup

// CVAR pointers
new cvar_nade_radius, cvar_duration

// Precache
public plugin_precache ( )
{
	// Precache grenade models
	precache_model ( grenade_model_p )
	precache_model ( grenade_model )
	precache_model ( grenade_model_w )

	// Precache sounds
	precache_sound ( explosion_sound )
	precache_sound ( purchase_sound )
	precache_sound ( purchase_sound2 )

	// Precache sprites
	m_iRing = precache_model ( "sprites/shockwave.spr" )
	m_iTrail = precache_model ( "sprites/laserbeam.spr" )
}

// Plugin initialization
public plugin_init ( )
{
	// New plugin
	register_plugin ( "[ZP] Extra Item: Concussion Grenade", VERSION, "NiHiLaNTh" )

	// Add cvar to detect servers with this plugin
	register_cvar ( "zp_concgren_version", VERSION, FCVAR_FLAGS )

	// New extra item
	g_conc = zp_register_extra_item ( "\r[\yZP\r]\yConcussion Grenade", GRENADE_COST, ZP_TEAM_ZOMBIE )

	// Events
	register_event ( "HLTV", "Event_NewRound", "a", "1=0", "2=0" )
	register_event ( "DeathMsg", "Event_DeathMsg", "a" )
	register_event ( "CurWeapon", "Event_CurrentWeapon", "be", "1=1", "2=25" )

	// Forwards
	register_forward ( FM_SetModel, "fw_SetModel" )
	RegisterHam ( Ham_Think, "grenade", "fw_ThinkGrenade" )
	register_forward ( FM_CmdStart, "fw_CmdStart" )

	// CVARs
	cvar_nade_radius = register_cvar ( "zp_conc_nade_radius", "500" )
	cvar_duration = register_cvar ( "zp_conc_nade_duration", "7" )

	// Messages
	g_msgScreenShake = get_user_msgid ( "ScreenShake" )
	g_msgScreenFade = get_user_msgid ( "ScreenFade" )
	g_msgAmmoPickup = get_user_msgid ( "AmmoPickup" )
}

// Someone decided to buy our an extra item
public zp_extra_item_selected ( Player, Item )
{
	// This is our grenade
	if ( Item == g_conc )
	{
		// Player already have it
		if ( g_NadeCount [ Player ] >= 1 )
		{
			// Increase nade count
			g_NadeCount [ Player ]++

			// Increase bp ammo
			set_pdata_int ( Player, OFFSET_FLAMMO, get_pdata_int ( Player, OFFSET_FLAMMO, LINUX_DIFF )+1, LINUX_DIFF )

			// Ammo pickup
			message_begin ( MSG_ONE, g_msgAmmoPickup, _, Player )
			write_byte ( 11 ) // Ammo ID
			write_byte ( 1 ) // Ammo amount
			message_end ( )

			// Emit sound
			emit_sound ( Player, CHAN_WEAPON, purchase_sound2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
		}
		else // 0 grenades
		{
			// Increase nade count
			g_NadeCount [ Player ] = 1

			// Give him flashbang
			give_item ( Player, "weapon_flashbang" )

			// Play purchase sound
			client_cmd ( Player, "spk %s", purchase_sound )
		}
	}
	return PLUGIN_CONTINUE
}

// Someone was infected
public zp_user_infected_post ( Player, Infector )
{
	// We were affected by concussion grenade
	if ( task_exists ( Player+TASK_AFFECT ) )
		remove_task ( Player+TASK_AFFECT )
}

// Someone were turned back to human
public zp_user_humanized_post ( Player, Survivor )
{
	// We dont' have nade anymore
	if ( g_NadeCount [ Player ] )
	{
		g_NadeCount [ Player ] = 0
	}
}

// New round started
public Event_NewRound ( )
{
	// Reset nade count
	arrayset ( g_NadeCount, false, 33 )

	// And they aren't affected by conc.grenade
	remove_task ( TASK_AFFECT )
}

// Someone died
public Event_DeathMsg ( )
{
	// Get victim
	new victim = read_data ( 2 )

	// Some people had error without this check
	if ( !is_user_connected ( victim ) )
		return

	// Remove hallucinations
	remove_task ( victim+TASK_AFFECT )

	// Reset nade count
	g_NadeCount [ victim ] = 0
}

// Current weapon player is holding
public Event_CurrentWeapon ( Player )
{
	// Dead or not zombie or don't have conc. grenade
	if ( !is_user_alive ( Player ) || !zp_get_user_zombie ( Player ) || g_NadeCount [ Player ] <= 0 )
		return PLUGIN_CONTINUE

	// Replace flashbang model with our ones
	set_pev ( Player, pev_viewmodel2, grenade_model )
	set_pev ( Player, pev_weaponmodel2, grenade_model_p )

	return PLUGIN_CONTINUE
}

// Set model
public fw_SetModel ( Entity, const Model [ ] )
{
	// Prevent invalid ent messages
	if ( !pev_valid ( Entity ) )
		return FMRES_IGNORED

	// Grenade not thrown yet
	if ( pev ( Entity, pev_dmgtime ) == 0.0 )
		return FMRES_IGNORED

	// We are throwing concussion grenade
	if ( g_NadeCount [ pev ( Entity, pev_owner ) ] >= 1 && equal ( Model [7 ], "w_fl", 4 ) )
	{
		//Draw trail
		message_begin ( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte ( TE_BEAMFOLLOW ) // Temp entity ID
		write_short ( Entity ) // Entity to follow
		write_short ( m_iTrail ) // Sprite index
		write_byte ( 10 ) // Life
		write_byte ( 10 ) // Line width
		write_byte ( 255 ) // Red amount
		write_byte ( 255 ) // Blue amount
		write_byte ( 0 ) // Blue amount
		write_byte ( 255 ) // Alpha
		message_end ( )

		// Set grenade entity
		set_pev ( Entity, pev_flTimeStepSound, NADE_TYPE_CONC )

		// Decrease nade count
		g_NadeCount [ pev ( Entity, pev_owner ) ]--

		// Set world model
		engfunc ( EngFunc_SetModel, Entity, grenade_model_w )
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

// Grenade is getting to explode
public fw_ThinkGrenade ( Entity )
{
	// Prevent invalid ent messages
	if ( !pev_valid ( Entity ) )
		return HAM_IGNORED

	// Get damage time
	static Float:dmg_time
	pev ( Entity, pev_dmgtime, dmg_time )

	// maybe it is time to go off
	if ( dmg_time > get_gametime ( ) )
		return HAM_IGNORED

	// Our grenade
	if ( pev ( Entity, pev_flTimeStepSound ) == NADE_TYPE_CONC )
	{
		// Force to explode
		concussion_explode ( Entity )
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

// Command start
public fw_CmdStart ( Player, UC_Handle, Seed )
{
	// Dead, zombie or not affected
	if ( !is_user_alive ( Player ) || zp_get_user_zombie ( Player ) || !task_exists ( Player+TASK_AFFECT ) )
		return FMRES_IGNORED

	// Get buttons
	new buttons = get_uc ( UC_Handle, UC_Buttons )

	// We are firing
	if ( buttons & IN_ATTACK )
	{
		// We are holding an active weapon
		if ( get_pdata_cbase ( Player, OFFSET_ACTIVE, LINUX_DIFF ) )
		{
			// New recoil
			set_pev ( Player, pev_punchangle, Float:{3.0, 3.0, 4.0} )
		}
	}
	return FMRES_HANDLED
}


// Grenade explode
public concussion_explode ( Entity )
{
	// Invalid entity ?
	if ( !pev_valid ( Entity  ) )
		return

	// Get entities origin
	static Float:origin [ 3 ]
	pev ( Entity, pev_origin, origin )

	// Draw ring
	UTIL_DrawRing (origin )

	// Explosion sound
	emit_sound ( Entity, CHAN_WEAPON, explosion_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )

	// Collisions
	static victim
	victim = -1

	// Find radius
	static Float:radius
	radius = get_pcvar_float ( cvar_nade_radius )

	// Find all players in a radius
	while ( ( victim = engfunc ( EngFunc_FindEntityInSphere, victim, origin, radius ) ) != 0 )
	{
		// Dead or zombie
		if ( !is_user_alive ( victim ) || zp_get_user_zombie ( victim ) )
			continue

		// Victim isn't affected yet
		if ( !task_exists ( victim+TASK_AFFECT ) )
		{
			// Get duration
			new duration = get_pcvar_num ( cvar_duration )

			// Calculate affect times
			new affect_count = floatround ( duration / REPEAT )

			// Continiously affect them
			set_task ( REPEAT, "affect_victim", victim+TASK_AFFECT, _, _, "a", affect_count )
		}
	}

	// Remove entity from ground
	engfunc ( EngFunc_RemoveEntity, Entity )
}

// We are going to affect you
public affect_victim ( taskid )
{
	// Dead
	if ( !is_user_alive ( ID_AFFECT ) )
		return

	// Make a screen fade
	message_begin ( MSG_ONE_UNRELIABLE, g_msgScreenFade, {0,0,0}, ID_AFFECT )
	write_short ( 1<<13 ) // Duration
	write_short ( 1<<14 ) // Hold Time
	write_short ( FFADE_IN ) // Fade type
	write_byte ( random_num ( 50, 200 ) ) // Red amount
	write_byte ( random_num ( 50, 200 ) ) // Green amount
	write_byte ( random_num ( 50, 200 ) ) // Blue amount
	write_byte ( random_num ( 50, 200 ) ) // Alpha
	message_end ( )

	// Make a screen shake
	message_begin ( MSG_ONE_UNRELIABLE, g_msgScreenShake, {0,0,0}, ID_AFFECT )
	write_short ( 0xFFFF ) // Amplitude
	write_short ( 1<<13 ) // Duration
	write_short ( 0xFFFF ) // Frequency
	message_end ( )

	// Remove task after all
	remove_task ( ID_AFFECT )
}

// Draw explosion ring ( from zombie_plague40.sma )
stock UTIL_DrawRing ( const Float:origin [ 3 ] )
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
	write_short( m_iRing ) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(200) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
