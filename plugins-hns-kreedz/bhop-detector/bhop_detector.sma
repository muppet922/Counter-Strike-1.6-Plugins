/* AMX Mod X Plugin
* 
* This file is provided as is (no warranties). 
* (C) 2007, Alka
*
*Thanks:
*-DarkSnow [Stock]
*
*Description:
*-This plugin detect when someone do bhop!This use aim vectors and constant button.
*-If you make more than 1 strafe and you hold(or press) down the jump button, you will be punished!
*-With this plugin you can't make any kind of bhop!
*/ 

#include <amxmodx>
#include <engine>
#include <amxmisc>

#define PLUGIN "Bhop Detector"
#define VERSION "1.2"
#define AUTHOR "Alka"

#define G_MAXPLAYERS 32

new Detect[G_MAXPLAYERS+1]
new Float:pStrafe[G_MAXPLAYERS+1][3]
new punish_type, slap_force, toggle_plugin, ban_time;


public plugin_init()
{   
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	toggle_plugin = register_cvar("amx_bhopdetect","1");
	punish_type = register_cvar("amx_punishtype","1");
	slap_force = register_cvar("amx_slap_force","1");
	ban_time = register_cvar("amx_ban_time","15");
	
}

public client_PreThink(id)
{   
	if(!get_pcvar_num(toggle_plugin) || is_user_bot(id))
		return 1;
	
	static Float:aim[3], detect_id
	
	entity_get_vector(id, EV_VEC_angles, aim)
	
	detect_id = Detect[id]
	
	if(aim[0] == pStrafe[id][0] && aim[1] == pStrafe[id][1])
	{
		detect_id -= 12
	}
	else
	{
		detect_id++
	}
	
	if((entity_get_int(id, EV_INT_button) & IN_JUMP) && detect_id < 0)
	{
		detect_id = 0
	}
	
	if(detect_id > 70 && entity_get_int(id, EV_INT_button) & IN_JUMP)
	{
		static p_name[32], p_authid[32]
		new ctime[64]
		
		get_time("%m/%d/%Y - %H:%M:%S", ctime, 63)
		get_user_name(id, p_name,31)
		get_user_authid(id, p_authid,31)
		
		switch(get_pcvar_num(punish_type))
		{
			
			case 1:
			{
				set_hudmessage(255, 0, 0, 0.5, 0.5, 0, 6.0, 5.0, 0.1, 0.1, -1);
				show_hudmessage(id, "Warning: Bhop detected!^nThis is not allowed here!");
			}
			
			case 2:
				set_task(0.1,"slap_pl",id,_,_,"a",5)
			
			
			case 3:
			{
				server_cmd("kick #%d Bhop detected!",get_user_userid(id))
				
				set_hudmessage(255,150, 0, 0.30, 0.85, 1, 6.0, 5.0, 0.1, 0.1, -1);
				show_hudmessage(0,"Warning: %s was kicked for doing Bhop!",p_name);
			}
			
			case 4:
			{
				server_cmd("amx_ban ^"%s^" %d Bhop detected!",p_authid,get_pcvar_num(ban_time))
				
				set_hudmessage(255,150, 0, 0.30, 0.85, 1, 6.0, 5.0, 0.1, 0.1, -1);
				show_hudmessage(0,"Warning: %s was banned (%d min.) for doing Bhop!",p_name,get_pcvar_num(ban_time));
			}
			
		}
		
		log_to_file("bhop_detector.txt","  %s was detected doing bhop! Punish Type: %d ^n[%s] ^n", p_name, get_pcvar_num(punish_type),ctime)
		
		detect_id = 0;
	}
	
	Detect[id] = detect_id
	
	CopyVector(aim,pStrafe[id])
	
	return 1;
}

public client_connect(id)
{
	Detect[id] = 0
}

stock CopyVector(Float:Vec1[3],Float:Vec2[3])
{
	Vec2[0] = Vec1[0]
	
	Vec2[1] = Vec1[1]
	
	Vec2[2] = Vec1[2]
}

public slap_pl(id)
{
	user_slap(id,get_pcvar_num(slap_force),1)
}
