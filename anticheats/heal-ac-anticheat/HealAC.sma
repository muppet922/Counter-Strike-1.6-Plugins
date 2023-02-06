/*[0.3.5]*/
/*Оптимизирован код
 *Убран квар для переключения анти-спедхака
 *Добавлен квар для предотвращения баннихопа, вместо кика*/
/*[0.3.4]*/
/*Исправлена ошибка с анти-спедхаком*/ 
/*[0.3.3]*/ 
/*Добавлен анти-бхоп*/  
/*[0.3.2]*/                                        
/*Добавлен анти-фасткнайф*/  
/*[0.3.1]*/ 
/*Добавлен анти-спедхак*/ 
/*[0.3.0 Release]*/   
/*-Ошибки   
 *Добавлена защита от ESP и WH*/  

                     
#include <amxmodx>
#include <fakemeta>                                  
#include <hamsandwich>                        
#include <xs>                                                                
#include <fun>     
#include <engine>

#define INV_CACHE    v_checkevery    
#define VIS_CACHE    v_checkevery * 2 + 10
#define PRED_COEF    v_checkevery * 0.02 + 0.1

#define is_entity_in_pvs(%0,%1)    engfunc(EngFunc_CheckVisibility, %0, %1)
#define is_user_flashed(%0)        get_pdata_int(%0, 518) > 200 && get_gametime() < get_pdata_float(%0, 515) + get_pdata_float(%0, 516)

new alive[33], team[33], tr_handle, p_checkevery, p_ignoreteam, v_checkevery, v_ignoreteam
                                 
new Float:offset_y[][] =
{
    {-17.0, -8.5, -8.5,-17.0},
    { 17.0,  8.5,  8.5, 17.0}                         
}

new Float:offset_z[][] =
{
    {-34.0,-17.0, 17.0, 34.0},
    {-17.0, -8.5, 17.0, 34.0}
}                                            

static g_i_time[33]
static g_i_warnings[33]

static bool:g_i_status[33]

static const g_s_sound[][]=
{
    "slash1",
    "slash2",                             
    "hitwall1",
    "hit1",
    "hit2",
    "hit3",
    "hit4",          
    "stab"
}
  
 
#define add_bot_property(%1)                        gBS_cl_bot |= (1<<(%1 - 1))
#define del_bot_property(%1)                        gBS_cl_bot &= ~(1<<(%1 - 1))
#define has_bot_property(%1)                        (gBS_cl_bot & (1<<(%1 - 1)))
#define add_alive_property(%1)                        gBS_cl_alive |= (1<<(%1 - 1))
#define del_alive_property(%1)                        gBS_cl_alive &= ~(1<<(%1 - 1))
#define has_alive_property(%1)                        (gBS_cl_alive & (1<<(%1 - 1)))
#define add_announced(%1)                            gBS_cl_announce |= (1<<(%1 - 1))
#define del_announced(%1)                            gBS_cl_announce &= ~(1<<(%1 - 1))
#define has_been_announced(%1)                        (gBS_cl_announce & (1<<(%1 - 1)))

const gC_MaxIdle =  2500
const gC_MaxLimit = 130                     
const gC_MaxSlots = 32
                                                                           
new gBS_cl_alive, gBS_cl_bot, gBS_cl_announce

new gCLI_count[gC_MaxSlots + 1]
new gCLI_buttons[gC_MaxSlots + 1]                                                  
new gCLI_idlecount[gC_MaxSlots + 1] 
new Float:gCLF_lasttime[gC_MaxSlots + 1]
new Float:gCLV_views[gC_MaxSlots + 1][3]
new Float:gCLV_pviews[gC_MaxSlots + 1][3]  

new g_frames[33]                                 
new g_bhops[33]
new g_inair[33]

new block_jump = 0

public plugin_init() {

    register_plugin("HealAC", "0.3.5", "stalker4026"); 
                                    
    register_forward(FM_EmitSound,"sound_hook" )                                                     
    register_forward(FM_AddToFullPack, "fw_addtofullpack") 
    register_forward(FM_CmdStart, "pfw_CmdStart", 1)                                                                                      
                                                               
    RegisterHam(Ham_Spawn, "player", "pfw_PlayerHandleAD", 1)
    RegisterHam(Ham_Killed, "player", "pfw_PlayerHandleAD", 1) 
    RegisterHam(Ham_Spawn, "player", "fw_alivehandle", 1)
    RegisterHam(Ham_Killed, "player", "fw_alivehandle", 1)
                       
    p_checkevery = register_cvar("heal_wh_checkevery", "1")
    p_ignoreteam = register_cvar("heal_wh_ignoreteam", "1")  
    
    register_cvar("heal_bhop_prevent", "1");
    register_cvar("heal_bhop_limit", "3") 
    
    tr_handle = create_tr2()    
}     

public fw_addtofullpack(es, e, ent, id, flags, player, set)
{
    if(player && id != ent && alive[id] && alive[ent] && (v_ignoreteam ? team[id] != team[ent] : true) && !is_entity_visible(id, ent, set))
    {
        forward_return(FMV_CELL, 0)                                

        return FMRES_SUPERCEDE
    }                      
                                                         
    return FMRES_IGNORED
}

