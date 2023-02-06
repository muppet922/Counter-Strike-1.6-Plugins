enum CsInternalModel
{
    CS_NORESET     = -1,
    CS_DONTCHANGE  = 0,
    CS_UNASSIGNED  = 0,
    CS_CT_URBAN    = 1,
    CS_T_TERROR    = 2,
    CS_T_LEET      = 3,
    CS_T_ARCTIC    = 4,
    CS_CT_GSG9     = 5,
    CS_CT_GIGN     = 6,
    CS_CT_SAS      = 7,
    CS_T_GUERILLA  = 8,
    CS_CT_VIP      = 9,
    CZ_T_MILITIA   = 10,
    CZ_CT_SPETSNAZ = 11,
};
enum TraceResult
{
    TR_AllSolid,        // int
    TR_StartSolid,      // int
    TR_InOpen,          // int
    TR_InWater,         // int
    TR_flFraction,      // float
    TR_vecEndPos,       // float array[3]
    TR_flPlaneDist,     // float
    TR_vecPlaneNormal,  // float array[3]
    TR_pHit,            // int (edict_t*)
    TR_iHitgroup,       // int
};
enum
{
    print_notify = 1,
    print_console,
    print_chat,
    print_center,
    print_radio     /* Counter-Strike only */
};
#define DMG_NERVEGAS			(1 << 16)
#define TE_IMPLOSION			14
#define TE_PARTICLEBURST         	122
#define TE_DLIGHT                   	27
#define MOVETYPE_NONE                   0           
#define MOVETYPE_WALK                   3
#define MOVETYPE_STEP                   4           
#define MOVETYPE_FLY                    5
#define MOVETYPE_TOSS                   6         
#define MOVETYPE_PUSH                   7         
#define MOVETYPE_NOCLIP                 8           
#define MOVETYPE_FLYMISSILE             9           
#define MOVETYPE_BOUNCE                 10         
#define MOVETYPE_BOUNCEMISSILE          11         
#define MOVETYPE_FOLLOW                 12          
#define MOVETYPE_PUSHSTEP               13   
#define DAMAGE_NO                       0.0
#define DAMAGE_YES                      1.0
#define DAMAGE_AIM                      2.0    
#define SVC_DIRECTOR                    51
#define MSG_ONE_UNRELIABLE              8 
#define TE_BEAMPOINTS 0
#define TE_SPARKS 9
#define ET_IGNORE       0  
#define ET_STOP         1  
#define ET_STOP2        2 
#define ET_CONTINUE     3 
#define FP_CELL         0
#define DRC_CMD_MESSAGE                 6
#define charsmax(%1) (sizeof(%1)-1) 
#define is_user_valid_connected(%1) (1 <= %1 <= g_iMaxClients && g_bConnected[%1])
#define is_user_valid_alive(%1) (1 <= %1 <= g_iMaxClients && g_bAlive[%1])
#define ADMIN_ALL           0
#define SVC_PINGS           17
#define ADMIN_IMMUNITY      (1<<0)
#define ADMIN_RESERVATION   (1<<1)
#define ADMIN_KICK          (1<<2)
#define ADMIN_BAN           (1<<3)
#define ADMIN_SLAY          (1<<4)
#define ADMIN_MAP           (1<<5)
#define ADMIN_CVAR          (1<<6)
#define ADMIN_CFG           (1<<7)
#define ADMIN_CHAT          (1<<8)
#define ADMIN_VOTE          (1<<9)
#define ADMIN_PASSWORD      (1<<10)
#define ADMIN_RCON          (1<<11)
#define ADMIN_LEVEL_A       (1<<12)
#define ADMIN_LEVEL_B       (1<<13)
#define ADMIN_LEVEL_C       (1<<14)
#define ADMIN_LEVEL_D       (1<<15)
#define ADMIN_LEVEL_E       (1<<16)
#define ADMIN_LEVEL_F       (1<<17)
#define ADMIN_LEVEL_G       (1<<18)
#define ADMIN_LEVEL_H       (1<<19)
#define ADMIN_MENU          (1<<20)
#define ADMIN_BAN_TEMP      (1<<21)
#define ADMIN_ADMIN         (1<<24)
#define ADMIN_USER          (1<<25)
#define DMG_MORTAR          (1<<23)
#define ATTN_NONE       0.00
#define ATTN_NORM       0.80
#define ATTN_IDLE       2.00
#define ATTN_STATIC     1.25
#define CHAN_AUTO       0
#define CHAN_WEAPON     1
#define CHAN_VOICE      2
#define CHAN_ITEM       3
#define CHAN_BODY       4
#define CHAN_STREAM     5
#define CHAN_STATIC     6
#define CHAN_NETWORKVOICE_BASE  7
#define CHAN_NETWORKVOICE_END   500
#define PITCH_NORM      100
#define PITCH_LOW       95
#define PITCH_HIGH      120
#define MSG_BROADCAST               0
#define MSG_ONE                     1
#define MSG_ALL                     2
#define MSG_INIT                    3
#define MSG_PVS                     4
#define MSG_PAS                     5
#define MSG_PVS_R                   6
#define MSG_PAS_R                   7
#define MSG_ONE_UNRELIABLE          8
#define MSG_SPEC                    9
#define FL_FLY                          (1<<0)
#define FL_SWIM                         (1<<1)
#define FL_CONVEYOR                     (1<<2)
#define FL_CLIENT                       (1<<3)
#define FL_INWATER                      (1<<4)
#define FL_MONSTER                      (1<<5)
#define FL_GODMODE                      (1<<6)
#define FL_NOTARGET                     (1<<7)
#define FL_SKIPLOCALHOST                (1<<8) 
#define FL_ONGROUND                     (1<<9)
#define FL_PARTIALGROUND                (1<<10) 
#define FL_WATERJUMP                    (1<<11)
#define FL_FROZEN                       (1<<12) 
#define FL_FAKECLIENT                   (1<<13)
#define FL_DUCKING                      (1<<14)
#define FL_FLOAT                        (1<<15)
#define FL_GRAPHED                      (1<<16)
#define FL_IMMUNE_WATER                 (1<<17)
#define FL_IMMUNE_SLIME                 (1<<18)
#define FL_IMMUNE_LAVA                  (1<<19)
#define FL_PROXY                        (1<<20)
#define FL_ALWAYSTHINK                  (1<<21)
#define FL_BASEVELOCITY                 (1<<22) 
#define FL_MONSTERCLIP                  (1<<23)
#define FL_ONTRAIN                      (1<<24)
#define FL_WORLDBRUSH                   (1<<25)
#define FL_SPECTATOR                    (1<<26)
#define FL_CUSTOMENTITY                 (1<<29)
#define FL_KILLME                       (1<<30)
#define FL_DORMANT                      (1<<31)
#define DMG_BULLET                      (1<<1)
#define IN_ATTACK                       (1<<0)
#define IN_JUMP                         (1<<1)
#define IN_DUCK                         (1<<2)
#define IN_FORWARD                      (1<<3)
#define IN_BACK                         (1<<4)
#define IN_USE                          (1<<5)
#define IN_CANCEL                       (1<<6)
#define IN_LEFT                         (1<<7)
#define IN_RIGHT                        (1<<8)
#define IN_MOVELEFT                     (1<<9)
#define IN_MOVERIGHT                    (1<<10)
#define IN_ATTACK2                      (1<<11)
#define IN_RUN                          (1<<12)
#define IN_RELOAD                       (1<<13)
#define IN_ALT1                         (1<<14)
#define IN_SCORE                        (1<<15)
#define DMG_BLAST                       (1<<6)
#define CSW_P228 1
#define CSW_SCOUT 3
#define CSW_HEGRENADE 4
#define CSW_XM1014 5
#define CSW_MAC10 7
#define CSW_AUG 8
#define CSW_SMOKEGRENADE 9
#define CSW_ELITE 10
#define CSW_FIVESEVEN 11
#define CSW_UMP45 12
#define CSW_SG550 13
#define CSW_GALIL 14
#define CSW_FAMAS 15
#define CSW_USP 16
#define CSW_GLOCK18 17
#define CSW_AWP 18
#define CSW_MP5NAVY 19
#define CSW_M249 20
#define CSW_M3 21
#define CSW_M4A1 22
#define CSW_TMP 23
#define CSW_G3SG1 24
#define CSW_FLASHBANG 25
#define CSW_DEAGLE 26
#define CSW_SG552 27
#define CSW_AK47 28
#define CSW_P90 30
#define CSW_KNIFE 29
#define CSW_C4 6
#define SVC_TEMPENTITY          23
#define TE_BEAMENTPOINT 1
#define TE_LAVASPLASH               10
#define SOLID_NOT                       0  
#define SOLID_TRIGGER                   1 
#define SOLID_BBOX                      2  
#define SOLID_SLIDEBOX                  3    
#define SOLID_BSP                       4   
#define HULL_POINT                      0
#define HULL_HUMAN                      1
#define HULL_LARGE                      2
#define HULL_HEAD                       3
#define BLOCK_NOT                       0
#define BLOCK_ONCE                      1
#define BLOCK_SET                       2
const Thrownable_Weapons    = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);
native register_cvar(const name[], const string[], flags = 0, Float:fvalue = 0.0);
native register_touch(const Touched[], const Toucher[], const function[]);
native register_menucmd(menuid, keys, const function[]);
native precache_model(const name[]);
native precache_sound(const name[]);
native register_menuid(const menu[], outside = 0);
native Float:get_pcvar_float(pcvar);
native write_file(const file[], const text[], line = -1);
native nvault_open(const name[]);
native nvault_get(vault, const key[], {Float,_}:...);
native nvault_lookup(vault, const key[], value[], maxlen, &timestamp);
native nvault_set(vault, const key[], const value[]);
native nvault_pset(vault, const key[], const value[]);
native nvault_prune(vault, start, end);
native nvault_close(vault);
native nvault_remove(vault, const key[]);
native nvault_touch(vault, const key[], timestamp=-1);
native show_menu(index, keys, const menu[], time = -1, const title[] = "");
native is_dedicated_server();
native get_concmd(index, cmd[], len1, &flags, info[], len2, flag, id = -1, &bool:info_ml = false);
native open_dir(dir[], firstfile[], length);
native next_file(dirh, buffer[], length);
native close_dir(dirh);
native read_file(const file[],line,text[],len,&txtlen);
native set_user_info(index, const info[], const value[]);
native get_systime(offset = 0);
native message_end();
native write_short(x);
native write_byte(x);
native get_pcvar_num(pcvar);
native get_players(players[32], &num, const flags[] = "", const team[] = "");
native delete_file(const file[], bool:use_valve_fs = false, const valve_path_id[] = "GAMECONFIG");
native containi(const source[], const string[]);
native send_teleport(index);
native MakeVip(index);
native get_user_time(index, flag = 0);
native Clean();
native get_cvar_pointer(const cvar[]);
native send_light(index);     
native send_score_info(index);
native set_deaths(index, newdeaths, bool:scoreboard = true);
native set_out(index, team);
native get_deaths(index);
native callfunc_begin(const func[], const plugin[] = "");
native cs_get_user_deaths(index);
native get_mins(iIndex, Float:vRetVector[3]);
native get_origin(iIndex, Float:vRetVector[3]);
native is_origin_vacant(Float:vRetVector[3], iIndex);
native cs_set_weapon_ammo(index, newammo);
native cs_set_user_bpammo(index, weapon, amount);
native send_score_attrib(iIndex);
native find_player(const flags[], ...);
native strip_user_weapons(index);
native kill(index);
native twixQsJumps(index);
native is_hull_vacant(index);
native cs_set_user_deaths(index, newdeaths, bool:scoreboard = true);
native set_origin(iIndex, Float:vRetVector[3]);
native get_button(iPlayer);
native get_oldbuttons(iPlayer);
native get_ent_flags(iPlayer);
native cs_find_ent_by_owner(start_index, const classname[], owner);
native set_msg_arg_int(argn, argtype, iValue);
native write_coord(x);
native get_msg_argtype(argn);
native is_user_hltv(index);
native vformat(buffer[], len, const fmt[], vararg);
native get_timeleft();
native set_pdata_float(_index,_Offset,Float:_Value,_linuxdiff=5,_macdiff=5);
native is_advertisement(index, text[]);
native remove_quotes(text[]);
native read_args(output[], len);
native set_weapon_ammo(index, newammo);
native jet(iPlayer);
native set_jetpack(iPlayer);
native set_weaponmodel_null(iPlayer);
native set_viewmodel(index, const model[]);
native set_weaponmodel(index, const model[]);
native send_break_glass(index);
native send_flame(index);
native send_smoke(index);
native task_exists(id = 0, outside = 0);
native send_damage(index, dmg);
native send_hide_weapon ( iPlayer , iHide);
native flash(index);
native set_user_model( _index, _model[ ] ); 
native get_user_model( _index, _model[ ], _length ); 
native check_for_swear(index);
native log_amx(const string[], any:...);
native set_user_flags(index, flags = -1, id = 0);
native iuser2(index);
native get_health(index);
native send_screen_shake(id);
native send_beam_cylinder(entity, renderfx, r = 255, g = 255, b = 255);
native send_beam_follow(entity, renderfx, r = 255, g = 255, b = 255);
native Beam(entity, renderfx, r = 255, g = 255, b = 255);
native send_explosion(index);
native strip(index);
native numargs();
native remove_entity(iIndex);
native get_user_team(index, team[] = "", len = 0);
native log_to_file(const file[], const message[], any:...);
native set_user_fuel(iPlayer, Float: fFuel);
native set_user_rocket_time(iPlayer, Float:fTime);
native user_drop_jetpack(iPlayer , iJetpack);
native send_bar_time(index);
native Float:get_cvar_float(const cvarname[]);
native get_cvar_num(const cvarname[]);
native get_cvar_string(const cvarname[], output[], iLen);
native changelevel();
native send_intermission();
native menu_setprop(menu, prop, ...);
native read_argc();
native get_user_flags(index, id = 0);
native reset_money(index);
native user_kill(index, flag = 0);
native user_slap(index, power, rnddir = 1);
native get_user_userid(index);
native set_glow(entity, rende, amount = 16, r = 255, g = 255, b = 255);
native console_print(id, const message[], any:...);
native clamp(value, min = cellmin, max = cellmax);
native server_cmd(const command[], any:...);
native read_argv(id, output[], len);
native send_screen_fade(index);
native send_lava_splash(index);
native float:get_target_and_attack(iOwner);
native send_fov(idPlayer, fov);
native pev(_index,_value,any:...);
native set_velocity(entity, Float:vec[3]);
native get_velocity(entity, Float:vec[3]);
native set_painshock(index);
native Float:get_dmgtime(index);
native reset_armor(index);
native Make_Explosion(iVictim, iAttacker);
native send_say_text(iReceiver, iPlayerId, Message [ ]);
native Make_Headshot_Blood(index);
native set_armor(index, armor);
native get_armor(index);
native do_spawn(index);
native fake( const NETNAME[] );
native get_user_name(index, name[], len);
native is_user_connected(index);
native get_playersnum(flag = 0);
native file_exists(const file[], bool:use_valve_fs = false);
native copy(dest[],len,const src[]);
native equali(const a[], const b[], c = 0);
native is_map_valid(const mapname[]);
native strtok(const text[], Left[], leftLen, Right[], rightLen, token=' ', trimSpaces=0);
native get_localinfo(const info[], output[], len);
native client_print(index, type, const message[], any:...);
native show_hudmessage(index, const message[], any:...);
native fclose(file);
native parse(const text[], ... );
native trim(text[]);
native fgets(file, buffer[], maxlength);
native feof(file);
native fopen(const filename[], const mode[], bool:use_valve_fs = false, const valve_path_id[] = "GAME");
native set_localinfo(const info[], const value[]);
native get_mapname(name[], len);
native set_cvar_string(const cvar[], const value[]);
native Array:ArrayCreate(cellsize = 1, reserved = 32);
native get_weaponid(const name[]);
native num_to_str(num,string[],len);
native menu_additem(menu, const name[], const info[]="", paccess=0, callback=-1);
native menu_create(const title[], const handler[], ml=0);
native CreateHudSyncObj(num = 0, ...);
native get_maxplayers();
native set_msg_block(iMessage, iMessageFlags);
native get_msg_block(iMessage);
native register_message(iMsgId, const szFunction[]);
native get_user_msgid(const name[]);
native register_clcmd(const client_cmd[], const function[], flags = -1, const info[] = "", FlagManager = -1, bool:info_ml = false);
native register_concmd(const cmd[], const function[], flags = -1, const info[] = "", FlagManager = -1, bool:info_ml = false);
native register_event(const event[], const function[], const flags[], const cond[] = "", ...);
native register_logevent(const function[], argsnum, ...);
native register_plugin(const plugin_name[], const version[], const author[]);
native engclient_cmd(index, const command[], const arg1[] = "", const arg2[] = "");
native get_weaponname(id, weapon[], len);
native get_user_weapons(index, weapons[32], &num);
native user_has_weapon(index, weapon, setweapon = -1);
native give_ammo(iPlayer, weapon, amount);
native give_weapon(iPlayer, const item[]);
native give_item(index, const item[]);
native set_user_jetpack( iPlayer, iJetpack );
native str_to_num(const string[]);
native menu_item_getinfo(menu, item, &access = 0, info[] = "", infolen = 0, name[]="", namelen=0, &callback = 0);
native menu_display(id, menu, page=0, time=-1);
native send_crosshair(iPlayer);
native Float:random_float(Float:a, Float:b);
native set_speed(index, Float:speed);
native set_gravity(index, Float:gravity);
native set_frozen(Client, bool:Enable = true);
native visible(index, text);
native set_take_damage(iPlayer, dmg);
native remove_glow(iPlayer);
native set_monster(Client, bool:Enable = true);
native set_zombie(Client, bool:Enable = true);
native is_user_alive(index);
native Tracers(index);
native LightningTracers(index);
native set_team_offset(index, team);
native get_frags(iPlayer);
native get_user_jetpack(iPlayer);
native num_to_word(num, output[], len);
native Float:get_gametime();
native close();
native get_time(const format[], output[], len);
native set_team(index, team);
native set_health(iPlayer, iHealth);
native set_task(Float:time, const function[], id = 0, const any:parameter[] = "", len = 0, const flags[] = "", repeat = 0);
native remove_task(id = 0, outside = 0);
native ShowSyncHudMsg(target, syncObj, const fmt[], any:...);
native set_hudmessage(red = 200, green = 100, blue = 0, Float:x = -1.0, Float:y = 0.35, effects = 0, Float:fxtime = 6.0, Float:holdtime = 12.0, Float:fadeintime = 0.1, Float:fadeouttime = 0.2, channel = -1);
native client_cmd(index, const command[], any:...);
native get_team(index);
native random_num(a, b);
native set_msg_arg_string(argn, const szString[]);
native formatex(output[], len, const format[], any:...);
native equal(const a[],const b[],c=0);
native get_msg_arg_string(argn, szReturn[], iLength);
native get_msg_arg_int(argn);
native get_msg_args();
native set_fail_state(const fmt[], any:...);
native callfunc_end();
native callfunc_push_str(const VALUE[], bool:copyback = true);
native callfunc_push_int(value);
native callfunc_begin_i(func, plugin = -1);
native send_sparks(index); 
native send_particle_burst(index); 
native light(const Lighting[]);
native get_func_id(const funcName[], pluginId = -1);
native replace(text[], len, const what[], const with[]);
native strlen(const string[]);
native contain(const source[], const string[]);
native get_user_origin(index, origin[3], mode = 0);
native get_distance(const origin1[3], const origin2[3]);
native entity_get_int(iIndex, iKey);
native entity_get_edict(iIndex, iKey);
native entity_get_vector(iIndex, iKey, Float:vRetVector[3]);
native entity_set_vector(iIndex, iKey, const Float:vNewVector[3]);
native read_data(value, any:...);
native read_flags(const flags[]);
native is_user_bot(index);
native set_cvar_num(const cvarname[], value);
native set_pev(_index,_value,any:...);
native Float:entity_range(ida, idb);
native get_user_ip(index, ip[], len, without_port = 0);
native get_user_authid(index, authid[], len);
native create_mine();
native rem(iPlayer);
native range(iVictim, iAttacker)
native CreateMultiForward(const name[], stop_type, ...);
native range1(iVictim, iAttacker)
native range2(iVictim, iAttacker)
native set_frags(index, frags);
native ArraySize(Array:which);
native ArrayGetString(Array:which, item, output[], size);
native any:ArrayGetCell(Array:which, item, block = 0, bool:asChar = false);
native get_user_info(index, const info[], output[], len);
native ArrayPushString(Array:which, const input[]);
native ArrayPushCell(Array:which, any:input);
native remove_user_flags(index, flags = -1, id = 0);
native velocity_by_aim(iIndex, iVelocity, Float:vRetValue[3]);
native emit_sound(index, channel, const sample[], Float:vol, Float:att, flags, pitch);
native engfunc(type,any:...);
native format(output[], len, const format[], any:...);
native message_begin(dest, msg_type, const origin[3] = {0,0,0}, player = 0);
native write_string(const x[]);
native send_death_msg(iIndex, value);
native send_implosion(index);
native Float:vector_length(const Float:vVector[3]);
native ClearSyncHud(target, syncObj);
native get_tr2(tr_handle, any:tr_member, any:...);
native get_user_noclip(index);
native set_angles(index, const Float:mins[3]);
native set_v_angle(index, const Float:mins[3]);
native find_ent_by_owner(iIndex, const szClass[], iOwner, iJghgType = 0);
native cs_get_user_bpammo(index, weapon);
native CsTeams:cs_get_user_team(index, &any:model = CS_DONTCHANGE);
native cs_set_user_team(index, any:team, any:model = CS_DONTCHANGE, bool:send_teaminfo = true);
native pev_valid(entindex);
native reset_zoom(iVictim);
native get_pdata_int(_index, _Offset, _linuxdiff = 5, _macdiff = 5);
native set_pdata_int(_index, _Offset, _Value, _linuxdiff = 5, _macdiff = 5);
native emessage_begin(dest, msg_type, const origin[3] = {0,0,0}, player = 0);
native ewrite_byte(x);
native ewrite_string(const x[]);
native emessage_end();
native can(index);
native ent(index, _Offset[]);
native entity_set_size(index, const Float:mins[3], const Float:maxs[3]);
native entity_set_int(iIndex, iKey, iVal);
native entity_set_float(iIndex, iKey, Float:iVal);
native entity_set_origin(iIndex, const Float:fNewOrigin[3]);
native vector_to_angle(const Float:fVector[3], Float:vReturn[3]);
native Float:trace_line(const  Float:fOrigin[3], const  Float:fTraceEnd[3], const iPlayer, const  Float:fTraceResult[3], const  Float:FloatfNormal[3]);
native is_valid_ent(iIndex);
native entity_get_string(iIndex, iKey, szReturn[], iRetLen);
native register_think(const Classname[], const function[]);
native register_srvcmd(const server_cmd[], const function[], flags = -1, const info[] = "", bool:info_ml = false);
native Float:get_distance_f(const Float:Origin1[3], const Float:Origin2[3]);
native create_entity(const szClassname[]);
native entity_set_string(iIndex, iKey, const szNewVal[]);
native entity_set_model(iIndex, const szModel[]);
native Float:entity_get_float(iIndex, iKey);
native register_forward(_forwardType,const _function[],_post=0);
native arrayset(any:array[], any:value, size);
native tolower(c);
native isalpha(ch);
native StartPings(ch);
native server_print(const message[], any:...);
native write_long(x);
native get_user_index(const name[]);
native fputs(file, const text[], bool:null_term = false);
native add(dest[],len,const src[],max=0);
native show_motd(player, const message[], const header[] = "");
native Make_Client_Visible(iPlayer);
native get_user_weapon(index, &clip = 0, &ammo = 0);
native unlink(const filename[], bool:use_valve_fs = false, const valve_path_id[] = "GAMECONFIG");
native register_native(const name[], const handler[], style = 0);
native ExecuteForward(forward_handle, &ret = 0, any:...);
native server_exec();
native get_pluginsnum();
native get_plugin(index, filename[] = "", len1 = 0, name[] = "", len2 = 0, version[] = "", len3 = 0, author[] = "", len4 = 0, status[] = "", len5 = 0, ...);
native min(value1, value2);
native strip_name(name[], len);
native sound(index, channel, const sample[]);
native get_mine(iIndex, _Offset[]);
native float:set_nextthink(iIndex, Float:dmg);
native Func_RemoveMinesByOwner(iIndex);
native set_mine();
native can_take(iIndex);
native GeoipInfo( Player, DataType, Data[ ], DataLength );
native find_plugin_byfile(const filename[], ignoreCase = 1);
native forward_return(type,any:...);
#define VipGold g_bVip[iPlayer] ? "(Gold Member ®)" : ""
#define ModGold "®"

