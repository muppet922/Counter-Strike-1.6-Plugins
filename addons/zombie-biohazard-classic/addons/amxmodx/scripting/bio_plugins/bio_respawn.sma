/*
 _,.~^*^~.,_Halo Style Respawning_,.~^*^~.,_
 
 Credits:
	CSDM - for the CSDM spawn points - duh!
		 - for the csdm_spawn_preset.sma - thanks open source ^_^
 
 //- Cvars -
 sv_HSR			//Turns HSR on(1|2) and off(0)
					//1 - kills subtract time, deaths add time
					//2 - suicides and team kills add time
 sv_HSRspawns	//Use CSDM spawns(1) or normal team spawns(0)
					//- Note: If there is no CSDM spawn configuration
					//		  for the current map, normal team spawns
					//		  will be used. Also, players will be given
					//		  pistols every spawn.
 sv_HSRtime		//How many seconds are added
 sv_HSRmaxtime	//Max seconds for players
 */

 #include <amxmodx>
 #include <amxmisc>
 #include <cstrike>
 #include <engine>
 #include <fun>
 #include <biohazard>

 #define PLUGNAME		"Halo Style Respawning"
 #define AUTHOR			"TEST"
 #define VERSION		"1.31"

 #define	MAX_SPAWNS	60
 #define	MAX_SPEAK	10

 new Float:HSRtime[33]				//countdown for the users
 new SOrigin[33][3];

 new Float:g_SpawnVecs[MAX_SPAWNS][3];
 new Float:g_SpawnAngles[MAX_SPAWNS][3];
 new Float:g_SpawnVAngles[MAX_SPAWNS][3];
 new g_TotalSpawns;
 
 //for pcvars
 new sv_HSR, sv_HSRspawns, sv_HSRtime, sv_HSRmaxtime
 public plugin_init()
 {

	register_plugin(PLUGNAME, VERSION, AUTHOR)

	sv_HSR = register_cvar("sv_HSR", "1")
	sv_HSRspawns = register_cvar("sv_HSRspawns", "1")
	sv_HSRtime = register_cvar("sv_HSRtime", "1.0")
	sv_HSRmaxtime = register_cvar("sv_HSRmaxtime", "2.0")

	register_event("DeathMsg","DeathEvent","a")

	readSpawns()
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET);
 }