public fw_alivehandle(id)
{
    v_checkevery = clamp(get_pcvar_num(p_checkevery), 1, 10)
    v_ignoreteam = get_pcvar_num(p_ignoreteam)

    alive[id] = is_user_alive(id)
    team[id] = get_user_team(id)
}                                                                           

public is_entity_visible(id, entity, set)
{
    static Float:p_origin[3], Float:e_origin[3], Float:v_plane[3], Float:v_temp[3], calls[33][33], cache[33][33], duck, i, j

    if(++calls[id][entity] < (cache[id][entity] ? VIS_CACHE : INV_CACHE))
    {
        return cache[id][entity]
    }

    calls[id][entity] = 0

    if(!is_entity_in_pvs(entity, set) || is_user_flashed(id))
    {
        return cache[id][entity] = 0                                   
    }

    get_origin(id, p_origin, cache[id][entity])
    get_origin(entity, e_origin, cache[id][entity])

    xs_vec_sub(e_origin, p_origin, v_plane)
    xs_vec_normalize(v_plane, v_plane)

    pev(id, pev_v_angle, v_temp)
    angle_vector(v_temp, ANGLEVECTOR_FORWARD, v_temp)

    if(xs_vec_dot(v_plane, v_temp) < 0)
    {
        return cache[id][entity] = 0
    }

    pev(id, pev_view_ofs, v_temp)
    xs_vec_add(p_origin, v_temp, p_origin)

    pev(entity, pev_view_ofs, v_temp)
    xs_vec_add(e_origin, v_temp, v_temp)

    if(is_point_visible(p_origin, v_temp, id))
    {
        return cache[id][entity] = 1
    }

    vector_to_angle(v_plane, v_plane)
    angle_vector(v_plane, ANGLEVECTOR_RIGHT, v_plane)

    duck = !!(pev(entity, pev_button) & IN_DUCK)

    for(i = 0; i < 2; i++)
    {
        for(j = 0; j < 4; j++)
        {
            v_temp[0] = e_origin[0] + v_plane[0] * offset_y[i][j]
            v_temp[1] = e_origin[1] + v_plane[1] * offset_y[i][j]
            v_temp[2] = e_origin[2] + v_plane[2] * offset_y[i][j] + offset_z[duck][j]

            if(is_point_visible(p_origin, v_temp, id))
            {
                return cache[id][entity] = 1
            }
        }
    }

    return cache[id][entity] = 0
}

stock get_origin(id, Float:origin[3], visible)
{
    pev(id, pev_origin, origin)

    if(!visible)
    {
        static Float:velocity[3]

        pev(id, pev_velocity, velocity)

        if(velocity[0] || velocity[1] || velocity[2])
        {
            xs_vec_mul_scalar(velocity, PRED_COEF, velocity)
            xs_vec_add(origin, velocity, origin)
        }
    }
}

stock is_point_visible(Float:start[3], Float:point[3], ignore_ent)
{
    static Float:fraction

    engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, tr_handle)
    get_tr2(tr_handle, TR_flFraction, fraction)

    return fraction == 1.0
}     

public client_connect(id)
{
    g_i_time[id]=10
    g_i_warnings[id]=0
    
    g_i_status[id]=true
    
    set_task(0.1,"set_time",id,_,_,"b")
}

public client_putinserver(id)
{          
    del_announced(id)
    del_alive_property(id)
    
    if (is_user_bot(id)){
        add_bot_property(id)
    } else {
        del_bot_property(id)
    }
}                                                                    

public client_disconnected(id)
{ 
    if(task_exists(id))                                     
    {
        remove_task(id)
    }                        
    
    del_announced(id)
    del_alive_property(id)
    del_bot_property(id)
}        
     
