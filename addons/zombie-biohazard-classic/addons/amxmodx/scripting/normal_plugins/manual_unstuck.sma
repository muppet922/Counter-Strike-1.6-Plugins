
   /* - - - - - - - - - - -

        AMX Mod X script.

          | Author  : Arkshine
          | Plugin  : Unstick Player
          | Version : v1.0.2

        (!) Support : http://forums.alliedmods.net/showthread.php?p=717994#post717994 .
        (!) Requested by Rirre.

        This program is free software; you can redistribute it and/or modify it
        under the terms of the GNU General Public License as published by the
        Free Software Foundation; either version 2 of the License, or (at
        your option) any later version.

        This program is distributed in the hope that it will be useful, but
        WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
        General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software Foundation,
        Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

        ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~


        Description :
        - - - - - - -
            Unstuck player via a client command.


        Requirement :
        - - - - - - -
            * All mods, except NS.
            * AMX Mod X 1.7x or higher.


        Modules :
        - - - - -
            * Fakemeta

            
        Credits :
        - - - - - 
            * AMX Mod X Team. ( original plugin )

            
        Changelog :
        - - - - - -
            v1.0.2 : [ 25 nov 2008 ]

                (+) Initial release.

    - - - - - - - - - - - */
    
    #include <amxmodx>
    #include <fakemeta>
    
    
    #define START_DISTANCE    32   // --| The first search distance for finding a free location in the map.
    #define MAX_ATTEMPTS      128  // --| How many times to search in an area for a free space.
    
    #define TASK_LOOP_ADVERT  9999   // --| Show advert message every x seconds.
   new const gs_AdvertMessage[] = "";
    
    
    #define MAX_CLIENTS     32
    
    new Float:gf_LastCmdTime[ MAX_CLIENTS + 1 ];
    new gp_UnstuckFrequency;
    new gh_MsgSync;
    
    // --| Just for readability.
    enum Coord_e { Float:x, Float:y, Float:z };
    
    // --| Macro.
    #define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )
    
    
    public plugin_init ()
    {
        register_plugin ( "Unstick Player", "1.0.2", "Arkshine" );
        
        // --| Cvars.
        gp_UnstuckFrequency = register_cvar ( "amx_unstuck_frequency", "4.0" );
        
        // --| Client command.
        register_clcmd ( "say_team /stuck"  , "ClientCommand_UnStick" );
        register_clcmd ( "say /stuck"       , "ClientCommand_UnStick" );
        register_clcmd ( "say_team /unstuck", "ClientCommand_UnStick" );
        register_clcmd ( "say /unstuck"     , "ClientCommand_UnStick" );
        
        gh_MsgSync = CreateHudSyncObj ();
        set_task ( float ( TASK_LOOP_ADVERT ), "Task_LoopAdvert", _, _, _, "b" );
    }
    
    
    public Task_LoopAdvert ()
    {
        set_hudmessage ( 0, 50, 200, 0.01, 0.93, 0, 9.0, 15.0, 0.1, 0.2, -1 ); 
        ShowSyncHudMsg ( 0, gh_MsgSync, gs_AdvertMessage );
    }
    
    
    public ClientCommand_UnStick ( const id )
    {
        new Float:f_MinFrequency = get_pcvar_float ( gp_UnstuckFrequency );
        new Float:f_ElapsedCmdTime = get_gametime () - gf_LastCmdTime[ id ];
        
        if ( f_ElapsedCmdTime < f_MinFrequency ) 
        {
            client_print ( id, print_chat, "[Biohazard] You have to wait %.1f seconds before you can unstuck.", f_MinFrequency - f_ElapsedCmdTime );
            return PLUGIN_HANDLED;
        }
        
        gf_LastCmdTime[ id ] = get_gametime ();
    
        new i_Value;
        
        if ( ( i_Value = UTIL_UnstickPlayer ( id, START_DISTANCE, MAX_ATTEMPTS ) ) != 1 )
        {
            switch ( i_Value )
            {
                case 0  : client_print ( id, print_chat, "[Biohazard] Couldn't find a free spot to move you" );
                case -1 : client_print ( id, print_chat, "[Biohazard] You can not use this command if you are dead" );
            }
        }
        
        return PLUGIN_CONTINUE;
    }
    
    
    UTIL_UnstickPlayer ( const id, const i_StartDistance, const i_MaxAttempts )
    {
        // --| Not alive, ignore.
        if ( !is_user_alive ( id ) )  return -1
        
        static Float:vf_OriginalOrigin[ Coord_e ], Float:vf_NewOrigin[ Coord_e ];
        static i_Attempts, i_Distance;
        
        // --| Get the current player's origin.
        pev ( id, pev_origin, vf_OriginalOrigin );
        
        i_Distance = i_StartDistance;
        
        while ( i_Distance < 1000 )
        {
            i_Attempts = i_MaxAttempts;
            
            while ( i_Attempts-- )
            {
                vf_NewOrigin[ x ] = random_float ( vf_OriginalOrigin[ x ] - i_Distance, vf_OriginalOrigin[ x ] + i_Distance );
                vf_NewOrigin[ y ] = random_float ( vf_OriginalOrigin[ y ] - i_Distance, vf_OriginalOrigin[ y ] + i_Distance );
                vf_NewOrigin[ z ] = random_float ( vf_OriginalOrigin[ z ] - i_Distance, vf_OriginalOrigin[ z ] + i_Distance );
            
                engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize ( id ), id, 0 );
            
                // --| Free space found.
                if ( get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) )
                {
                    // --| Set the new origin .
                    engfunc ( EngFunc_SetOrigin, id, vf_NewOrigin );
                    return 1;
                }
            }
            
            i_Distance += i_StartDistance;
        }
        
        // --| Could not be found.
        return 0;
    }    
    