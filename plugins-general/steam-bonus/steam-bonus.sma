#include <amxmodx> 
#include <cstrike> 
#include <fakemeta_util> 
#include <hamsandwich>          
 
#define REGISTRATION "STEAM BONUS", "rz 0.2", "[N][E][M][E][C]"
#define LEN_BUFFER 32
#define ROUND 3

enum _: DATA {WEAPON_NAME[LEN_BUFFER], WEAPON_ID, WEAPON_AMMO, SZ_WEAPON[LEN_BUFFER]};
new const szBonusWeapon[][DATA] = {          
    {"weapon_ak47", CSW_AK47, 90, "AK 47"},
    {"weapon_m4a1", CSW_M4A1, 90, "M 16"}, 
    {"weapon_awp", CSW_AWP, 30, "AWP"}, 
    {"weapon_famas", CSW_FAMAS, 90, "FAMAS"}                                
};

new iWeapon[] = {CSW_SCOUT, CSW_XM1014, CSW_MAC10, CSW_AUG, CSW_UMP45, CSW_SG550, CSW_GALIL, CSW_FAMAS, CSW_AWP, CSW_MP5NAVY, CSW_M249, CSW_M3, CSW_M4A1, CSW_TMP, CSW_G3SG1, CSW_SG552, CSW_AK47, CSW_P90};                       
new g_CHSO, g_iRound;                       

public plugin_init() {         
    register_plugin(REGISTRATION);                      

    new const szBlockMap[][] = {                                                                        
        "awp_india", 
        "fy_pool_day", 
        "aim_map_hlo",   
        "35hp_2",                                                                                                     
        "fy_snow" 
    };
    
    new szBuffer[LEN_BUFFER+1]; get_mapname(szBuffer, LEN_BUFFER);

    for(new i; i < sizeof szBlockMap; ++ i) { 
        if(equal(szBlockMap[i], szBuffer)) 
            pause("d");                                         
    } 
 
    register_event("HLTV", "Round", "a", "1=0", "2=0"); 
    register_event("TextMsg", "RestartRound", "a", "2=#Game_will_restart_in","2=#Game_Commencing");
    
    RegisterHam(Ham_Spawn, "player", "SpawnPlayer", true);
 
    g_CHSO = CreateHudSyncObj(); 
} 
 
public RestartRound()    
    g_iRound = 0; 
 
public Round()                                     
    ++ g_iRound;                   
 
public SpawnPlayer(id) { 
    if(!is_user_alive(id) || g_iRound < ROUND || !is_user_steam(id)) 
        return;                               

    new iRandom = random_num(0, charsmax(szBonusWeapon));

    for(new i; i < sizeof iWeapon; ++ i)             
        fm_strip_user_gun(id, iWeapon[i]);

    fm_give_item(id, szBonusWeapon[iRandom][WEAPON_NAME]);
    cs_set_user_bpammo(id, szBonusWeapon[iRandom][WEAPON_ID], szBonusWeapon[iRandom][WEAPON_AMMO]);
    
    set_hudmessage(255, 255, 255, -1.0, 0.55, _, _, 5.0, _, _, false);
    ShowSyncHudMsg(id, g_CHSO, "+бонус %s, за STEAM", szBonusWeapon[iRandom][SZ_WEAPON]);         
}                                                                                            
 
stock bool:is_user_steam(id) { 
    static dp_pointer; 
 
    if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider"))) { 
        server_cmd("dp_clientinfo %d", id); 
        server_exec(); 
        return (get_pcvar_num(dp_pointer) == 2) ? true : false; 
    }
    
    return false; 
} 