////////////////////////////////////////////////////////////////////////////
// To lazy to rewrite everything, and plus I bet this is probably written //
//   the best it can be, right? I mean BAILOPAN and Freecode wrote it!	  //
////////////////////////////////////////////////////////////////////////////
 readSpawns()
 {
	//-617 2648 179 16 -22 0 0 -5 -22 0
	// Origin (x,y,z), Angles (x,y,z), vAngles(x,y,z), Team (0 = ALL) - ignore
	// :TODO: Implement team specific spawns
	
	new Map[32], config[32],  MapFile[64];
	
	get_mapname(Map, 31)
	get_configsdir(config, 31 )
	format(MapFile, 63, "%s\csdm\%s.spawns.cfg", config, Map);
	g_TotalSpawns = 0;
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[12][8];
    		
		while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2 || Data[0] == '[')
				continue;

			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);
			
			// Origin
			g_SpawnVecs[g_TotalSpawns][0] = str_to_float(pos[1]);
			g_SpawnVecs[g_TotalSpawns][1] = str_to_float(pos[2]);
			g_SpawnVecs[g_TotalSpawns][2] = str_to_float(pos[3]);
			
			//Angles
			g_SpawnAngles[g_TotalSpawns][0] = str_to_float(pos[4]);
			g_SpawnAngles[g_TotalSpawns][1] = str_to_float(pos[5]);
			g_SpawnAngles[g_TotalSpawns][2] = str_to_float(pos[6]);
			
			//v-Angles
			g_SpawnVAngles[g_TotalSpawns][0] = str_to_float(pos[7]);
			g_SpawnVAngles[g_TotalSpawns][1] = str_to_float(pos[8]);
			g_SpawnVAngles[g_TotalSpawns][2] = str_to_float(pos[9]);
			
			//Team - ignore
			
			g_TotalSpawns++;
		}
		
		log_amx("Loaded %d spawn points for map %s.", g_TotalSpawns, Map)
	} else {
		log_amx("No spawn points file found (%s)", MapFile)
	}
	
	return 1;
 }
 // I didn't see the point in the "num" in spawn_Preset(id, num) since
 // there is a new num being created. Anyone want to tell me why it's there?
 public spawn_Preset(id)
 {
	if (g_TotalSpawns < 2)
		return PLUGIN_CONTINUE
	
	new list[MAX_SPAWNS];
	new num = 0; 
	new final = -1; 
	new total=0; 
	new players[32], n, x = 0;
	new Float:loc[32][3], locnum
	
	//cache locations
	get_players(players, num)
	for (new i=0; i<num; i++)
	{
		if (is_user_alive(players) && players != id)
		{
			entity_get_vector(players, EV_VEC_origin, loc[locnum])
			locnum++
		}
	}
	
	num = 0
	while (num <= g_TotalSpawns)
	{
		//have we visited all the spawns yet?
		if (num == g_TotalSpawns)
			break;
		//get a random spawn
		n = random_num(0, g_TotalSpawns-1);
		//have we visited this spawn yet?
		if (!list[n])
		{
			//yes, set the flag to true, and inc the number of spawns we've visited
			list[n] = 1;
			num++;
		} 
		else 
		{
	        //this was a useless loop, so add to the infinite loop prevention counter
			total++;
			if (total > 100) // don't search forever
				break;
			continue;   //don't check again
		}

		new trace  = trace_hull(g_SpawnVecs[n],1);
		if (trace)
			continue;
		
		if (locnum < 1)
		{
			final = n
			break
		}
		
		final = n
		for (x = 0; x < locnum; x++)
		{
			new Float:distance = get_distance_f(g_SpawnVecs[n], loc[x]);
			if (distance < 250.0)
			{
				//invalidate
				final = -1;
				break;
			}
		}
		
		if (final != -1)
			break
	}
	
	if (final != -1)
	{
		entity_set_origin(id, g_SpawnVecs[final]);
		entity_set_int(id, EV_INT_fixangle, 1);
		entity_set_vector(id, EV_VEC_angles, g_SpawnAngles[final]);
		entity_set_vector(id, EV_VEC_v_angle, g_SpawnVAngles[final]);
		entity_set_int(id, EV_INT_fixangle, 1);
		
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
 }
 public DeathEvent()
 {
	new attacker = read_data(1)
	new id = read_data(2)

	if(get_pcvar_num(sv_HSR)<1) return PLUGIN_CONTINUE
	if(1>get_user_team(id)>2) return PLUGIN_CONTINUE

	switch(get_pcvar_num(sv_HSR))
	{
		case 2:{
			if(is_user_connected(attacker)){
				if(get_user_team(id)==get_user_team(attacker) || id==attacker){
					HSRtime[attacker] += get_pcvar_num(sv_HSRtime)
					if(HSRtime[attacker] > get_pcvar_num(sv_HSRmaxtime))
						HSRtime[attacker] = get_pcvar_float(sv_HSRmaxtime)
				}
			}
		}
		case 1:{
			if(is_user_alive(attacker)){
				HSRtime[attacker] -= get_pcvar_num(sv_HSRtime)
				if(HSRtime[attacker]<1.0)
					HSRtime[attacker] = 1.0
			}

			HSRtime[id] += get_pcvar_num(sv_HSRtime)
			if(HSRtime[id] > get_pcvar_num(sv_HSRmaxtime))
				HSRtime[id] = get_pcvar_float(sv_HSRmaxtime)
		}
		default: return PLUGIN_CONTINUE
	}

	new time = floatround(HSRtime[id]) + 1

	new parm[2]
	parm[0] = id
	parm[1] = time

	set_task(0.1,"check_respawn",0,parm,2)

	return PLUGIN_CONTINUE
 }
 public check_respawn(parm[])
 {
	new id = parm[0]
	parm[1]--

	if(is_user_alive(id) || !is_user_zombie(id) )
		return

	if(parm[1]==0){
		respawn(id)
	}
	else{
		if(parm[1]<MAX_SPEAK){
			new speak[30]
			num_to_word(parm[1], speak, 29)
			client_cmd(id,"spk ^"fvox/%s^"",speak) 
		}
		client_print(id, print_center, "You will respawn in %d seconds.", parm[1])
		set_task(1.0,"check_respawn",0,parm,2)
	}
 }
 public respawn(id)
 {
	if( is_user_alive(id) ||  !is_user_connected(id)) return -1

	if(is_user_zombie(id) ) {
		new parm[2]
		parm[0] = id
		parm[1] = 0
		set_task( 0.5, "actual_revive", 1, parm, 2)
		parm[1] = 1
		set_task( 0.7, "actual_revive", 1, parm, 2)
		return 1
	}
	return 0
 }
 public actual_revive(parm[])
 {
	new id = parm[0], a = parm[1]
	spawn(id)
	if(a==0)
		get_user_origin(id, SOrigin[id])
	else {
		if(get_pcvar_num(sv_HSRspawns) > 0)
			spawn_Preset(id)
		else
			set_user_origin(id, SOrigin[id])
	}
 }


 public client_connect(id)
 {
	HSRtime[id] = get_pcvar_float(sv_HSRtime)
 }
 public client_putinserver(id)
 {
	set_task(1.0,"first_respawn",id)
 }
 public first_respawn(id)
 {
	if(!respawn(id))
		set_task(1.0,"first_respawn",id)
 }
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/