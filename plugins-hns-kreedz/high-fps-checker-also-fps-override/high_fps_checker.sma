#include < amxmodx >

#define PLUGIN_VERSION "1.0"

#define TASK_FREQ 0.8

new Trie:g_tCvars;

const g_iFpsMax = 101;
const g_iFpsOverride = 0;

public plugin_cfg( )
{
    g_tCvars = TrieCreate( );

    new szFpsMax[ 3 ], szFpsOverride[ 1 ];
    num_to_str( g_iFpsMax, szFpsMax, charsmax( szFpsMax ) );
    num_to_str( g_iFpsOverride, szFpsOverride, charsmax( szFpsOverride ) );
    
    TrieSetString( g_tCvars, "fps_max", szFpsMax );
    TrieSetString( g_tCvars, "fps_override", szFpsOverride );
    
    set_task( TASK_FREQ, "OnTaskCheckCvars", _, _, _, "b" );
}

public plugin_init( )
{
    register_plugin( "Fps Limit", PLUGIN_VERSION, "DoNii" );
    register_cvar( "fps_limit_cvar", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
}

public plugin_end( )
TrieDestroy( g_tCvars );

public client_connect( id )
{
    client_cmd( id, "cl_filterstuffcmd 0;fps_max %d;fps_override %d", g_iFpsMax, g_iFpsOverride );
}

public OnTaskCheckCvars( )
{
    new szPlayers[ 32 ], iNum;
    get_players( szPlayers, iNum, "c" );

    static iTempID;

    for( new i; i < iNum; i++ )
    {
        iTempID = szPlayers[ i ];
        
        query_client_cvar( iTempID, "fps_max", "OnCvarResult" );
        query_client_cvar( iTempID, "fps_override", "OnCvarResult" );
    }
}

public OnCvarResult( id, const szCvar[ ], const szValue[ ] )
{ 
    new szValueCheck[ 4 ], szReason[ 128 ];
    TrieGetString( g_tCvars, szCvar, szValueCheck, charsmax( szValueCheck ) );
    
    new iValue = str_to_num( szValue );
    
    if( equal( szCvar, "fps_max" ) )
    {    
        if( iValue > g_iFpsMax )
        {
            formatex( szReason, charsmax( szReason ), "^n***************************^n** Kicked due to invalid fps_max **^n** -> Set fps_max to %d <- ** ^n***************************", g_iFpsMax );
            
            server_cmd( "kick #%d", get_user_userid( id ));
            client_print( id, print_console, szReason );
        }
    }
    
    else if( equal( szCvar, "fps_override" ) )
    {
        if( iValue != g_iFpsOverride )
        {
            formatex( szReason, charsmax( szReason ), "^n***************************^n** Kicked due to invalid fps_override **^n** -> Set fps_override to %d <- **^n***************************", g_iFpsOverride );
            
            server_cmd( "kick #%d", get_user_userid( id ));
            client_print( id, print_console, szReason );
        }
    }
    return PLUGIN_CONTINUE;
}  