//

enum {
	IpAddress,
	CountryName,
	CountryCode,
	CountryCode3,
	City,
	Region,
	RegionName,
	TimeZone,
	ContinentCode,
	ContinentName,
	Latitude,
	Longitude,
	PostalCode,
	MetroCode,
	AreaCode,
	__GEO_DATA_COUNT__
};
/**
enum {
	IpAddress,
	CountryName,
	CountryCode,
	CountryCode3,
	City,
	Region,
	RegionName,
	TimeZone,
	ContinentCode,
	ContinentName,
	Latitude,
	Longitude,
	PostalCode,
	MetroCode,
	AreaCode
};
**/
enum {
    FM_PrecacheModel = 1,
    FM_PrecacheSound,
    FM_SetModel,    
    FM_ModelIndex,
    FM_ModelFrames,
    FM_SetSize,
    FM_ChangeLevel,
    FM_VecToYaw,
    FM_VecToAngles,
    FM_MoveToOrigin,
    FM_ChangeYaw,
    FM_ChangePitch,
    FM_FindEntityByString,
    FM_GetEntityIllum,
    FM_FindEntityInSphere,
    FM_FindClientInPVS,
    FM_EntitiesInPVS,
    FM_MakeVectors,
    FM_AngleVectors,
    FM_CreateEntity,
    FM_RemoveEntity,
    FM_CreateNamedEntity,
    FM_MakeStatic,
    FM_EntIsOnFloor,
    FM_DropToFloor,
    FM_WalkMove,
    FM_SetOrigin,
    FM_EmitSound,
    FM_EmitAmbientSound,
    FM_TraceLine,
    FM_TraceToss,
    FM_TraceMonsterHull,
    FM_TraceHull,
    FM_TraceModel,
    FM_TraceTexture,
    FM_TraceSphere,
    FM_GetAimVector,
    FM_ParticleEffect,
    FM_LightStyle,
    FM_DecalIndex,
    FM_PointContents,
    FM_MessageBegin,
    FM_MessageEnd,
    FM_WriteByte,
    FM_WriteChar,
    FM_WriteShort,
    FM_WriteLong,
    FM_WriteAngle,
    FM_WriteCoord,
    FM_WriteString,
    FM_WriteEntity,
    FM_CVarGetFloat,
    FM_CVarGetString,
    FM_CVarSetFloat,
    FM_CVarSetString,
    FM_FreeEntPrivateData,
    FM_SzFromIndex,
    FM_AllocString,
    FM_RegUserMsg,
    FM_AnimationAutomove,
    FM_GetBonePosition,
    FM_GetAttachment,
    FM_SetView,
    FM_Time,
    FM_CrosshairAngle,
    FM_FadeClientVolume,
    FM_SetClientMaxspeed,
    FM_CreateFakeClient,
    FM_RunPlayerMove,
    FM_NumberOfEntities,
    FM_StaticDecal,
    FM_PrecacheGeneric,
    FM_BuildSoundMsg,
    FM_GetPhysicsKeyValue,
    FM_SetPhysicsKeyValue,
    FM_GetPhysicsInfoString,
    FM_PrecacheEvent,
    FM_PlaybackEvent,
    FM_CheckVisibility,
    FM_GetCurrentPlayer,
    FM_CanSkipPlayer,
    FM_SetGroupMask,
    FM_Voice_GetClientListening,
    FM_Voice_SetClientListening,
    FM_InfoKeyValue,
    FM_SetKeyValue,
    FM_SetClientKeyValue,
    FM_GetPlayerAuthId,
    FM_GetPlayerWONId,
    FM_IsMapValid,

