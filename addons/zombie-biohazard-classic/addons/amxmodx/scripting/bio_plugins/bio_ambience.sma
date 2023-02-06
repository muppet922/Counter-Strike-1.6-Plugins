#include < amxmodx >
#include < biohazard >

#define MAX_SOUNDS		1

#define TIME_AFTER_COUNTDOWN	30.0
//#define TIME_EMITE_SHAKES	30.0

#define TASK_AMBIENCE		1232

new const 
	PLUGIN_NAME[  ] = "Biohazard Ambience", 
	PLUGIN_VERSION[  ] = "1.4", 
	PLUGIN_AUTHOR[  ] = "TEST";

new const szRandomSounds[ MAX_SOUNDS ][  ] = {
	
	"biohazard/ambience/horror_ambience.mp3"
};

//new const SoundShake[  ] = "Biohazard30/Ambience/ShakeSound.wav";

public plugin_init(  ) {
	
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	is_biomod_active(  ) ? plugin_init2(  ) : pause( "ad" );
}

public plugin_init2(  ) {
	
	register_event( "HLTV", "hltv_NewRound", "a", "1=0", "2=0" );
	
	register_logevent( "logevent_RoundEnd", 2, "1=Round_End" );
}

public plugin_precache(  ) {
	
	for( new i = 0; i < sizeof szRandomSounds; i++ )
		precache_sound( szRandomSounds[ i ] );
	
//	precache_sound( SoundShake );
}

public client_putinserver( id ) {
	
	remove_task( id );
}

public client_disconnect( id ) {
	
	remove_task( id );
}

public hltv_NewRound(  ) {
	
	new szPlayers[ 32 ], iNum;
	get_players( szPlayers, iNum, "ch" );
	
	for( new i = 0; i < iNum; i++)  {
		
		new id = szPlayers[ i ];

		if( is_user_alive( id ) && is_user_connected( id ) ) {
			
			set_task( TIME_AFTER_COUNTDOWN, "task_AmbiencesEffect", TASK_AMBIENCE );
			//set_task( TIME_EMITE_SHAKES, "task_MakeShakes", id, _, _, "b" );
		}
	}
}

public logevent_RoundEnd(  ) {
	
	remove_task( TASK_AMBIENCE );
}

public task_AmbiencesEffect( taskid ) {
	
	PlaySoundToClients( szRandomSounds[ random_num( 0, sizeof szRandomSounds - 1 ) ] );
}

public task_MakeShakes( id ) {
	
//	new szPlayers[ 32 ], iNum;
//	get_players( szPlayers, iNum, "ch" );
	
//	for( new i = 0; i < iNum; i++ )  {
		
//		new id = szPlayers[ i ];
		
//		PlaySoundToClients( SoundShake );

		message_begin( MSG_ONE, get_user_msgid( "ScreenFade" ), _, id );
		write_short( floatround( 4096.0 * 1.5, floatround_round ) );
		write_short( floatround( 4096.0 * 1.5, floatround_round ) );
		write_short( 0x0000 );
		write_byte( 255 );
		write_byte( 255 );
		write_byte( 255 );
		write_byte( 20 );
		message_end(  );
//	}
}

PlaySoundToClients( const szSound[  ] ) {
	
	if( equal( szSound[ strlen( szSound ) - 4 ], ".mp3" ) )
		client_cmd( 0, "mp3 play ^"sound/%s^"", szSound );
	else
		client_cmd( 0, "spk ^"%s^"", szSound );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
