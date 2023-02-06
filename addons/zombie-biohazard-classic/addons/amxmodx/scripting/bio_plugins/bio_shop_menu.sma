#include <amxmodx>
#include <fun>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <biohazard>
#include <hamsandwich> 
#include <fakemeta_util>


#define XO_WEAPON    4
#define m_pPlayer    41
#define XO_PLAYER        5
#define m_bResumeZoom    110
#define get_money(%1)	(cs_get_user_money(%1))
#define is_zombie(%1)	(is_user_zombie(%1))
#define is_human(%1)	(!is_user_zombie(%1))
#define get_health(%1)	(get_user_health(%1))
#define set_health(%1,%2)	(set_user_health(%1,%2))
#define get_armor(%1)	(get_user_armor(%1))
#define set_armor(%1,%2)	(set_user_armor(%1,%2))
#define set_money(%1,%2)	(cs_set_user_money(%1,%2))


new HavePara[33];

public plugin_init( ) {

				     // dd mm yyyy
	register_plugin( "[BIO] Shop", "v2.1", "YONTU" );

	if( is_biomod_active() ) {

		RegisterHam( Ham_Killed, "player", "fw_Killed" );

		register_clcmd( "say shop", "ShopMenu" );
		register_clcmd( "say /shop", "ShopMenu" );

	} else { set_fail_state( "[MOD] Biohazard Need to be enable !" ); }

}

public client_putinserver( id ) {
	HavePara[id] = 0;
}



public event_infect( id, attacker ) {
	if( !is_user_alive( id ) ) return;
	strip_user_weapons( id ); set_pdata_int( id, 116, 0 ); 
	give_item( id, "weapon_knife" );
	/* Fix ZOOm SCope On zm Infect by Alkaline 2016*/ 
	set_task( 0.5, "FixZMZoom", id ); cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 1 );
} 

public ShopMenu( id ) {

	new menu = menu_create ( "\y[ \rBiohazard\y ]\w Shop \y! \rv2019", "ShopMenuHandler" );

	if( is_user_alive( id ) ) {
	if( !HavePara[id] ) {
		if( get_money( id ) >= 100 )
			menu_additem( menu, "\wParachute \y[ \r100 $ \y]", "1", 0 );
		else	menu_additem( menu, "\wParachute \y[ \d100 $ \y]", "1", 0 );
	} else menu_additem( menu, "\dParachute [ \rReady \d]", "1", 0 );

	if( is_human( id ) ) {
	if( get_health( id ) < 200 ) {
		if( get_money( id ) >= 2000 ) 
			menu_additem( menu, "\wHP 50 \y[ \r2000 $ \y]", "2", 0 );
		else	menu_additem( menu, "\wHP 50 \y[ \d2000 $ \y]", "2", 0 );
	} else menu_additem( menu, "\dHP 50 [ \rMax. \d]", "2", 0 );
	if( get_armor( id ) < 200 ) {
		if( get_money( id ) >= 2000 )
			menu_additem( menu, "\wArmor 50 \y[ \r2000 $ \y]", "3", 0 );
		else	menu_additem( menu, "\wArmor 50 \y[ \d2000 $ \y]", "3", 0 );
	} else menu_additem( menu, "\dArmor 50 [ \rMax. \d]", "3", 0 );
	} else {
		menu_additem( menu, "\dHP 50 [ \d500 $ ] \y->\r Not available", "2", 0 );
		menu_additem( menu, "\dArmor 50 [ \d500 $ ] \y->\r Not available", "3", 0 );
	} 
	if( is_zombie( id ) ) {
		if( LastZM() == 1 ) { menu_additem( menu, "\dAntidote  [ \d10000 $ ] \y->\r Last Zombie, Not available", "4", 0 ); }
		else {
			if( get_money( id ) >= 5000 )
				menu_additem( menu, "\wAntidote  \y[ \r10000 $ \y]", "4", 0 );
			else 	menu_additem( menu, "\wAntidote  \y[ \d10000 $ \y]", "4", 0 );
		}
	} else menu_additem( menu, "\dAntidote  [ \d10000 $ ] \y->\r Not available", "4", 0 );

	if( is_human( id ) ) {
		if( !user_has_weapon( id, CSW_HEGRENADE ) && !user_has_weapon( id, CSW_FLASHBANG ) && !user_has_weapon( id, CSW_SMOKEGRENADE ) ) {
			if( get_money( id ) >= 4000 )
				menu_additem( menu, "\wHe/Flash/Smoke \y[ \r4000 $ \y]^n", "5", 0 );
			else	menu_additem( menu, "\wHe/Flash/Smoke \y[ \d4000 $ \y]^n", "5", 0 );
		} else menu_additem( menu, "\dHe/Flash/Smoke [ \rAll Ready \d]^n", "5", 0 );
	} else menu_additem( menu, "\dHe/Flash/Smoke [ \d4000 $ ] \y->\r Not available^n", "5", 0 );
	} else if( !is_user_alive( id ) ) {
		menu_additem( menu, "\dParachute [ 100 $ ] \y->\r Only Alive", "1", 0 );
		menu_additem( menu, "\dHP 50 [ 2000 $ ] \y->\r Only Alive", "2", 0 );
		menu_additem( menu, "\dArmor 50 [ 2000 $ ] \y->\r Only Alive", "3", 0 );
		menu_additem( menu, "\dAntidote [ 10000 $ ] \y->\r Only Alive", "4", 0 );
		menu_additem( menu, "\dHe/Flash/Smoke [ 4000 $ ] \y->\r Only Alive^n", "5", 0 );
	}
	if( !is_user_alive( id ) ) {
		if( get_money( id ) >= 5000 )
			menu_additem( menu, "\wLife \d(Respawn) \y[ \r10000 $ \y] \w->\y *\rBuy Now\y*", "6", 0 );
		else	menu_additem( menu, "\wLife \d(Respawn) \y[ \d10000 $ \y]", "6", 0 );
	} else menu_additem( menu, "\dLife \d(Respawn) \y[ \rYou need to be dead \w:) \y]", "6", 0 );
 
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, menu, 0 );
	return 1;
}