public pfw_CmdStart(id, pUC, seed)  
{                                                          
    if (!has_alive_property(id) || has_bot_property(id))
        return FMRES_IGNORED
    
    new Float:fGameTime, iButtons          
    new Float:vView[3]            
    
    pev(id, pev_v_angle, vView)
    fGameTime = get_gametime()
    get_uc(pUC, UC_Buttons, iButtons)
    
    if (gCLI_count[id] > 0)
    {
        if (gCLI_buttons[id] == iButtons)
        {
            if (gCLV_pviews[id][0] == vView[0] && gCLV_pviews[id][1] == vView[1] && gCLV_pviews[id][2] == vView[2])
                gCLI_idlecount[id]++
            else
                gCLI_idlecount[id] = 0
            
            if (gCLI_idlecount[id] > gC_MaxIdle)
            {
                gCLV_views[id][0] == -8000.0
                gCLI_idlecount[id] = 0
            }
        }
        else
        {
            gCLI_idlecount[id] = 0
            gCLI_buttons[id] = iButtons
        }
        
        gCLV_pviews[id][0] = vView[0]
        gCLV_pviews[id][1] = vView[1]
        gCLV_pviews[id][2] = vView[2]
    }
    
    if (gCLI_count[id] < 0)
    {
        gCLI_idlecount[id] = 0
        gCLI_buttons[id] = iButtons
        gCLV_pviews[id][0] = vView[0]
        gCLV_pviews[id][1] = vView[1]
        gCLV_pviews[id][2] = vView[2]
    }
    
    if (gCLV_views[id][0] == -8000.0 && gCLI_count[id] != -9)
    {
        gCLI_count[id] = -9
        return FMRES_IGNORED
    }
    
    if (gCLI_count[id] < -2)
    {
        gCLI_buttons[id] =  iButtons;
        gCLV_views[id][0] = vView[0];
        gCLV_views[id][1] = vView[1];
        gCLV_views[id][2] = vView[2];
        gCLI_count[id]++;
        return FMRES_IGNORED;
    }
    
    if (gCLV_views[id][0] == vView[0] && gCLV_views[id][1] == vView[1] && gCLV_views[id][2] == vView[2])
    {
        gCLI_count[id] = -2
        return FMRES_IGNORED
    }
    
    if (fGameTime - gCLF_lasttime[id] > 1.0)                    
    {    
        if (gCLI_count[id] > gC_MaxLimit){
            ppunish(id, 0);               
        }
        
        if (gCLI_count[id] < 0){
            gCLI_count[id] ++
        } else {
            gCLI_count[id] = 0 
        }
        
        gCLF_lasttime[id] = fGameTime 
        
        return FMRES_IGNORED;
    }
                           
    if (gCLI_count[id] >= 0)                                                                              
    {
        gCLI_count[id]++;                       
    }
    
    return FMRES_IGNORED
}

public pfw_PlayerHandleAD(id)
{
    if (is_user_alive(id)){
    
        gCLF_lasttime[id] = get_gametime()
        gCLV_views[id][0] = -8000.0
        gCLI_idlecount[id] = 0
        
        add_alive_property(id)
        
    } else {          
        del_alive_property(id)
    }
    
    return HAM_IGNORED
}
                          
public set_time(id)
{
    g_i_time[id]++
}

public sound_hook(id,i_channel,s_sound[])
{
    if(is_user_bot(id)||is_user_hltv(id))
    {
        return PLUGIN_CONTINUE
    }
    
    if(id<1||id>32||g_i_status[id]==false)
    {                                                                
        return PLUGIN_CONTINUE
    }
    
    new s_buffer[64]
    
    for(new a;a<sizeof(g_s_sound);a++)
    {
        format(s_buffer,63,"weapons/knife_%s.wav",g_s_sound[a])
        
        if(equal(s_buffer,s_sound))
        {
            if(g_i_time[id]<3)
            {
                if(g_i_warnings[id]==3)
                {
                    ppunish(id, 1)
                    
                    g_i_status[id]=false
                    
                    return PLUGIN_CONTINUE
                }
                else
                {
                    g_i_warnings[id]++
                }
            }
            
            g_i_time[id]=0
            
            break
        }
    }
    
    return PLUGIN_CONTINUE
}                                                                                               
                               
public client_PreThink(id){
    if(block_jump == 1){
        client_cmd(id, ";-jump");
        block_jump = 0;
        if(entity_get_int(id,EV_INT_button) & IN_JUMP ) {    
            return HAM_SUPERCEDE
        }                
    }         

    if(!is_user_bot(id) && is_user_alive(id)){
        new button = entity_get_int(id, EV_INT_button)    
        new jump = (button & IN_JUMP)                                        
        new flags = entity_get_int(id, EV_INT_flags)
        new onground = flags & FL_ONGROUND
        
        if(get_speed(id)>floatround(get_user_maxspeed(id))){
            if(jump && onground && g_inair[id]){
                g_bhops[id]++
                g_inair[id] = false                                
            }         
            if(!onground)
                g_inair[id] = true
            if(jump && !onground)
                g_frames[id]++
            if(get_cvar_num("heal_bhop_prevent") == 0){
                if(g_bhops[id] >= get_cvar_num("heal_bhop_limit") && !g_frames[id])  
                    ppunish(id, 2);
            } else {                       
                if(g_bhops[id] >= 0 && !g_frames[id]){
                    block_jump = 1;           
                }
            }            
        }                                                                      
                                                 
        if(get_speed(id)<=floatround(get_user_maxspeed(id))){
            g_bhops[id] = 0
            g_frames[id] = 0
        }    
    }  
    
    return HAM_IGNORED;
}

public ppunish(id, type)
{                                    
    new iUserID = get_user_userid(id) 
    switch(type)                                                     
    {                                                          
        case 0:
            server_cmd("kick #%d  [HEALAC] Speed Hack detected!", iUserID)   
        case 1:                                                
            server_cmd("kick #%d  [HEALAC] Fast Knife detected!", iUserID)                 
        case 2:
            server_cmd("kick #%d  [HEALAC] Bunnyhop detected!", iUserID)   
    }                 
}         
     
public plugin_end()
{
    free_tr2(tr_handle)
}                     