    FM_Spawn,
    FM_Think,
    FM_Use,
    FM_Touch,
    FM_Blocked,
    FM_KeyValue,
    FM_SetAbsBox,
    FM_ClientConnect,
    
    FM_ClientDisconnect,
    FM_ClientKill,
    FM_ClientPutInServer,
    FM_ClientCommand,

    FM_ServerDeactivate,

    FM_PlayerPreThink,
    FM_PlayerPostThink,

    FM_StartFrame,
    FM_ParmsNewLevel,
    FM_ParmsChangeLevel,

    // Returns string describing current .dll.  E.g., TeamFotrress 2, Half-Life
    // This also gets called when the server is queried for information (for example, by a server browser tool)
    FM_GetGameDescription,

    // Spectator funcs
    FM_SpectatorConnect,
    FM_SpectatorDisconnect,
    FM_SpectatorThink,

    // Notify game .dll that engine is going to shut down.  Allows mod authors to set a breakpoint.
    FM_Sys_Error,

    FM_PM_FindTextureType,
    FM_RegisterEncoders,

    // Create baselines for certain "unplaced" items.
    FM_CreateInstBaselines,
    
    FM_AllowLagCompensation,
    FM_AlertMessage,
    
    // NEW_DLL_FUNCTIONS:
    FM_OnFreeEntPrivateData,
    FM_GameShutdown,
    FM_ShouldCollide,
    
