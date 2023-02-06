#include <amxmod>
#include <biohazard>
#include <amxmisc>

#define MAX_PLAYERS 32 

new const Float:g_flCoords[][] =  
{ 
    {0.50, 0.40}, 
    {0.56, 0.44}, 
    {0.60, 0.50}, 
    {0.56, 0.56}, 
    {0.50, 0.60}, 
    {0.44, 0.56}, 
    {0.40, 0.50}, 
    {0.44, 0.44} 
}

new const g_iColors[][] = 
{ 
    	{0, 127, 255}, // blue 
    	{255, 127, 0}, // orange 
    	{127, 0, 255}, // purple 
   	{255, 0, 0}, 	// red 
   	{255, 100, 150}, // pink 
	{0, 255, 0}
}

new g_iPlayerPos[MAX_PLAYERS+1]
new g_iPlayerCol[MAX_PLAYERS+1]
new g_iMaxPlayers

public plugin_init()
{
    register_plugin( "Bullet Damage", "0.0.2", "ConnorMcLeod" )
    register_event("Damage", "Event_Damage", "b", "2>0", "3=0")
    g_iMaxPlayers = get_maxplayers()
}

public Event_Damage( iVictim )
{
    if(read_data(4) || read_data(5) || read_data(6))
    {
        new id = get_user_attacker(iVictim)
        if( (1 <= id <= g_iMaxPlayers) && is_user_connected(id) && !is_user_zombie(id) )
        {
            new iPos = ++g_iPlayerPos[id]
            if( iPos == sizeof(g_flCoords) )
            {
                iPos = g_iPlayerPos[id] = 0
            }

            new iCol = ++g_iPlayerCol[id]
            if( iCol == sizeof(g_iColors) )
            {
                iCol = g_iPlayerCol[id] = 0
            }

            set_hudmessage(g_iColors[iCol][0], g_iColors[iCol][1], g_iColors[iCol][2], Float:g_flCoords[iPos][0], Float:g_flCoords[iPos][1], 0, 0.1, 2.5, 0.02, 0.02, -1)
            show_hudmessage(id, "%d", read_data(2))
        } 
    } 
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
