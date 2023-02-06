#include < amxmodx >
#include < amxmisc >

#pragma semicolon 1

// Jucatori Maximi ( 32 + 1 ) //
#define MAX_PLAYERS 33

// Globaluri //
new g_szBanTime [ MAX_PLAYERS ] [ 8 ] ;
new g_szBanReason [ MAX_PLAYERS ] [ 32 ] ;
new g_Hostname ;
new g_DelaySS ;
new g_DelayBan ;
new g_SnapShot ;
new g_UnbanURL ;
new g_msgHudSync ;

// Initializare //
public plugin_init ( )
{
	// Plugin //
	register_plugin	( "Info Ban" , AMXX_VERSION_STR , "TEST" ) ;
	
	// Comenzi //
	register_concmd	( "amx_banip" , "cmdBanIP" , ADMIN_BAN , "<nume sau #id> <minut(e)> [motiv]" ) ;
	register_concmd	( "amx_ban" , "cmdBanIP" , ADMIN_BAN , "<nume sau #id> <minut(e)> [motiv]" ) ;
	
	// Globaluri //
	g_msgHudSync =	CreateHudSyncObj ( ) ;
	g_Hostname =	get_cvar_pointer ( "hostname" ) ;
	g_DelaySS =	register_cvar ( "amx_intarzie_repoze" , "0.5" ) ;
	g_DelayBan =	register_cvar ( "amx_intarziere_ban" , "1.7" ) ;
	g_SnapShot =	register_cvar ( "amx_numar_poze" , "2" ) ;
	g_UnbanURL =	register_cvar ( "amx_infoban_forum" , "www.ForumulTau.com" ) ;
}

public cmdBanIP ( id , level , cid )
{
	if ( !cmd_access ( id , level , cid , 3 ) )
	{
		return PLUGIN_HANDLED ;
	}
	
	new target [ 32 ] ;
	
	read_argv ( 1 , target , 31 ) ;
	read_argv ( 2 , g_szBanTime [ id ] , 7 ) ;
	read_argv ( 3 , g_szBanReason [ id ] , 63 ) ;
	
	client_print ( id , print_chat ,		"Jucatorul va fi banat in 2 secunde !!!" ) ;
	client_print ( id , print_chat ,		"Jucatorul va fi banat in 2 secunde !!!" ) ;
	
	client_print ( id , print_console ,	"Jucatorul va fi banat in 2 secunde !!!" ) ;
	client_print ( id , print_console ,	"Jucatorul va fi banat in 2 secunde !!!" ) ;
	
	client_cmd ( id , "wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait;wait" ) ;
	
	new player = cmd_target ( id , target , CMDTARGET_OBEY_IMMUNITY ) ;
	
	if ( !player )
	{
		return PLUGIN_HANDLED ;
	}
	
	new Param [ 2 ] ;
	
	Param [ 0 ] = id ;
	Param [ 1 ] = player ;
	
	set_task ( Float:get_pcvar_float ( g_DelaySS ) , "SS_Task" , 0 , Param , 2 , "a" , get_pcvar_num ( g_SnapShot ) ) ;
	set_task ( Float:get_pcvar_float ( g_DelayBan ) , "BanSS_Task" , 0 , Param , 2 ) ;
	
	return PLUGIN_HANDLED ;
}