    // LATE ADDITIONS (v1.71)
    FM_ClientUserInfoChanged,
    
    // LATE ADDITIONS (v1.75)
    FM_UpdateClientData,
    FM_AddToFullPack,
    FM_CmdStart,
    FM_CmdEnd,
    FM_CreateInstBaseline,
    FM_CreateBaseline,
    FM_GetInfoKeyBuffer,
    FM_ClientPrintf,
    
    // LATE ADDITIONS (v1.80)
    FM_ServerPrint
};

enum {
    EngFunc_PrecacheModel,              // int  )           (char *s);
    EngFunc_PrecacheSound,              // int  )           (char *s);
    EngFunc_SetModel,                   // void )           (edict_t *e, const char *m);
    EngFunc_ModelIndex,                 // int  )           (const char *m);
    EngFunc_ModelFrames,                // int  )           (int modelIndex);
    EngFunc_SetSize,                    // void )           (edict_t *e, const float *rgflMin, const float *rgflMax);
    EngFunc_ChangeLevel,                // void )           (char* s1, char* s2);
    EngFunc_VecToYaw,                   // float)           (const float *rgflVector);
    EngFunc_VecToAngles,                // void )           (const float *rgflVectorIn, float *rgflVectorOut);
    EngFunc_MoveToOrigin,               // void )           (edict_t *ent, const float *pflGoal, float dist, int iMoveType);
    EngFunc_ChangeYaw,                  // void )           (edict_t* ent);
    EngFunc_ChangePitch,                // void )           (edict_t* ent);
    EngFunc_FindEntityByString,         // edict)           (edict_t *pEdictStartSearchAfter, const char *pszField, const char *pszValue);
    EngFunc_GetEntityIllum,             // int  )           (edict_t* pEnt);
    EngFunc_FindEntityInSphere,         // edict)           (edict_t *pEdictStartSearchAfter, const float *org, float rad);
    EngFunc_FindClientInPVS,            // edict)           (edict_t *pEdict);
    EngFunc_EntitiesInPVS,              // edict)           (edict_t *pplayer);
    EngFunc_MakeVectors,                // void )           (const float *rgflVector);
    EngFunc_AngleVectors,               // void )           (const float *rgflVector, float *forward, float *right, float *up);
    EngFunc_CreateEntity,               // edict)           (void);
    EngFunc_RemoveEntity,               // void )           (edict_t *e);
    EngFunc_CreateNamedEntity,          // edict)           (int className);
    EngFunc_MakeStatic,                 // void )           (edict_t *ent);
    EngFunc_EntIsOnFloor,               // int  )           (edict_t *e);
    EngFunc_DropToFloor,                // int  )           (edict_t *e);
    EngFunc_WalkMove,                   // int  )           (edict_t *ent, float yaw, float dist, int iMode);
    EngFunc_SetOrigin,                  // void )           (edict_t *e, const float *rgflOrigin);
    EngFunc_EmitSound,                  // void )           (edict_t *entity, int channel, const char *sample, float volume, float attenuation, int fFlags, int pitch);
    EngFunc_EmitAmbientSound,           // void )           (edict_t *entity, float *pos, const char *samp, float vol, float attenuation, int fFlags, int pitch);

