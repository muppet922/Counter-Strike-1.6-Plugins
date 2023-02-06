#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN_NAME	"Light SmokeGrenade"
#define PLUGIN_VERSION 	"1.1"
#define PLUGIN_AUTHOR 	"tuty"

#pragma semicolon 1		// ;)
#define SMOKE_MODEL_INDEX	"models/w_smokegrenade.mdl"
#define SMOKE_START_SOUND	"items/nvg_on.wav"
#define SMOKE_STOP_SOUND	"items/nvg_off.wav"
#define SMOKE_SPR_TRAIL		"sprites/laserbeam.spr"
#define SMOKE_SPR_CIRCLE	"sprites/shockwave.spr"
#define SMOKE_SPR_SMOKE		"sprites/steam1.spr"	
#define SMOKE_ID		071192
#define pev_valid2(%1)		(pev(%1, pev_iuser4) == SMOKE_ID) ? 1 : 0

new gSmokeLightEnable;
new gLightTime;
new gDeployTime;
new gSpriteTrail;
new gSpriteCircle;
new gSpriteSmoke;
new gTrailEnable;
new gCylinderEnable;
new gGlowColorCvar;
new gSmokeCvar;
new gSmokeBonus;
new Float:fOrigin[ 3 ];
new iOrigin[ 3 ];

public plugin_init()
{
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	register_forward( FM_SetModel, "forward_setmodel" );
	register_forward( FM_Think, "forward_think" );
	RegisterHam( Ham_Spawn, "player", "forward_spawn", 1 );
	
	gSmokeLightEnable = register_cvar( "lightsmoke_enabled", "1" );
	gLightTime = register_cvar( "lightsmoke_light_duration", "20.0" );
	gDeployTime = register_cvar( "lightsmoke_deploytime", "3.0" );
	gTrailEnable = register_cvar( "lightsmoke_trail", "1" );
	gCylinderEnable = register_cvar( "lightsmoke_cylinder", "1" );
	gSmokeCvar = register_cvar( "lightsmoke_smoke", "1" );
	gGlowColorCvar = register_cvar( "lightsmoke_glow_color", "255 255 255" );
	gSmokeBonus = register_cvar( "lightsmoke_bonus", "1" );
}
public plugin_precache()
{
	precache_model( SMOKE_MODEL_INDEX );
	precache_sound( SMOKE_START_SOUND );
	precache_sound( SMOKE_STOP_SOUND );
	gSpriteTrail = precache_model( SMOKE_SPR_TRAIL );
	gSpriteCircle = precache_model( SMOKE_SPR_CIRCLE );
	gSpriteSmoke = precache_model( SMOKE_SPR_SMOKE );
}
public forward_spawn( id )
{
	if( is_user_alive( id ) && get_pcvar_num( gSmokeLightEnable ) == 1 && get_pcvar_num( gSmokeBonus ) == 1 )
	{
		fm_give_item( id, "weapon_smokegrenade" );
	}
}	
public forward_setmodel( ent, const model[] )
{
	if( !pev_valid( ent ) || get_pcvar_num( gSmokeLightEnable ) == 0 || !equal( model[ 9 ], "smokegrenade.mdl" ) )
	{
		return FMRES_IGNORED;
	}
	
	static classname[ 32 ];
	pev( ent, pev_classname, classname, charsmax( classname ) );

	if( equal( classname, "grenade" ) )
	{
		if( get_pcvar_num( gTrailEnable ) == 1 )
		{
			create_trail_sprite( ent );
		}
		
		engfunc( EngFunc_SetModel, ent, SMOKE_MODEL_INDEX );
		set_task( get_pcvar_float( gDeployTime ), "deploy_smoke", ent );
		set_pev( ent, pev_iuser4, SMOKE_ID );
		set_pev( ent, pev_nextthink, get_gametime() + get_pcvar_float( gLightTime ) );
		
		new color[ 12 ], rgb[ 3 ][ 4 ], r, g, b;
		get_pcvar_string( gGlowColorCvar, color, charsmax( color ) );
		parse( color, rgb[ 0 ], 3 , rgb[ 1 ], 3 , rgb[ 2 ], 3 );
		
		r = clamp( str_to_num( rgb[ 0 ] ) , 0, 255 );
		g = clamp( str_to_num( rgb[ 1 ] ) , 0, 255 );
		b = clamp( str_to_num( rgb[ 2 ] ) , 0, 255 );
		
		fm_set_rendering( ent, kRenderFxGlowShell, r, g, b, kRenderNormal, 18 );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}
public deploy_smoke( ent )
{
	if( get_pcvar_num( gCylinderEnable ) == 1 )
	{
		create_blast_circle( ent );
	}
	
	set_pev( ent, pev_effects, EF_DIMLIGHT );
	emit_sound( ent, CHAN_ITEM, SMOKE_START_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}
public forward_think( ent )
{
	if( pev_valid( ent ) && get_pcvar_num( gSmokeLightEnable ) == 1 && pev_valid2( ent ) )
	{
		if( get_pcvar_num( gSmokeCvar ) == 1 )
		{
			pev( ent, pev_origin, fOrigin );
			FVecIVec( fOrigin, iOrigin );
		
			new x = iOrigin[ 0 ];
			new y = iOrigin[ 1 ];
			new z = iOrigin[ 2 ];
		
			create_little_smoke( x + 50, y, z );
			create_little_smoke( x, y + 50, z );
			create_little_smoke( x - 50, y, z );
			create_little_smoke( x, y - 50, z );
			create_little_smoke( x + 35, y + 35, z );
			create_little_smoke( x + 35, y - 35, z );
			create_little_smoke( x - 35, y + 35, z );
			create_little_smoke( x - 35, y - 35, z );
		}
		
		emit_sound( ent, CHAN_ITEM, SMOKE_STOP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		set_pev( ent, pev_flags, FL_KILLME );
	}
}
create_trail_sprite( ent )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( ent );		
	write_short( gSpriteTrail );
	write_byte( 3 );
	write_byte( 7 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 100 );
	message_end();
}
create_blast_circle( ent )
{
	pev( ent, pev_origin, fOrigin );
	FVecIVec( fOrigin, iOrigin );

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, iOrigin ); 
	write_byte( TE_BEAMCYLINDER );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] + 220 ) ;
	write_short( gSpriteCircle );
	write_byte( 0 );
	write_byte( 1 );
	write_byte( 6 );
	write_byte( 8 );
	write_byte( 1 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 128 );
	write_byte( 5 );
	message_end();
}
create_little_smoke( x, y, z )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SMOKE );
	write_coord( x );
	write_coord( y );
	write_coord( z ); 
	write_short( gSpriteSmoke );
	write_byte( 12 );
	write_byte( 3 );
	message_end();
}
