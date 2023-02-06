#include <amxmodx> 
#include <hamsandwich> 
#include <fakemeta_util> 
#include <biohazard> 
  
#define PLUGIN "[IceFireWaterWind] Elemental Zombie" 
#define VERSION "0.1 Unfinished" 
#define AUTHOR "TEST" 

#define D_ZOMBIE_NAME "Zombie Elemental [Slow/Burn/Imobilize/Telekinetic]" 
#define D_ZOMBIE_DESC "Can slow/burn/drown/control players press G" 
#define D_PLAYER_MODEL "ultimate_frostman" 
#define D_CLAWS "models/player/ultimate_frostman/ultimate_claws.mdl" 
#define PMODEL "models/player/ultimate_frostman/ultimate_frostman.mdl" 
       
new Jack 
        
#define FireShpere_Classname "ZP_Jack_FireShpere" 
#define FrostSphere_Classname "ZP_Jack_FrostSphere" 
  
#define CDHudChannel 4 
  

#define Shpere "models/w_flashbang.mdl" 
#define Trail "sprites/xenobeam.spr" 
#define Burn "sprites/xflare2.spr" 
#define ThrowFireShpereSound "FireBallMissileLaunch3.wav" 

const Float:FireShpereExplodeRadius = 140.0 
const Float:FireShpereExplodeDamage = 20.0 
const Float:FireShpere_CD=50.0 
  
const Float:FireShpere_BurnTime = 6.0 
const Float:BurnDamage = 3.0 
const Float:BurnUpdate = 0.5    //Damage == FireShpere_BurnTime/BurnUpdate*BurnDamage 
  
  
const Float:FrostSphereExplodeRadius = 170.0 
const Float:FrostSphereExplodeDamage = 25.0 
const Float:FrostSphere_CD=40.0 
const Float:FrostSphere_FreezeTime = 8.0 
  
  
new bool:Can_Use_Ability[32],Selected_Ability[32],Float:Ability_CD[32],Float:UpdateHud[32] 
new bool:in_frost[32],Float:FrostTime[32] 
new bool:in_burn[32],Float:BurnTime[32],BurnOwner[32],Float:BurnUpdateDamage[32] 
  
new Msg_ScreenShake,Msg_ScreenFade,TrailSpriteIndex,BurnSprite 
  
public plugin_precache() 
{ 
        precache_model(Shpere) 
        TrailSpriteIndex=precache_model(Trail) 
        BurnSprite=precache_model(Burn) 
        precache_sound(ThrowFireShpereSound) 
} 
public plugin_init() 
{ 
        register_plugin(PLUGIN, VERSION, AUTHOR) 
        register_logevent("round_end", 2, "1=Round_End"); 

        Msg_ScreenShake = get_user_msgid("ScreenShake") 
        Msg_ScreenFade = get_user_msgid("ScreenFade")   
         
        register_class_data() 
        
        //Ham 
        RegisterHam(Ham_Touch, "info_target", "Ham_Touch_Pre") 
        
        //CMD 
        register_clcmd("drop","use_ability")    //Becouse ZP block impulse 100 =| 
        // Add your code here... 
} 

public register_class_data() 
{ 
    Jack = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC) 

    if(Jack != -1) 
    { 
        set_class_data(Jack, DATA_HEALTH, 150.0) 
        set_class_data(Jack, DATA_SPEED, 300.0) 
        set_class_data(Jack, DATA_GRAVITY, 0.7) 
        set_class_data(Jack, DATA_HITREGENDLY, 5.0) 
        set_class_pmodel(Jack, D_PLAYER_MODEL) 
        set_class_wmodel(Jack, D_CLAWS) 
    } 
} 