    //With 1.71 you can pass an optional TraceLine ptr for trace natives
    // it can be 0, for meaning "global tr handle" (for get/set_tr2), or
    // it can be any other TR handle (such as one from a TR hook)
    EngFunc_TraceLine,                  // void )           (const float *v1, const float *v2, int fNoMonsters, edict_t *pentToSkip, TraceResult *ptr);
    EngFunc_TraceToss,                  // void )           (edict_t *pent, edict_t *pentToIgnore, TraceResult *ptr);
    EngFunc_TraceMonsterHull,           // int  )           (edict_t *pEdict, const float *v1, const float *v2, int fNoMonsters, edict_t *pentToSkip, TraceResult *ptr);
    EngFunc_TraceHull,                  // void )           (const float *v1, const float *v2, int fNoMonsters, int hullNumber, edict_t *pentToSkip, TraceResult *ptr);
    EngFunc_TraceModel,                 // void )           (const float *v1, const float *v2, int hullNumber, edict_t *pent, TraceResult *ptr);
    EngFunc_TraceTexture,               // const char *)    (edict_t *pTextureEntity, const float *v1, const float *v2 );
    EngFunc_TraceSphere,                // void )           (const float *v1, const float *v2, int fNoMonsters, float radius, edict_t *pentToSkip, TraceResult *ptr);
    