public SS_Task ( Param [ 2 ] )
{
	new player =	Param [ 1 ] ;
	new id =		Param [ 0 ] ;
	
	new name	[ 32 ] ;
	new timer	[ 32 ] ;
	new name2	[ 32 ] ;
	new ip		[ 32 ] ;
	new authid2	[ 32 ] ;
	new hostname	[ 64 ] ;
	new site		[ 64 ] ;
	
	get_user_name	( id , name , 31 ) ;
	get_user_name	( player , name2 , 31 ) ;
	get_user_authid	( player , authid2 , 31 ) ;
	get_user_ip	( player , ip , 31 , 1 ) ;
	get_time		( "[%d/%m/%Y] - [%H:%M:%S]" , timer , 63 ) ;
	get_pcvar_string	( g_Hostname, hostname, charsmax ( hostname ) ) ;
	get_pcvar_string	( g_UnbanURL, site, charsmax ( site ) ) ;
	
	chat_color ( player , "\verde\*****************************************" ) ;
	chat_color ( player , "\verde\**\normal\ ADMIN :\culoare_echipa\ %s", name) ;
	chat_color ( player , "\verde\**\normal\ TIMP :\culoare_echipa\ %s\normal\ && SERVER :\culoare_echipa\ %s", timer, hostname) ;
	chat_color ( player , "\verde\**\normal\ NUMELE TAU :\culoare_echipa\ %s\normal\ || IP :\culoare_echipa\ %s\normal\ && STEAM : \culoare_echipa\%s", name2, ip, authid2) ;
	chat_color ( player , "\verde\**\normal\ POSTEAZA POZELE PE\culoare_echipa\ %s\normal\ PENTRU DEBANARE!", site) ;
	
	client_cmd ( player , "wait;snapshot" ) ;
	
	return PLUGIN_HANDLED ;
}