//Cmd Drop 
public use_ability(id) 
{ 
        if(!is_user_connected(id))return 
        if(!is_user_alive(id))return 
         
        if(!is_user_zombie(id))return 
        if(get_user_class(id)!=Jack)return 
         
        if(!Can_Use_Ability[id-1])return 
        new Float: gametime = get_gametime() 
        switch(Selected_Ability[id-1]) 
        { 
                case 0:throw_Shpere(id,1),Ability_CD[id-1]=gametime+FireShpere_CD,Can_Use_Ability[id-1]=false 
                case 1:throw_Shpere(id,2),Ability_CD[id-1]=gametime+FrostSphere_CD,Can_Use_Ability[id-1]=false 
        }       
} 
//Ham 
public Ham_Touch_Pre(ent,world) 
{ 
        if(!pev_valid(ent))return HAM_IGNORED 
        
        new Classname[32] 
        pev(ent, pev_classname, Classname, sizeof(Classname)) 
        if(!equal(Classname, FireShpere_Classname)&&!equal(Classname, FrostSphere_Classname))return HAM_IGNORED 
        
        new Float:Origin[3],id = pev(ent,pev_owner) 
                                
        pev(ent,pev_origin,Origin) 
        new victim =-1,Float:Damage_Radius,Float:Damage,attacker 
        switch(pev(ent,pev_iuser1)) 
        { 
                case 1:Damage_Radius=FireShpereExplodeRadius,Damage=FireShpereExplodeDamage,Light(Origin,30,255,105,0,4),DrawRings(Origin,255,105,0) 
                case 2:Damage_Radius=FrostSphereExplodeRadius,Damage=FrostSphereExplodeDamage,Light(Origin,30,0,105,255,4),DrawRings(Origin,0,105,255) 
        } 
        
        
        while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, Damage_Radius)) != 0) 
        { 
                if(pev_valid(victim)&&pev(victim, pev_takedamage)!=DAMAGE_NO&&pev(victim, pev_solid)!=SOLID_NOT) 
                { 
                        if(is_user_connected(victim)) 
                        { 
                                if(get_user_team(victim)!=get_user_team(id)) 
                                 
                                if(!is_user_zombie(victim)) 
                                { 
                                        if(pev(victim,pev_armorvalue)<=0.0&&pev(victim,pev_health)<Damage)attacker=id;else attacker=0 
                                        switch(pev(ent,pev_iuser1)) 
                                        { 
                                                case 1: ExecuteHamB(Ham_TakeDamage,victim, ent,attacker, Damage, DMG_BURN),ScreenFade(victim,6,1,{255,125,0},125,1),fm_set_rendering(victim), 
                                                        BurnTime[victim-1]=get_gametime()+FireShpere_BurnTime,in_burn[victim-1]=true,in_frost[victim-1]=false,BurnOwner[victim-1]=id 
                                                case 2: ExecuteHamB(Ham_TakeDamage,victim, ent,attacker, Damage, DMG_FREEZE),ScreenFade(victim,6,1,{0,0,255},125,1), 
                                                        FrostTime[victim-1]=get_gametime()+FrostSphere_FreezeTime,in_frost[victim-1]=true,in_burn[victim-1]=false, 
                                                        fm_set_rendering(victim, kRenderFxGlowShell, 0,105,255, kRenderNormal,15) 
                                        } 
                                        ScreenShake(victim, ((1<<12) * 3), ((2<<12) * 3)) 
                                } 
                        } 
                        else ExecuteHamB(Ham_TakeDamage,victim, ent,id, Damage, DMG_BLAST)      //take damage entity 
                } 
        } 
        if(pev_valid(ent))engfunc(EngFunc_RemoveEntity, ent)    //Remove sphere after blast! 
        return HAM_HANDLED 
} 
                        
public event_infect(id) 
{ 
    if(get_user_class(id)!=Jack) 
    { 
        Can_Use_Ability[id-1]=true 
    } 
} 

public round_end() 
{ 
    static id 
    new num, iPlayers[32] 
    get_players(iPlayers, num) 
    if( !num ) 
    { 
        return; 
    } 
    for(new i = 0; i < num; i++) 
    { 
        id = iPlayers[i] 
        if(!is_user_connected(id)) 
            continue 

        if(in_frost[i-1]||in_burn[i-1])in_frost[i-1]=false,in_burn[i-1]=false,fm_set_rendering(i) 
    } 
} 

