#include <amxmodx>
#include <amxmisc>

// Fisier descarcat de pe www.eXtreamCS.com !
// Ghostchat disabled by default
new ghostchat = 3; // Set to let HLTV see alive chat by default.
new gmsgSayText;
new logfilename[256];

// Return current setting or set new value
public handle_ghostchat(id,level,cid) {

    // No switches given
    if (read_argc() < 2) {
        new status[55];
        if (ghostchat == 1) {
            copy(status, 55, "Dead can read alive");
        }
        else if (ghostchat == 2) {
            copy(status, 55, "Dead and alive can read eachother");
        }
        else if (ghostchat == 3) {
            copy(status, 55, "HLTV can read chat of the living");
        }
        else {
            copy(status, 55, "Disabled");
        }
        client_print(id,print_console,"[AMX] Ghostchat status: %s (NOT TEAMSAY)", status);
        if (cmd_access(id,ADMIN_LEVEL_B,cid,0)) 
           client_print(id,print_console,"[AMX] Ghostchat usage: amx_ghostchat 0(disabled), 1(Dead can read alive), 2(Dead and alive can chat), 3(Only HLTV can read alive)");
        return PLUGIN_HANDLED;
    }

    // If you don't have enough rights, you can't change anything
    if (!cmd_access(id,ADMIN_LEVEL_B,cid,0))
        return PLUGIN_HANDLED;
    
    new arg[2];
    read_argv(1,arg,2);

    if (equal(arg,"0",1)) {
        ghostchat = 0;
        client_print(0,print_chat,"[AMX] Ghostchat - Plugin has been disabled");
    }
    else if (equal(arg,"1",1)) {
        ghostchat = 1;
        client_print(0,print_chat,"[AMX] Ghostchat - Dead people can read the chat of the living (NOT TEAMSAY)!");
    }
    else if (equal(arg,"2",1)) {
        ghostchat = 2;
        client_print(0,print_chat,"[AMX] Ghostchat - Dead and living people can talk to eachother (NOT TEAMSAY)!");
    }
    else if (equal(arg,"3",1)) {
        ghostchat = 3;
        client_print(0,print_chat,"[AMX] Ghostchat - HLTV can read chat of the living (NOT TEAMSAY)!");
    }

    new authid[16],name[32];
    get_user_authid(id,authid,16);
    get_user_name(id,name,32);

    log_to_file(logfilename,"Ghostchat: ^"%s<%d><%s><>^" amx_ghostchat %s",name,get_user_userid(id),authid,arg);
    return PLUGIN_HANDLED;
}

public handle_say(id) {
    // If plugin is disabled, skip the code
    if (ghostchat <= 0)
       return PLUGIN_CONTINUE;

    // Gather information
    new is_alive = is_user_alive(id);
    new message[129];
    read_argv(1,message,128);
    new name[33];
    get_user_name(id,name,32);
    new player_count = get_playersnum();
    new players[32];
    get_players(players, player_count, "c");

    // Clients sometimes send empty messages, or a message containig a '[', ignore those.
    if (equal(message,"")) return PLUGIN_CONTINUE;
    if (equal(message,"[")) return PLUGIN_CONTINUE;
 
    // Response to a specific query
    if (containi(message,"[G]") != -1)
        client_print(id,print_chat,"[AMX] Ghostchat - Type amx_ghostchat in console for current status");
    
    // Format the messages, the %c (2) adds the color. The client decides what color
    // it gets by looking at team.
    if (is_alive) format(message, 127, "%c[G]*MORT*%s :    %s^n", 2, name, message);
    else format(message, 127, "%c[G]*VIU*%s :    %s^n", 2, name, message);

    // Check all players wether they should receive the message or not
    for (new i = 0; i < player_count; i++) {

      if (is_alive && !is_user_alive(players[i])) {
         // Talking person alive, current receiver dead
         if ((ghostchat == 3 && is_user_hltv(players[i])) || ghostchat <= 2) {
             // Either HLTV mode is enabled and current player is HLTV
             // or one of the other modes is enabled...
             message_begin(MSG_ONE,gmsgSayText,{0,0,0},players[i]);
             write_byte(id);
             write_string(message);
             message_end();
         }
      }
      else if (!is_alive && is_user_alive(players[i]) && ghostchat == 2) {
         // Talking person is dead, current receiver alive
         message_begin(MSG_ONE,gmsgSayText,{0,0,0},players[i]);
         write_byte(id);
         write_string(message);
         message_end();
      }
    }
    return PLUGIN_CONTINUE;
}

public plugin_init() {
    register_plugin("Ghostchat", "0.3", "NetRipper");
    register_clcmd("say", "handle_say");
    register_concmd("amx_ghostchat", "handle_ghostchat",-1,"<mode>");

    gmsgSayText = get_user_msgid("SayText");
    get_time("addons/amx/logs/admin%m%d.log",logfilename,255) 

    return PLUGIN_CONTINUE;
}