public BanSS_Task ( Param [ ] )
{
	new id =		Param [ 0 ] ;
	new player =	Param [ 1 ] ;
	
	new minutes	[ 8 ] ;
	new reason	[ 32 ] ;
	new authid	[ 32 ] ;
	new name2	[ 32 ] ;
	new authid2	[ 32 ] ;
	new name	[ 32 ] ;
	new ip		[ 32 ] ;
	new fo_logfile	[ 64 ] ;
	new timp		[ 64 ] ;
	new maxtext	[ 256 ] ;
	
	new userid2 = get_user_userid ( player ) ;
	
	copy ( minutes , 7 , g_szBanTime [ id ] ) ;
	copy ( reason , 31 , g_szBanReason [ id ] ) ;
	
	get_user_ip	( player , ip , 31 , 1 ) ;
	get_time		( "[%d/%m/%Y] - [%H:%M:%S]" , timp , 63 ) ;
	get_user_authid	( player , authid2 , 31 ) ;
	get_user_authid	( id , authid , 31 ) ;
	get_user_name	( player , name2 , 31 ) ;
	get_user_name	( id , name , 31 ) ;
	get_configsdir	( fo_logfile , 63 ) ;
	
	format ( maxtext , 255 , "%s %s %s %s %s" , timp , name , name2 , minutes , reason ) ;
	format ( fo_logfile , 63 , "%s/ban_logs.txt" , fo_logfile ) ;
	
	write_file ( fo_logfile , maxtext , -1 ) ;
	
	new temp		[ 64 ] ;
	new banned	[ 16 ] ;
	new nNum =	str_to_num ( minutes ) ;
	
	if ( nNum )
	{
		format ( temp , 63 , "%L" , player , "FOR_MIN" , minutes ) ;
	}
	
	else
	
	{
		format ( temp , 63 , "%L" , player , "PERM" ) ;
	}
	
	format(banned, 15, "%L", player, "BANNED") ;
	
	new address [ 32 ] ;
	
	get_user_ip(player, address, 31, 1) ;
	
	client_print ( player , print_console , "*****************************" ) ;
	client_print ( player , print_console , "** MOTIV : %s **", reason ) ;
	client_print ( player , print_console , "** DURATA ( 0 = permanent ) : %s **" , minutes ) ;
	client_print ( player , print_console , "** ADMIN : %s **", name ) ;
	client_print ( player , print_console , "*****************************" ) ;
	client_print ( player , print_console , "** MOTIV : %s **", reason ) ;
	client_print ( player , print_console , "** DURATA ( 0 = permanent ) : %s **" , minutes ) ;
	client_print ( player , print_console , "** ADMIN : %s **", name ) ;
	client_print ( player , print_console , "*****************************" ) ;
	client_print ( player , print_console , "** MOTIV : %s **", reason ) ;
	client_print ( player , print_console , "** DURATA ( 0 = permanent ) : %s **" , minutes ) ;
	client_print ( player , print_console , "** ADMIN : %s **", name ) ;
	client_print ( player , print_console , "*****************************" ) ;
	client_print ( player , print_console , "** MOTIV : %s **", reason ) ;
	client_print ( player , print_console , "** DURATA ( 0 = permanent ) : %s **" , minutes ) ;
	client_print ( player , print_console , "** ADMIN : %s **", name ) ;
	client_print ( player , print_console , "*****************************" ) ;
	client_print ( player , print_console , "** MOTIV : %s **", reason ) ;
	client_print ( player , print_console , "** DURATA ( 0 = permanent ) : %s **" , minutes ) ;
	client_print ( player , print_console , "** ADMIN : %s **", name ) ;
	client_print ( player , print_console , "*****************************" ) ;
	
	set_hudmessage ( random_num ( 0 , 255 ) , random_num ( 0 , 255 ) , random_num ( 0 , 255 ) , -1.75 , 0.20 ) ;
	
	show_hudmessage ( 0 , "%s was BANNED!" , name2 ) ;
	
	ShowSyncHudMsg ( 0 , g_msgHudSync , "%s was BANNED!" , name2 ) ;
	ShowSyncHudMsg ( 0 , g_msgHudSync , "%s was BANNED!" , name2 ) ;
	
	if ( reason [ 0 ] )
	{
		server_cmd ( "kick #%d ^"Check Console. %s (%s %s)^";wait;addip ^"%s^" ^"%s^";wait;writeip;wait;writeid" , userid2 , reason , banned , temp , minutes , address ) ;
	}
	
	else
	
	{
		server_cmd ( "kick #%d ^"Check Console. %s %s^";wait;addip ^"%s^" ^"%s^";wait;writeip;wait;writeid" , userid2 , banned , temp , minutes , address ) ;
	}
	
	new msg [ 256 ];
	new len ;
	new maxpl = get_maxplayers ( ) ;
	
	for ( new i = 1 ; i <= maxpl ; i++ )
	{
		if ( is_user_connected ( i ) && !is_user_bot ( i ) )
		{
			len = formatex ( msg , charsmax ( msg ) , "%L" , i , "BAN" ) ;
			len += formatex ( msg [ len ] , charsmax ( msg ) - len , " %s " , name2 ) ;
			
			if ( nNum )
			{
				formatex ( msg [ len ] , charsmax ( msg ) - len , "%L" , i , "FOR_MIN" , minutes ) ;
			}
			
			else
			
			{
				formatex ( msg [ len ] , charsmax ( msg ) - len , "%L" , i , "PERM" ) ;
			}
			
			if ( strlen ( reason ) > 0 )
			
			{
				formatex ( msg [ len ] , charsmax ( msg ) - len , " (%L: %s)" , i , "REASON" , reason ) ;
			}
			
			show_activity_id ( i , id , name , msg ) ;
		}
	}
	return PLUGIN_HANDLED ;
}

// Stochare Chat Colorat
stock chat_color ( const id , const input[ ] , any:... )
{
	new count = 1, players [ 32 ] ;
	static msg [ 191 ] ;
	vformat ( msg , 190 , input , 3 ) ;
	replace_all ( msg , 190 , "\verde\" , "^4" ) ;
	replace_all ( msg , 190 , "\normal\" , "^1" ) ;
	replace_all ( msg , 190 , "\culoare_echipa\" , "^3" ) ;
	if ( id ) players [ 0 ] = id ; else
	get_players ( players , count , "ch" ) ;
	{
		for ( new i = 0 ; i < count ; i++ )
		{
			if ( is_user_connected ( players [ i ] ) )
			{
				message_begin ( MSG_ONE_UNRELIABLE , get_user_msgid ( "SayText" ) , _ , players [ i ] ) ;
				write_byte ( players [ i ] ) ;
				write_string ( msg ) ;
				message_end ( ) ;
			}
		}
	}
}