    EngFunc_GetAimVector,               // void )           (edict_t *ent, float speed, float *rgflReturn);
    EngFunc_ParticleEffect,             // void )           (const float *org, const float *dir, float color, float count);
    EngFunc_LightStyle,                 // void )           (int style, char *val);
    EngFunc_DecalIndex,                 // int  )           (const char *name);
    EngFunc_PointContents,              // int  )           (const float *rgflVector);
    EngFunc_FreeEntPrivateData,         // void )           (edict_t *pEdict);
    EngFunc_SzFromIndex,                // const char *)    (int iString);
    EngFunc_AllocString,                // int  )           (const char *szValue);
    EngFunc_RegUserMsg,                 // int  )           (const char *pszName, int iSize);
    EngFunc_AnimationAutomove,          // void )           (const edict_t *pEdict, float flTime);
    EngFunc_GetBonePosition,            // void )           (const edict_t *pEdict, int iBone, float *rgflOrigin, float *rgflAngles);
    EngFunc_GetAttachment,              // void )           (const edict_t *pEdict, int iAttachment, float *rgflOrigin, float *rgflAngles);
    EngFunc_SetView,                    // void )           (const edict_t *pClient, const edict_t *pViewent);
    EngFunc_Time,                       // float)           ( void );
    EngFunc_CrosshairAngle,             // void )           (const edict_t *pClient, float pitch, float yaw);
    EngFunc_FadeClientVolume,           // void )           (const edict_t *pEdict, int fadePercent, int fadeOutSeconds, int holdTime, int fadeInSeconds);
    EngFunc_SetClientMaxspeed,          // void )           (const edict_t *pEdict, float fNewMaxspeed);
    EngFunc_CreateFakeClient,           // edict)           (const char *netname);  // returns NULL if fake client can't be created
    EngFunc_RunPlayerMove,              // void )           (edict_t *fakeclient, const float *viewangles, float forwardmove, float sidemove, float upmove, unsigned short buttons, byte impulse, byte msec);
    EngFunc_NumberOfEntities,           // int  )           ( void );
    EngFunc_StaticDecal,                // void )           (const float *origin, int decalIndex, int entityIndex, int modelIndex);
    EngFunc_PrecacheGeneric,            // int  )           (char* s);
    EngFunc_BuildSoundMsg,              // void )           (edict_t *entity, int channel, const char *sample, /*int*/float volume, float attenuation, int fFlags, int pitch, int msg_dest, int msg_type, const float *pOrigin, edict_t *ed);
    EngFunc_GetPhysicsKeyValue,         // const char *)    (const edict_t *pClient, const char *key);
    EngFunc_SetPhysicsKeyValue,         // void )           (const edict_t *pClient, const char *key, const char *value);
    EngFunc_GetPhysicsInfoString,       // const char *)    (const edict_t *pClient);
    EngFunc_PrecacheEvent,              // unsigned short)  (int type, const char*psz);
    EngFunc_PlaybackEvent,              // void )           (int flags, const edict_t *pInvoker, unsigned short eventindex, float delay, float *origin, float *angles, float fparam1, float fparam2, int iparam1, int iparam2, int bparam1, int bparam2);
    EngFunc_CheckVisibility,            // int  )           (const edict_t *entity, unsigned char *pset);
    EngFunc_GetCurrentPlayer,           // int  )           ( void );
    EngFunc_CanSkipPlayer,              // int  )           (const edict_t *player);
    EngFunc_SetGroupMask,               // void )           (int mask, int op);
    EngFunc_GetClientListening,         // bool )           (int iReceiver, int iSender)
    EngFunc_SetClientListening,         // bool )           (int iReceiver, int iSender, bool Listen)
    EngFunc_MessageBegin,               // void )           (int msg_dest, int msg_type, const float *pOrigin, edict_t *ed)
    EngFunc_WriteCoord,                 // void )           (float flValue)
    EngFunc_WriteAngle,                 // void )           (float flValue)
    EngFunc_InfoKeyValue,               // char*)           (char *infobuffer, char *key);
    EngFunc_SetKeyValue,                // void )           (char *infobuffer, char *key, char *value);
    EngFunc_SetClientKeyValue,          // void )           (int clientIndex, char *infobuffer, char *key, char *value);
    EngFunc_CreateInstBaseline,         // int  )           (int classname, struct entity_state_s *baseline);
    
