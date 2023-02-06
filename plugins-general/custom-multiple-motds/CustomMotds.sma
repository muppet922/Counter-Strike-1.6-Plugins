#include <amxmodx>
#include <json>

#pragma semicolon 1

new const CHAT_PREFIX[] = "^4[^3MOTD^4]";

enum MotdType{
    MT_Undefined = 0,

    MT_File,
    MT_Site,
}

enum _:E_MotdData{
    MD_Title[128],
    MotdType:MD_Type,
    MD_Url[PLATFORM_MAX_PATH],
}

new Trie:Motds;

new const PLUG_NAME[] = "Custom MOTDs";
new const PLUG_VER[] = "1.0.1";

public plugin_init(){
    register_plugin(PLUG_NAME, PLUG_VER, "ArKaNeMaN");
    LoadMotds();
    server_print("[%s v%s] loaded.", PLUG_NAME, PLUG_VER);
}

public Cmd_ShowMOTD(const Id){
    static Cmd[32]; GetCmd(Cmd, charsmax(Cmd));
    if(TrieKeyExists(Motds, Cmd)){
        static Motd[E_MotdData]; TrieGetArray(Motds, Cmd, Motd, E_MotdData);
        switch(Motd[MD_Type]){
            case MT_File: {
                show_motd(Id, Motd[MD_Url], Motd[MD_Title]);
            }
            case MT_Site: {
                static Content[1024]; formatex(Content, charsmax(Content), "\
                    <!DOCTYPE HTML>\
                    <html>\
                        <head>\
                         <meta http-equiv=^"refresh^" content=^"0;url=%s^">\
                        </head>\
                    </html>\
                ", Motd[MD_Url]);
                show_motd(Id, Content, Motd[MD_Title]);
            }
        }
    }
    else client_print_color(Id, print_team_default, "%s ^3Что-то пошло не так... :(", CHAT_PREFIX);
}

LoadMotds(){
    Motds = TrieCreate();

    static file[PLATFORM_MAX_PATH];
    get_localinfo("amxx_configsdir", file, charsmax(file));
    add(file, charsmax(file), "/plugins/CustomMOTDs/list.json");
    if(!file_exists(file)){
        set_fail_state("[ERROR] Config file '%s' not found", file);
        return;
    }
    new JSON:List = json_parse(file, true);
    if(!json_is_object(List)){
        set_fail_state("[ERROR] Invalid config structure. File '%s'", file);
        return;
    }
    static Cmd[32], JSON:Item, Data[E_MotdData], temp[32];
    for(new i = 0; i < json_object_get_count(List); i++){
        json_object_get_name(List, i, Cmd, charsmax(Cmd));
        Item = json_object_get_value(List, Cmd);
        if(!json_is_object(Item)){
            set_fail_state("[ERROR] Invalid config structure. File '%s'", file);
            return;
        }

        json_object_get_string(Item, "Type", temp, charsmax(temp));
        Data[MD_Type] = GetMOTDType(temp);
        if(!Data[MD_Type]){
            set_fail_state("[ERROR] Undefined MOTD type '%s'", temp);
            return;
        }
        json_object_get_string(Item, "Url", Data[MD_Url], charsmax(Data[MD_Url]));
        if(Data[MD_Type] == MT_File && !file_exists(Data[MD_Url])){
            set_fail_state("[ERROR] MOTD file '%s' not found", Data[MD_Url]);
            return;
        }
        json_object_get_string(Item, "Title", Data[MD_Title], charsmax(Data[MD_Title]));

        TrieSetArray(Motds, Cmd, Data, E_MotdData);

        RegisterClCmds(Cmd, "Cmd_ShowMOTD");

        json_free(Item);
    }
    json_free(List);
}

RegisterClCmds(const Cmd[], const Handler[]){
    register_clcmd(Cmd, Handler);
    static Cmd_[64]; formatex(Cmd_, charsmax(Cmd_), "say /%s", Cmd);
    register_clcmd(Cmd_, Handler);
    formatex(Cmd_, charsmax(Cmd_), "say_team /%s", Cmd);
    register_clcmd(Cmd_, Handler);
}

bool:GetCmd(Output[], len){
    static cmd[64];
    read_argv(0, cmd, charsmax(cmd));
    if(equal(cmd, "say") || equal(cmd, "say_team")){
        read_argv(1, cmd, charsmax(cmd));
        if(cmd[0] == '/'){
            formatex(Output, len, cmd[1]);
            return true;
        }
    }
    else{
        formatex(Output, len, cmd);
        return true;
    }
    return false;
}

MotdType:GetMOTDType(const Str[]){
    if(equal(Str, "file") || equal(Str, "File")) return MT_File;
    else if(equal(Str, "Site") || equal(Str, "site")) return MT_Site;
    return MT_Undefined;
}