public ShopMenuHandler( id, menu, item ) {
 
	if( item == MENU_EXIT ) { return 1; }
	new data [ 4 ], szName [ 64 ];
	new access, callback;
	menu_item_getinfo ( menu, item, access, data,charsmax ( data ), szName,charsmax ( szName ), callback );
	new key = str_to_num ( data );
	new money; 

	switch( key ){

                case 1: {
		if( is_user_alive( id ) ) {
		if( is_human( id ) ) {
			money = get_money( id ) - 2000;
			if( money < 0 ) { Color( id, "!4[Biohazard Shop] !1N-ai bani !! Necesari:!3 2000 $ !1!" ); return 1; } else
			if( get_armor( id ) < 200 ) {
				set_armor( id, min( (get_armor( id ) + 50), 200) );
				set_money( id, money );
				Color( id, "!4[Biohazard Shop] !1Ai cumparat!3 50 Armura !1!" );
				ShopMenu( id );
			} else Color( id, "!4[Biohazard Shop]!1 Ai Armura Maxim !" );
		} else Color( id, "!4[Biohazard Shop]!1 Doar !3Human !1pot cumpara !" );
		} else Color( id, "!4[Biohazard Shop] !1Trebuie sa fi in viata sa cumperi!3 50 Armura !1!" );
		} case 2: {
		if( is_user_alive( id ) ) {
		if( is_zombie( id ) ) {
			money = get_money( id ) - 10000;
			if( money < 0 ) { Color( id, "!4[Biohazard Shop] !1N-ai bani !! Necesari:!3 10000 $ !1!" ); return 1; } else
			if( is_zombie( id ) ) {
				if( LastZM() == 1 ) Color( id, "!4[Biohazard Shop]!1 Nu poti cumpara! Deoarece esti singurul !3Zombie !1!" );
				else {
					cure_user( id );
					set_user_health( id, 100 );
					cs_set_user_team( id, CS_TEAM_CT );
					cs_reset_user_model( id );
					Remove_User_Nvgs(id);
					if( is_user_alive( id )) {
					fm_give_item( id, "weapon_knife" ); fm_give_item( id, "weapon_m4a1" ); cs_set_user_bpammo( id, CSW_M4A1, 90 );
					fm_give_item( id, "weapon_deagle" ); cs_set_user_bpammo( id, CSW_DEAGLE, 100 );
					fm_give_item( id, "weapon_hegrenade" ); fm_give_item( id, "weapon_flashbang" ); fm_give_item( id, "weapon_smokegrenade" ); }
					set_money( id, money );
					Color( id, "!4[Biohazard Shop] !1Ai cumparat!3 Antidote !1!" );
					ShopMenu( id );
				}
			}
		} else Color( id, "!4[Biohazard Shop]!1 Doar !3Zombie !1pot cumpara !" );
		} else Color( id, "!4[Biohazard Shop] !1Trebuie sa fi in viata sa cumperi!3 Antidote !1!" );
		} case 3: {
		if( is_user_alive( id )) {
		if( is_human( id ) ) {
			if( !user_has_weapon( id, CSW_HEGRENADE ) && !user_has_weapon( id, CSW_FLASHBANG ) && !user_has_weapon( id, CSW_SMOKEGRENADE ) ) {
				money = get_money( id ) - 4000;
				if( money < 0 ) {  Color( id, "!4[Bio Shop] !1N-ai bani !! Necesari:!3 4000 $ !1!" ); return 1; } else
				give_item( id, "weapon_hegrenade" ); give_item( id, "weapon_flashbang" ); give_item( id, "weapon_smokegrenade" );
				set_money( id, money );
				Color( id, "!4[Biohazard Shop] !1Ai cumparat!3 HE/Flash/Smoke !1!" ); ShopMenu( id );
			} else 	Color( id, "!4[Biohazard Shop] !1Ai deja un set!1 de :!3 HE/Flash/Smoke !1!" );
		} else Color( id, "!4[Biohazard Shop]!1 Doar !3Human !1pot cumpara !" );
		} else Color( id, "!4[Biohazard Shop] !1Trebuie sa fi in viata sa cumperi!3 HE/Flash/Smoke !1!" );
		} case 4: {
			if( !is_user_alive( id ) ) {
				money = get_money( id ) - 10000;
				if( money < 0 ) { Color( id, "!4[Biohazard Shop] !1N-ai bani !! Necesari:!3 10000 $ !1!" ); return 1; } else
				cs_set_user_team( id, CS_TEAM_CT );
				ExecuteHamB(Ham_CS_RoundRespawn, id);
				cure_user(id);
				set_task( 0.6, "SpawnArm", id );
				Remove_User_Nvgs(id);
				set_user_health(id, 100);
				cs_reset_user_model(id);	
				set_money( id, money );
				Color( id, "!4[Biohazard Shop] !1Ai cumparat!3 Respawn !1!" );
				//ShopMenu( id );
			} else { Color( id, "!4[Biohazard Shop] !1Trebuie sa fi Mort sa poti lua!3 Respawn !1!" ); }
		}
		
	}
	return 1;
}