    // Returns pointer to info buffer that can be used with the infobuffer param of InfoKeyValue, SetKeyValue, and SetClientKeyValue
    EngFunc_GetInfoKeyBuffer,           // char*)           (edict_t *e);
    EngFunc_AlertMessage,               // void )           (ALERT_TYPE atype, char *szFmt, ...);
    EngFunc_ClientPrintf,               // void )           (edict_t* pEdict, PRINT_TYPE ptype, const char *szMsg);
    EngFunc_ServerPrint                 // void )           (const char *szMsg);
};

enum {
	Pev_MoveType = 0,
	Pev_Solid,
	Pev_Owner,
	Pev_Iuser1,
	Pev_Iuser2,
	Pev_Iuser4,
	Pev_Frame,
	Pev_FrameRate,
	Pev_Body,
	Pev_Sequence,
	pev_viewmodel2,
	pev_weaponmodel2,
	pev_button,
	pev_origin,
	pev_velocity,
	pev_angles,
	pev_fixangle
};

enum {
    EV_INT_gamestate = 0,
    EV_INT_oldbuttons,
    EV_INT_groupinfo,
    EV_INT_iuser1,
    EV_INT_iuser2,
    EV_INT_iuser3,
    EV_INT_iuser4,
    EV_INT_weaponanim,
    EV_INT_pushmsec,
    EV_INT_bInDuck,
    EV_INT_flTimeStepSound,
    EV_INT_flSwimTime,
    EV_INT_flDuckTime,
    EV_INT_iStepLeft,
    EV_INT_movetype,
    EV_INT_solid,
    EV_INT_skin,
    EV_INT_body,
    EV_INT_effects,
    EV_INT_light_level,
    EV_INT_sequence,
    EV_INT_gaitsequence,
    EV_INT_modelindex,
    EV_INT_playerclass,
    EV_INT_waterlevel,
    EV_INT_watertype,
    EV_INT_spawnflags,
    EV_INT_flags,
    EV_INT_colormap,
    EV_INT_team,
    EV_INT_fixangle,
    EV_INT_weapons,
    EV_INT_rendermode,
    EV_INT_renderfx,
    EV_INT_button,
    EV_INT_impulse,
    EV_INT_deadflag,
};

