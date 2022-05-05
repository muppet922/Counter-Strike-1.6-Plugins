#include <amxmodx>
#include <hamsandwich>
#include <zombie_plague_special>

// Uncomment this if you want to show the taken damage
//#define SHOW_DAMAGE_ON_MESSAGE

// Integers
new g_iMaxPlayers

// Bools
new bool:g_bIsConnected[33]

// Macros
#define IsConnected(%1) (1 <= %1 <= g_iMaxPlayers && g_bIsConnected[%1])

#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "meTaLiCroSS"

public plugin_init()
{
    register_plugin("[ZP] Addon: Zombie HP Displayer", PLUGIN_VERSION, PLUGIN_AUTHOR)

    RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage_Post", 1)

    g_iMaxPlayers = get_maxplayers()
}

public client_putinserver(iId) g_bIsConnected[iId] = true
public client_disconnected(iId) g_bIsConnected[iId] = false

public fw_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iDamageType)
{
    if(!IsConnected(iAttacker) || iVictim == iAttacker)
        return HAM_IGNORED

    if(zp_get_user_zombie(iVictim))
    {
        // I use statics variables
        // because this forward can (or not)
        // be called many times.
        static iVictimHealth
        iVictimHealth = get_user_health(iVictim)

        if(iVictimHealth)
        #if defined SHOW_DAMAGE_ON_MESSAGE
            client_print(iAttacker, print_center, "You did %.1f Damage. Health Remaining: %d", flDamage, iVictimHealth)
        #else
            client_print(iAttacker, print_center, "Health Remaining: %d", iVictimHealth)
        #endif
        else
            client_print(iAttacker, print_center, "You Killed him")

        return HAM_HANDLED
    }

    return HAM_IGNORED
}
