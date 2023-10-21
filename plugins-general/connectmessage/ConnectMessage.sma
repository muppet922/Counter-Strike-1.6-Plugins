#include <amxmodx>
#include <json>

#pragma semicolon 1
#define GetRandomMessage(%0) ArrayGetString(MessagesList,random_num(0,ArraySize(MessagesList)-1),%0,charsmax(%0))
#define MAX_CHATMSG_LENGTH 187

// Длина приветственного сообщения
#define CONNECT_MSG_LENGTH 128

// Задержка перед показом сообщения
#define SHOW_MSG_DELAY 1.0

new const PLUG_NAME[] = "Connect Message";
new const PLUG_VER[] = "1.0.0";

new Array:MessagesList;

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");

    LoadMessages();

    server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

public client_putinserver(UserId)
{
	if(!is_user_connected(UserId))
		return;
}

public Task_ShowMessage(const UserId){
    static Msg[MAX_CHATMSG_LENGTH]; GetRandomMessage(Msg);

    replace_all(Msg, charsmax(Msg), "%%Name%%", fmt("^4%n^3", UserId));

    client_print_color(0, print_team_default, "^4[^3Connect^4] ^3%s", Msg);
}

LoadMessages(){
    if(MessagesList != Invalid_Array)
        ArrayDestroy(MessagesList);
    MessagesList = ArrayCreate(CONNECT_MSG_LENGTH, 8);

    new File[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", File, charsmax(File));
    add(File, charsmax(File), "/plugins/ConnectMessage/Messages.json");
    if(!file_exists(File)){
        set_fail_state("[ERROR] Config file '%s' not found", File);
        return;
    }
    
    new JSON:List = json_parse(File, true);
    if(!json_is_array(List)){
        json_free(List);
        set_fail_state("[ERROR] Invalid config structure. File '%s'.", File);
        return;
    }

    new Msg[CONNECT_MSG_LENGTH];
    for(new i = 0; i < json_array_get_count(List); i++){
        json_array_get_string(List, i, Msg, charsmax(Msg));
        ArrayPushString(MessagesList, Msg);
    }
    json_free(List);
}