#include <amxmodx>
#include <fakemeta>
#include <amxmisc>
 
#define PLUGIN "Spec-Bots"
#define VERSION "1.0"
#define AUTHOR "Author"
 
new g_pEnable;
new g_pMaxPlayers;
new g_pBotName, g_pBotName2, g_pBotName3
new bool:bot_on, bot_on2, bot_on3;
 
public plugin_init() {
    // Plugin registration
    register_plugin(PLUGIN, VERSION, AUTHOR);
 
    // Plugin OFF-ON on values 0-1
    g_pEnable = register_cvar("bs_enable", "1");
 
    // Bot nicknames
    g_pBotName = register_cvar("bs_botname", "RESPAWN.OLDGODS.RO (dns)");
    g_pBotName2 = register_cvar("bs_botname2", "89.40.233.100:27015 (IP)");
    g_pBotName3 = register_cvar("bs_botname3", "forum: oldgods.ro/forum");
 
    // Min-Max values 5 & 29 - Disconnect happens at value + 1
    g_pMaxPlayers = create_cvar("bs_maxplayers", "29.0", FCVAR_NONE, _, true, 5.0, true, 29.0);
 
    // Sets bot connection confirmations off on each map change
    bot_on = false;
    bot_on2 = false;
    bot_on3 = false;
 
    // Checks and connects bots every 60s if requirements are met
    if(get_pcvar_num(g_pEnable)) {
        set_task(60.0, "AddBots", 0, _, _, "b");
    }
 
}
 
// On every client connection removes bots if threshold + 1 has been reached or surpassed
public client_connect(id) {
    if(get_pcvar_num(g_pEnable)) {
        if(get_playersnum(1) >= get_pcvar_num(g_pMaxPlayers) + 1) {
            RemoveBots();
        }
    }
}
 
// Removal of bots
public RemoveBots() {
        new szBotName[35];
        get_pcvar_string(g_pBotName, szBotName, charsmax(szBotName));
        server_cmd("kick ^"%s^"", szBotName);
        bot_on = false;
        new szBotName2[35];
        get_pcvar_string(g_pBotName2, szBotName2, charsmax(szBotName2));
        server_cmd("kick ^"%s^"", szBotName2);
        bot_on2 = false;
        new szBotName3[35];
        get_pcvar_string(g_pBotName3, szBotName3, charsmax(szBotName3));
        server_cmd("kick ^"%s^"", szBotName3);
        bot_on3 = false;
}
 
// Adds up to 3 bots if they're not connected and there's less players than the threshold
public AddBots() {
    if(get_playersnum(1) < get_pcvar_num(g_pMaxPlayers) && !bot_on) {
        AddBot();
        if(get_playersnum(1) < get_pcvar_num(g_pMaxPlayers) && !bot_on2) {
            AddBot2();
            if(get_playersnum(1) < get_pcvar_num(g_pMaxPlayers) && !bot_on3) {
                AddBot3();
            }
        }
    }
}
 
/* ------------- BOT CREATION ------------- */
public AddBot() {
    new szBotName[35];
    get_pcvar_string(g_pBotName, szBotName, charsmax(szBotName));
 
    new id = engfunc(EngFunc_CreateFakeClient, szBotName);
    if(!id) {
        return;
    }
    engfunc(EngFunc_FreeEntPrivateData, id);
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT);
 
    new szMsg[128];
    dllfunc(DLLFunc_ClientConnect, id, szBotName, "127.0.0.1", szMsg);
    dllfunc(DLLFunc_ClientPutInServer, id);
 
    bot_on = true;
}
 
public AddBot2() {
    new szBotName2[35];
    get_pcvar_string(g_pBotName2, szBotName2, charsmax(szBotName2));
 
    new id = engfunc(EngFunc_CreateFakeClient, szBotName2);
    if(!id) {
        return;
    }
    engfunc(EngFunc_FreeEntPrivateData, id);
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT);
 
    new szMsg[128];
    dllfunc(DLLFunc_ClientConnect, id, szBotName2, "127.0.0.1", szMsg);
    dllfunc(DLLFunc_ClientPutInServer, id);
 
    bot_on2 = true;
}
 
public AddBot3() {
    new szBotName3[35];
    get_pcvar_string(g_pBotName3, szBotName3, charsmax(szBotName3));
 
    new id = engfunc(EngFunc_CreateFakeClient, szBotName3);
    if(!id) {
        return;
    }
    engfunc(EngFunc_FreeEntPrivateData, id);
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT);
 
    new szMsg[128];
    dllfunc(DLLFunc_ClientConnect, id, szBotName3, "127.0.0.1", szMsg);
    dllfunc(DLLFunc_ClientPutInServer, id);
 
    bot_on3 = true;
}
/* ------------- END BOT CREATION ------------- */
 
