#include < amxmodx >
#include < cstrike >
#include < csstats >
#include < biohazard >

#define PLUGIN_VERSION	"1.4"

new ChooseTeamOverrideActive[ 33 ];

public plugin_init(  ) {

	register_plugin( "[Bio] Addon: Game Menu", PLUGIN_VERSION, "TEST" );

	is_biomod_active(  ) ? plugin_init2(  ) : pause( "ad" );
}

public plugin_init2(  ) {

	register_clcmd( "chooseteam", "ChooseTeam" );
	register_clcmd( "say gamemenu", "GameMenu" );
	register_clcmd( "say menu", "GameMenu" );	
	register_clcmd( "say /gamemenu", "GameMenu" );
	register_clcmd( "say /menu", "GameMenu" );
	register_clcmd( "say_team gamemenu", "GameMenu" );
	register_clcmd( "say_team menu", "GameMenu" );
	register_clcmd( "say_team /gamemenu", "GameMenu" );
	register_clcmd( "say_team /menu", "GameMenu" );

	set_task( 100.0, "GameMenuMessage", _, _, _, "b" );
}

public client_putinserver( id )
	ChooseTeamOverrideActive[ id ] = true;

public ChooseTeam( id ) {

	if( ChooseTeamOverrideActive[ id ] ) {

		GameMenu( id );
		return PLUGIN_HANDLED;
	}

	ChooseTeamOverrideActive[ id ] = true;
	return PLUGIN_CONTINUE;
}

public GameMenu( id ) {

	new szMenu = menu_create( "\yGame Menu^n\yBiohazard\r v2.2\y\w |", "GameMenuCmd" );

	static szMenuItem[ 150 ];
	static stats[ 8 ], body[ 8 ];
	new iRankPos = get_user_stats( id, stats, body );
	new iMaxRank = get_statsnum(  );
	menu_additem( szMenu, "\wShop [Coming soon]", "1", 0 );
	menu_additem( szMenu, "\wZombie Classes", "2", 0 );	// GENERAL
	menu_additem( szMenu, "\wSelect team", "3", 0 );			// GENERAL
                menu_additem( szMenu, "\wServer binds/lasermines", "4", 0)
                menu_additem( szMenu, "\wUnstuck", "5", 0)

	formatex( szMenuItem, charsmax( szMenuItem ), "\r[\dRank:\y %d\d from\y %d\r]", iRankPos, iMaxRank );
	menu_additem( szMenu, szMenuItem, "6", ADMIN_IMMUNITY );	// GENERAL
	
	menu_setprop( szMenu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, szMenu, 0 );
	
	return PLUGIN_CONTINUE;
}

public GameMenuCmd( id, szMenu, szItem ) {

	if( szItem == MENU_EXIT ) {

		menu_destroy( szMenu );
		return PLUGIN_HANDLED;
	}

	new iData[ 6 ], szName[ 64 ];
	new iAccess, iCallBack;

	menu_item_getinfo( szMenu, szItem, iAccess, iData, 5, szName, 63, iCallBack );
	new iKey = str_to_num( iData );

	switch( iKey ) {

		case 1: {

			if( is_user_alive( id ) ) {

				client_cmd( id, "say /shop" );
			} else {

				menu_display( id, szMenu, 0 );
			}
		}

		case 2: client_cmd( id, "say /class" );

		case 3: {

			ChooseTeamOverrideActive[ id ] = false;
			
			client_cmd( id, "chooseteam" );
		}

                                case 4:
                                {
                                                 client_cmd(id, "say /binds")
                                }
                                 case 5:
                                {
                                                client_cmd(id, "say /unstuck")
                                 }

		case 6: {

			if( is_user_alive( id ) ) {

				client_cmd( id, "say /top15" );
			}

			else {

				menu_display( id, szMenu, 0 );
			}
		}

		case 7: set_task( 0.1, "AdminsMenu", id );
	}

	menu_destroy( szMenu );
	return PLUGIN_HANDLED;
}

public GameMenuMessage( id )
	ColorChat( id, "!g[BIO-MENU]!y Press!t [M]!y to open server menu." );

stock ColorChat( const id, const input[  ], any:... ) {

	new iCount = 1, szPlayers[ 32 ];
	static szMsg[ 191 ];

	vformat( szMsg, 190, input, 3 );

	replace_all( szMsg, 190, "!g", "^4" );
	replace_all( szMsg, 190, "!y", "^1" );
	replace_all( szMsg, 190, "!t", "^3" );

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