public SpawnArm( id ) {
	set_user_health( id, 100 );
	fm_give_item( id, "weapon_knife" ); fm_give_item( id, "weapon_m4a1" ); cs_set_user_bpammo( id, CSW_M4A1, 90 );
	fm_give_item( id, "weapon_deagle" ); cs_set_user_bpammo( id, CSW_DEAGLE, 100 );
	fm_give_item( id, "weapon_hegrenade" ); fm_give_item( id, "weapon_flashbang" ); fm_give_item( id, "weapon_smokegrenade" ); }


public fw_Killed( id, attacker, shouldgib ) {
	HavePara[id] = 0;
} 

public client_PreThink( id ) {
	if( HavePara[id] ) {
		static Button; Button = get_user_button( id );
		static Float: Velocity[ 3 ]; entity_get_vector( id, EV_VEC_velocity, Velocity );
		if( Button & IN_USE && Velocity[ 2 ] < 00 ) { Velocity[ 2 ] = -100.0; entity_set_vector( id, EV_VEC_velocity, Velocity ); }
	}	
}
LastZM( ) {
	static iZombies, id; iZombies = 0;
	for (id = 1; id <= get_maxplayers(); id++) {
		if (is_user_alive(id) && is_zombie(id))
			iZombies++;
	}
	return iZombies;
}

#define OFFSET_NVGOGGLES 129
#define HAS_NVGS (1<<0)
#define USES_NVGS (1<<8)
stock Remove_User_Nvgs(id) {
	new iNvgs = get_pdata_int(id, OFFSET_NVGOGGLES, 5);
	if (!iNvgs) { return; }
	if (iNvgs & USES_NVGS) {
		static gmsgNVGToggle;
		gmsgNVGToggle = get_user_msgid("NVGToggle");
		emessage_begin(MSG_ONE, gmsgNVGToggle, _, id);
		ewrite_byte(0);
		emessage_end();
	}
	set_pdata_int(id, OFFSET_NVGOGGLES, 0, 5);
}
public FixZMZoom( id ) cs_set_user_zoom( id, CS_RESET_ZOOM, 1 );

stock Color( const id, const input[ ], any:... ) {
	new count = 1, players[ 32 ];
	static msg[ 191 ]; vformat( msg, 190, input, 3 );
	replace_all( msg, 190, "!4", "^4" );
	replace_all( msg, 190, "!1", "^1" );
	replace_all( msg, 190, "!3", "^3" );
	replace_all( msg, 190, "!0", "^0" );
	if( id ) players[ 0 ] = id; else get_players( players, count, "ch" ); {
		for( new i = 0; i < count; i++ ) {
			if( is_user_connected( players[ i ] ) ) {
				message_begin( MSG_ONE_UNRELIABLE, get_user_msgid( "SayText" ), _, players[ i ] )
				write_byte( players[ i ] );
				write_string( msg );
				message_end( );
			}
		}
	}
}