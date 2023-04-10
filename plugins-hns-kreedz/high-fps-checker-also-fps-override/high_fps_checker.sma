#include < amxmodx >
#include <regex>

#define PLUGIN_VERSION "1.0"

#define VALIDE_FLOAT_REGEX "^^[0-9]*\.[0-9]+([eE][0-9]+)?$"
#define INVALIDE_FLOAT_REGEX "^^.*\..*\..*$"

#define TASK_FREQ 0.8

new cvars[2], Float:flcvars[2], /*Regex:gPatternValidFloat,*/ Regex:gPatternInvalidFloat, regex_return

public plugin_init( )
{
    register_plugin( "Fps Limit", PLUGIN_VERSION, "DoNii" );

    register_cvar( "fps_limit_cvar", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );

    cvars[0]=register_cvar("amx_fps_max","101.0")
    cvars[1]=register_cvar("amx_fps_override","0.0")
    flcvars[0]=get_pcvar_float(cvars[0])
    flcvars[1]=get_pcvar_float(cvars[1])

    //gPatternValidFloat = regex_compile(VALIDE_FLOAT_REGEX, regex_return, "", 0)
    gPatternInvalidFloat = regex_compile(INVALIDE_FLOAT_REGEX, regex_return, "", 0)

    set_task( TASK_FREQ, "OnTaskCheckCvars", _, _, _, "b" );
}
public plugin_end()
{
    //regex_free(gPatternValidFloat)
    regex_free(gPatternInvalidFloat)
}
public OnTaskCheckCvars( )
{
    static szPlayers[ 32 ], iNum;get_players( szPlayers, iNum, "ch" );
    if(!iNum)
    {
        return
    }

    static i, iTempID;
    for( i=0; i < iNum; i++ )
    {
        iTempID = szPlayers[ i ];
        
        query_client_cvar( iTempID, "fps_max", "OnCvarResult" );
        query_client_cvar( iTempID, "fps_override", "OnCvarResult" );
    }
}
public OnCvarResult( id, const szCvar[ ], const szValue[ ], const param[ ] )
{
    if(regex_match_c(szValue, gPatternInvalidFloat, regex_return) > 0)
    {
        server_cmd( "kick #%d Invalid value for %s", get_user_userid( id ),szCvar);
        //regex_free(gPatternInvalidFloat)
        return
    }

    static Float:fValue, szReason[100]

    fValue = floatstr(szValue);
    
    switch(szCvar[4])
    {
        case 'm', 'M':
        {
            floatclamp(fValue, 0.0, flcvars[0])
            if( fValue > flcvars[0] )
            {
                formatex( szReason, charsmax( szReason ), "^n***************************^n** Kicked due to invalid fps_max **^n** -> Set fps_max to %.1f <- ** ^n***************************", flcvars[0] );
                engclient_print( id, engprint_console, szReason );

                server_cmd( "kick #%d", get_user_userid( id ));
            }
        }
        case 'o', 'O':
        {
            floatclamp(fValue, 0.0, flcvars[1])
            if( fValue != flcvars[1] )
            {
                formatex( szReason, charsmax( szReason ), "^n***************************^n** Kicked due to invalid fps_override **^n** -> Set fps_override to %.1f <- **^n***************************", flcvars[1] );
                engclient_print( id, engprint_console, szReason );

                server_cmd( "kick #%d", get_user_userid( id ));
            }
        }
    }
}