//Standart Forwards 
public client_connect(id)Can_Use_Ability[id-1]=false,Selected_Ability[id-1]=0 
public client_PreThink(id) 
{ 
        new Float:gametime = get_gametime() 
        if(in_frost[id-1]) 
                 
                if(FrostTime[id-1]<gametime||!is_user_alive(id)) 
                 
                if(FrostTime[id-1]<gametime||!is_user_alive(id)||is_user_zombie(id)) 
                 
                        fm_set_rendering(id), 
                        in_frost[id-1]=false 
                else 
                        {set_pev(id,pev_velocity,{0.0,0.0,0.0});new Float:Origin[3];pev(id,pev_origin,Origin);Light(Origin,15,0,105,255,4);} 
        if(in_burn[id-1]) 
                 
                if(BurnTime[id-1]<gametime||!is_user_alive(id)) 
                 
                if(BurnTime[id-1]<gametime||!is_user_alive(id)||is_user_zombie(id)) 
                 
                        in_burn[id-1]=false 
                else 
                        if(BurnUpdateDamage[id-1]<gametime) 
                        { 
                                if(pev(id,pev_armorvalue)<=0.0&&pev(id,pev_health)<BurnDamage)ExecuteHamB(Ham_TakeDamage,id, 0,BurnOwner[id-1], BurnDamage, DMG_BURN) 
                                else ExecuteHamB(Ham_TakeDamage,id, 0,0, BurnDamage, DMG_BURN) 
                                
                                BurnUpdateDamage[id-1]=gametime+BurnUpdate 
                                
                                new Float:Origin[3] 
                                pev(id,pev_origin,Origin) 
                                engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, Origin, 0) 
                                write_byte(TE_SPRITE) // TE id 
                                engfunc(EngFunc_WriteCoord, Origin[0]+random_float(-5.0, 5.0)) // x 
                                engfunc(EngFunc_WriteCoord, Origin[1]+random_float(-5.0, 5.0)) // y 
                                engfunc(EngFunc_WriteCoord, Origin[2]+random_float(-10.0, 10.0)) // z 
                                write_short(BurnSprite) // sprite 
                                write_byte(random_num(5, 10)) // scale 
                                write_byte(200) // brightness 
                                message_end() 
                                Light(Origin,15,255,105,0,7)    
                        } 
        if(!is_user_alive(id))return 
         
        if(!is_user_zombie(id))return 
         
        if(get_user_class(id)!=Jack)return 
         
        if(UpdateHud[id-1]<gametime) 
        { 
                new Text0[100], Text1[56],Text2[56] 
                formatex(Text0, 99, "Press [E] to change the Element Power [Fire] or [Ice]^nPress [G] to use ability^n^n") 
                switch(Selected_Ability[id-1]) 
                { 
                        case 0:formatex(Text1, 55, "Selected Ability: Throw Fire Shpere^n") 
                        case 1:formatex(Text1, 55, "Selected Ability: Throw Ice Sphere^n") 
                } 
                if(!Can_Use_Ability[id-1]) 
                { 
                        if(Ability_CD[id-1]-gametime>0.0)formatex(Text2, 55, "Recharge Ability: %..1f^n",Ability_CD[id-1]-gametime) 
                        else formatex(Text2, 55, "Recharge Ability: Ready to use^n"),Can_Use_Ability[id-1]=true 
                } 
                set_hudmessage(255,255,255,0.02,0.2,0,0.1,1.0,0.0,0.0,CDHudChannel) 
                show_hudmessage(id,"%s%s%s",Text0,Text1,Text2) 
                UpdateHud[id-1]=gametime+0.1 
        } 
        //Select Ability 
        if((pev(id,pev_button)&IN_USE)&&!(pev(id,pev_oldbuttons)&IN_USE)) 
        { 
                switch(Selected_Ability[id-1]) 
                { 
                        case 0:Selected_Ability[id-1]=1 
                        case 1:Selected_Ability[id-1]=0 
                } 
        } 
        //Use ability 
        if(Can_Use_Ability[id-1]) 
        if (pev(id,pev_impulse)==100) 
        { 
                switch(Selected_Ability[id-1]) 
                { 
                        case 0:throw_Shpere(id,1),Ability_CD[id-1]=gametime+FireShpere_CD,Can_Use_Ability[id-1]=false 
                        case 1:throw_Shpere(id,2),Ability_CD[id-1]=gametime+FrostSphere_CD,Can_Use_Ability[id-1]=false 
                } 
                
        } 
} 
//Public func 
public throw_Shpere(id,type) 
{ 
        emit_sound(id, CHAN_VOICE, ThrowFireShpereSound, 1.0, ATTN_NORM, 0, PITCH_NORM) //Play sound 
        set_pdata_float(id, 83, 0.7, 5) //Block attack 
        UTIL_PlayWeaponAnimation(id,5)  //And play Anim 
        
        new Float:StartOrigin[3],Float:EndOrigin[3] 
        get_position(id,30.0,0.0,5.0,StartOrigin) 
        fm_get_aim_origin(id,EndOrigin) 
        
        new ient = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target")) 
        engfunc(EngFunc_SetModel,ient, Shpere) 
        engfunc(EngFunc_SetSize, ient, {-3.0,-3.0,-3.0}, {3.0,3.0,3.0}) 
        switch(type) 
        { 
                case 1: set_pev(ient, pev_classname, FireShpere_Classname), 
                        fm_set_rendering(ient, kRenderFxGlowShell, 255,105,0, kRenderTransAlpha,55) 
                case 2: set_pev(ient, pev_classname, FrostSphere_Classname), 
                        fm_set_rendering(ient, kRenderFxGlowShell, 0,105,255, kRenderTransAlpha,55) 
        } 
        set_pev(ient, pev_movetype, MOVETYPE_FLY) 
        set_pev(ient,pev_solid,SOLID_TRIGGER) 
        set_pev(ient,pev_origin,StartOrigin) 
        set_pev(ient,pev_owner,id) 
        set_pev(ient, pev_nextthink, get_gametime() +0.01)              
        set_pev(ient,pev_iuser1,type) 
        
        //Sphere Trail 
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
        write_byte(TE_BEAMFOLLOW) 
        write_short(ient) 
        write_short(TrailSpriteIndex) 
        write_byte(15) 
        write_byte(15) 
        switch(type)    //Select colors 
        { 
                case 1: 
                { 
                        write_byte(255) 
                        write_byte(105) 
                        write_byte(0) 
                } 
                case 2: 
                { 
                        write_byte(0) 
                        write_byte(105) 
                        write_byte(255) 
                } 
        } 
        write_byte(155) 
        message_end() 
        
        new Float:VECTOR[3],Float:VELOCITY[3] 
        xs_vec_sub(EndOrigin, StartOrigin, VECTOR) 
        xs_vec_normalize(VECTOR, VECTOR) 
        xs_vec_mul_scalar(VECTOR, 1300.0, VELOCITY)     //1300.0 - Sphere speed! (Max 2000.0!!!) 
        set_pev(ient, pev_velocity, VELOCITY) 
} 
//Stocks 
stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[]) 
{ 
        new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3] 
        pev(id, pev_v_angle, vAngle);pev(id, pev_origin, vOrigin);pev(id, pev_view_ofs,vUp) 
        xs_vec_add(vOrigin,vUp,vOrigin) 
        angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) 
        angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight) 
        angle_vector(vAngle,ANGLEVECTOR_UP,vUp) 
        vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up 
        vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up 
        vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up 
} 
stock DrawRings(Float:Origin[3],R,G,B) 
{ 
        for(new i=0;i<4;i++) 
        { 
                message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
                write_byte( TE_BEAMTORUS ); 
                engfunc(EngFunc_WriteCoord, Origin[0]) 
                engfunc(EngFunc_WriteCoord, Origin[1]) 
                engfunc(EngFunc_WriteCoord, Origin[2]+3.0*i) 
                engfunc(EngFunc_WriteCoord, Origin[0]) 
                engfunc(EngFunc_WriteCoord, Origin[1]) 
                engfunc(EngFunc_WriteCoord, Origin[2]+100.0+10.0*i) 
                write_short( TrailSpriteIndex ); // sprite 
                write_byte( 0 ); // Starting frame 
                write_byte( 0  ); // framerate * 0.1 
                write_byte( 8-1*i ); // life * 0.1 
                write_byte( 14 ); // width 
                write_byte( 0 ); // noise 
                write_byte( R ); // color r,g,b 
                write_byte( G ); // color r,g,b 
                write_byte( B); // color r,g,b 
                write_byte( 255 ); // brightness 
                write_byte( 0 ); // scroll speed 
                message_end();   
        }       
} 
stock Light(Float:Origin[3],RAD,R,G,B,Life) 
{ 
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
        write_byte(TE_DLIGHT) 
        engfunc(EngFunc_WriteCoord, Origin[0]) 
        engfunc(EngFunc_WriteCoord, Origin[1]) 
        engfunc(EngFunc_WriteCoord, Origin[2]) 
        write_byte(RAD) //Radius 
        write_byte(R)   // r 
        write_byte(G)   // g 
        write_byte(B)   // b 
        write_byte(Life)        //Life 
        write_byte(10) 
        message_end() 
} 
stock ScreenFade(id, Timer, FadeTime, Colors[3], Alpha, type) 
{ 
        if(id) if(!is_user_connected(id)) return 
  
        if (Timer > 0xFFFF) Timer = 0xFFFF 
        if (FadeTime <= 0) FadeTime = 4 
        
        message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST,Msg_ScreenFade, _, id); 
        write_short(Timer * 1 << 12) 
        write_short(FadeTime * 1 << 12) 
        switch (type) 
        { 
                case 1: write_short(0x0000)             // IN ( FFADE_IN ) 
                case 2: write_short(0x0001)             // OUT ( FFADE_OUT ) 
                case 3: write_short(0x0002)             // MODULATE ( FFADE_MODULATE ) 
                case 4: write_short(0x0004)             // STAYOUT ( FFADE_STAYOUT ) 
                default: write_short(0x0001) 
        } 
        write_byte(Colors[0]) 
        write_byte(Colors[1]) 
        write_byte(Colors[2]) 
        write_byte(Alpha) 
        message_end() 
} 
stock ScreenShake(id, duration, frequency) 
{       
        message_begin(id ? MSG_ONE_UNRELIABLE : MSG_ALL, Msg_ScreenShake, _, id ? id : 0); 
        write_short(1<<14) 
        write_short(duration) 
        write_short(frequency) 
        message_end(); 
} 
stock UTIL_PlayWeaponAnimation(const Player, const Sequence) 
{ 
        set_pev(Player, pev_weaponanim, Sequence) 
        
        message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player) 
        write_byte(Sequence) 
        write_byte(pev(Player, pev_body)) 
        message_end() 
}  