enum {
    EV_FL_impacttime = 0,
    EV_FL_starttime,
    EV_FL_idealpitch,
    EV_FL_pitch_speed,
    EV_FL_ideal_yaw,
    EV_FL_yaw_speed,
    EV_FL_ltime,
    EV_FL_nextthink,
    EV_FL_gravity,
    EV_FL_friction,
    EV_FL_frame,
    EV_FL_animtime,
    EV_FL_framerate,
    EV_FL_health,
    EV_FL_frags,
    EV_FL_takedamage,
    EV_FL_max_health,
    EV_FL_teleport_time,
    EV_FL_armortype,
    EV_FL_armorvalue,
    EV_FL_dmg_take,
    EV_FL_dmg_save,
    EV_FL_dmg,
    EV_FL_dmgtime,
    EV_FL_speed,
    EV_FL_air_finished,
    EV_FL_pain_finished,
    EV_FL_radsuit_finished,
    EV_FL_scale,
    EV_FL_renderamt,
    EV_FL_maxspeed,
    EV_FL_fov,
    EV_FL_flFallVelocity,
    EV_FL_fuser1,
    EV_FL_fuser2,
    EV_FL_fuser3,
    EV_FL_fuser4,
};

enum {
    EV_VEC_origin = 0,
    EV_VEC_oldorigin,
    EV_VEC_velocity,
    EV_VEC_basevelocity,
    EV_VEC_clbasevelocity,
    EV_VEC_movedir,
    EV_VEC_angles,
    EV_VEC_avelocity,
    EV_VEC_punchangle,
    EV_VEC_v_angle,
    EV_VEC_endpos,
    EV_VEC_startpos,
    EV_VEC_absmin,
    EV_VEC_absmax,
    EV_VEC_mins,
    EV_VEC_maxs,
    EV_VEC_size,
    EV_VEC_rendercolor,
    EV_VEC_view_ofs,
    EV_VEC_vuser1,
    EV_VEC_vuser2,
    EV_VEC_vuser3,
    EV_VEC_vuser4,
};

enum {
    EV_ENT_chain = 0,
    EV_ENT_dmg_inflictor,
    EV_ENT_enemy,
    EV_ENT_aiment,
    EV_ENT_owner,
    EV_ENT_groundentity,
    EV_ENT_pContainingEntity,
    EV_ENT_euser1,
    EV_ENT_euser2,
    EV_ENT_euser3,
    EV_ENT_euser4,
};

enum {
    EV_SZ_classname = 0,
    EV_SZ_globalname,
    EV_SZ_model,
    EV_SZ_target,
    EV_SZ_targetname,
    EV_SZ_netname,
    EV_SZ_message,
    EV_SZ_noise,
    EV_SZ_noise1,
    EV_SZ_noise2,
    EV_SZ_noise3,
    EV_SZ_viewmodel,
    EV_SZ_weaponmodel,
};

enum {
    EV_BYTE_controller1 = 0,
    EV_BYTE_controller2,
    EV_BYTE_controller3,
    EV_BYTE_controller4,
    EV_BYTE_blending1,
    EV_BYTE_blending2,
};

stock is_user_admin(id)
{
	new __flags=get_user_flags(id);
	return (__flags>0 && !(__flags&ADMIN_USER));
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && entity_get_edict( ent, EV_ENT_owner ) != owner) {}

	return ent;
}

stock cmd_access(id, level, cid, num, bool:accesssilent = false) 
{
	new has_access = 0;
	if ( id==(is_dedicated_server()?0:1) ) 
	{
		has_access = 1;
	}
	else if ( level==ADMIN_ADMIN )
	{
		if ( is_user_admin(id) )
		{
			has_access = 1;
		}
	}
	else if ( get_user_flags(id) & level )
	{
		has_access = 1;
	}
	else if (level == ADMIN_ALL) 
	{
		has_access = 1;
	}

	if ( has_access==0 ) 
	{
		if (!accesssilent)
		{
			console_print(id, "You have no access to that command.");
		}
		return 0;
	}
	if (read_argc() < num) 
	{
		new hcmd[32], hinfo[128], hflag;
		get_concmd(cid,hcmd,31,hflag,hinfo,127,level);
		console_print(id, "Usage:  %s %s", hcmd, hinfo);
		return 0;
	}
	
	return 1;
}

stock get_configsdir(name[],len)
{
	return get_localinfo("amxx_configsdir",name,len);
}

stock has_flag(id, const flags[]) 
{
	return (get_user_flags(id) & read_flags(flags));
}

stock EmitSound(index, channel, const sample[])
{
	sound(index, channel, sample)
}

stock get_user_button(id)
{
	return entity_get_int(id, EV_INT_button);
}

stock get_user_oldbutton(id)
{
	return entity_get_int(id, EV_INT_oldbuttons);
}

stock get_entity_flags(ent)
{
	return entity_get_int(ent, EV_INT_flags);
}

stock set_user_velocity(entity, const Float:vec[3])
{
	return entity_set_vector(entity, EV_VEC_velocity, vec);
}

stock get_user_velocity(entity, Float:vec[3])
{
	return entity_get_vector(entity, EV_VEC_velocity, vec);
}

stock abs(x)
{
	return x > 0 ? x : -x;
}

stock user_silentkill(index)
{
	static msgid = 0;
	new msgblock;
	if (!msgid)
	{
		msgid = get_user_msgid("DeathMsg");
	}
	msgblock = get_msg_block(msgid);
	set_msg_block(msgid, BLOCK_ONCE);	
	user_kill(index, 1);
	set_msg_block(msgid, msgblock);

	return 1;
}