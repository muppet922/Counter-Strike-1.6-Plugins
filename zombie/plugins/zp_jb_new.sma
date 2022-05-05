#include <amxmodx>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>
#include <colorchat>
#include <amxmisc>



// HUD messages
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.17
const Float:HUD_INFECT_X = 0.05
const Float:HUD_INFECT_Y = 0.45
const Float:HUD_SPECT_X = -1.0
const Float:HUD_SPECT_Y = 0.8
const Float:HUD_STATS_X = 0.02
const Float:HUD_STATS_Y = 0.9

#pragma tabsize 0

#define PLUGINNAME		"[ZP] Extra: Jetpack+Bazooka"
#define VERSION			"1.0"
#define AUTHOR			"SAYFZM"

#define MAX_PLAYERS	32

#define ACCESS_LEVEL	ADMIN_LEVEL_A

#define TE_EXPLOSION	3
#define TE_BEAMFOLLOW	22
#define TE_BEAMCYLINDER	21

#define JETPACK_COST  30 // set how may ammopacks the Jatpack+Rocket cost

new ROCKET_MDL[64] = "models/rpgrocket.mdl"
new ROCKET_SOUND[64] = "zombie_plague/rocket_fire.wav"
new getrocket[64] = "items/9mmclip2.wav"

new bool:fly[33] = false
new bool:rocket[33] = false
new bool:rksound[33] = false
new bool:shot[33] = false

new frame[33];

new const Float:g_flCoords[][] =
{
	{0.50, 0.40},
	{0.56, 0.44},
	{0.60, 0.50},
	{0.56, 0.56},
	{0.50, 0.60},
	{0.44, 0.56},
	{0.40, 0.50},
	{0.44, 0.44}
}

new g_iPlayerPos[MAX_PLAYERS+1]
new g_iEventsHudmessage
new g_buyabletime, cvar_buy_delay

new Float:gltime = 0.0
new Float:last_Rocket[33] = 0.0
new Float:jp_cal[33] = 0.0
new Float:jp_soun[33] = 0.0
new flame, explosion, trail, white
new g_flyEnergy[33], hasjet[33]
new cvar_jetpack, cvar_jetpackSpeed, cvar_RocketDmg, cvar_SniperDmg, cvar_Dmg_range, cvar_jetpackUpSpeed, cvar_jetpackAcrate ,cvar_RocketDelay, cvar_RocketSpeed, cvar_fly_max_engery, cvar_fly_engery, cvar_regain_energy, g_item_jetpack, cvar_cal_time, cvar_oneround


public plugin_init() {
	register_plugin(PLUGINNAME, VERSION, AUTHOR)

	g_item_jetpack = zp_register_extra_item("\r[\yZP\r]\yJetpack\r(one round)", JETPACK_COST, ZP_TEAM_HUMAN)
	register_clcmd("drop","cmdDrop")

	new ver[64]
	format(ver,63,"%s v%s",PLUGINNAME,VERSION)
	register_cvar("zp_jp_version",ver,FCVAR_SERVER)

	cvar_jetpack = register_cvar("zp_jp_jetpack", "2")

	cvar_jetpackSpeed=register_cvar("zp_jp_forward_speed","350.0")
	cvar_jetpackUpSpeed=register_cvar("zp_jp_up_speed","35.0")
	cvar_jetpackAcrate=register_cvar("zp_jp_accelerate","100.0")

	cvar_RocketDelay=register_cvar("zp_jp_rocket_delay","12.0")
	cvar_RocketSpeed=register_cvar("zp_jp_rocket_speed","1700")
	cvar_RocketDmg=register_cvar("zp_jp_rocket_damage","350")
	cvar_SniperDmg=register_cvar("zp_sniper_damage","4000")
	cvar_Dmg_range=register_cvar("zp_jp_damage_radius","600")

	cvar_fly_max_engery = register_cvar("zp_jp_max_engery", "100")
	cvar_fly_engery = register_cvar("zp_jp_engery", "10")
	cvar_regain_energy = register_cvar("zp_jp_regain_energy", "3")
	cvar_cal_time = register_cvar("zp_jp_energy_cal", "1.0")
	cvar_oneround = register_cvar("zp_jp_oneround", "1")

	register_event("CurWeapon", "check_models", "be")
	register_event("DeathMsg", "player_die", "a")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	register_forward(FM_StartFrame, "fm_startFrame")
	register_forward(FM_PlayerPreThink, "fm_prethink")
	register_forward(FM_EmitSound, "emitsound")


	register_clcmd("zp_jetpack", "cmdJetpack", ADMIN_KICK, "[ZP] zp_jetpack <name>")
	register_clcmd("zp_drop_jetpack", "cmdDropJetpack", ADMIN_KICK, "[ZP] zp_drop_jetpack <name>")


	g_iEventsHudmessage = CreateHudSyncObj(0);


	set_task(1.0,"regain_dropped")
}

public plugin_precache() {
	precache_model("models/p_egon.mdl")
	precache_model("models/v_egon.mdl")
	precache_model("models/w_egon.mdl")
	precache_sound("jetpack.wav")
	precache_sound("jp_blow.wav")

	precache_model(ROCKET_MDL)
	precache_sound(ROCKET_SOUND)
	precache_sound(getrocket)

	explosion = precache_model("sprites/zerogxplode.spr")
	trail = precache_model("sprites/smoke.spr")
	flame = precache_model("sprites/xfireball3.spr")
	white = precache_model("sprites/white.spr")

cvar_buy_delay = register_cvar("zp_extra_item_delay", "2.0")

}

public client_putinserver(id) {
	fly[id] = false
	rocket[id] = false
	hasjet[id] = 0
	g_flyEnergy[id] = 0
}

public client_disconnect(id) {
	fly[id] = false
	rocket[id] = false
	hasjet[id] = 0
	g_flyEnergy[id] = 0
}

public event_round_start()
{
g_buyabletime = false
set_task(get_pcvar_float(cvar_buy_delay), "canbuy");
remove_jetpacks();
	if (get_pcvar_num(cvar_oneround) == 1) {
		for (new id; id <= 32; id++)
		{
		hasjet[id] = 0
		g_flyEnergy[id] = 0
		fly[id] = false
		}
	}
	else
	{
		for (new id; id <= 32; id++)
		{
		g_flyEnergy[id] = get_pcvar_num(cvar_fly_max_engery)
		last_Rocket[id] = 0.0
		rocket[id]=true
		}
	}
}


public canbuy()
g_buyabletime = true

public fm_startFrame(){

    gltime = get_gametime()
    static id
    for (id = 1; id <= 32; id++)
    {
       frame[id]++;

    }
}

public fm_prethink(id) {

    if(is_user_alive(id))
       jp_forward(id)
}

public jp_forward(player) {

	if (!is_user_alive(player) && (zp_get_user_zombie(player) || zp_get_user_nemesis(player)))
		return FMRES_IGNORED

	if (!hasjet[player])
		return FMRES_IGNORED

	if(jp_cal[player] < gltime){
		jp_energy(player); jp_cal[player] = gltime + get_pcvar_float(cvar_cal_time)
	}

	check_rocket(player)



		if(get_pcvar_num(cvar_jetpack) == 1){
			if(!(pev(player, pev_flags)&FL_ONGROUND) && pev(player,pev_button)&IN_ATTACK){
				if(g_flyEnergy[player] > get_pcvar_num(cvar_fly_max_engery)*0.3){
					if(jp_soun[player] < gltime){
						emit_sound(player,CHAN_ITEM,"jetpack.wav",1.0,ATTN_NORM,0,PITCH_NORM)
						jp_soun[player] = gltime + 0.2
					}
				}
				else if((g_flyEnergy[player] > 0) && (g_flyEnergy[player] < get_pcvar_num(cvar_fly_max_engery)*0.3)){
					if(jp_soun[player] < gltime){
							emit_sound(player,CHAN_ITEM,"jp_blow.wav",1.0,ATTN_NORM,0,PITCH_NORM)
							jp_soun[player] = gltime + 0.1
					}
				}
			}
			human_fly(player)
			attack(player)
		}
		if((pev(player,pev_button)&IN_ATTACK2)){
				attack2(player)
			}

	if((get_pcvar_num(cvar_jetpack) == 2 && !(pev(player, pev_flags)&FL_ONGROUND)) && (pev(player,pev_button)&IN_JUMP && pev(player,pev_button)&IN_DUCK)){
		if(g_flyEnergy[player] > get_pcvar_num(cvar_fly_max_engery)*0.3){
			if(jp_soun[player] < gltime){
				emit_sound(player,CHAN_ITEM,"jetpack.wav",1.0,ATTN_NORM,0,PITCH_NORM)
				jp_soun[player] = gltime + 0.2
			}
		}
		else if((g_flyEnergy[player] > 0) && (g_flyEnergy[player] < get_pcvar_num(cvar_fly_max_engery)*0.3)){
			if(jp_soun[player] < gltime){
				emit_sound(player,CHAN_ITEM,"jp_blow.wav",1.0,ATTN_NORM,0,PITCH_NORM)
				jp_soun[player] = gltime + 0.1
			}
		}
		human_fly(player)
		attack(player)
	}

	return FMRES_IGNORED
}

public jp_energy(player) {

		if (!(pev(player, pev_flags)&FL_ONGROUND) && pev(player,pev_button)&IN_ATTACK)
		{
			// Get our current velocity
			new clip,ammo
			new wpnid = get_user_weapon(player,clip,ammo)
			if (wpnid == CSW_KNIFE)
			{
			// flying
			if(g_flyEnergy[player] > get_pcvar_num(cvar_fly_max_engery)*0.09)
				g_flyEnergy[player] = g_flyEnergy[player] - get_pcvar_num(cvar_fly_engery);	 // Increase distance counter
			}
		}
		else if ((get_pcvar_num(cvar_jetpack) == 2 && !(pev(player, pev_flags)&FL_ONGROUND)) && (pev(player,pev_button)&IN_JUMP && pev(player,pev_button)&IN_DUCK))
		{
			if(g_flyEnergy[player] > get_pcvar_num(cvar_fly_max_engery)*0.09)
				g_flyEnergy[player] = g_flyEnergy[player] - get_pcvar_num(cvar_fly_engery);	 // Increase distance counter
		}
		// Walking/Runnig
		if (pev(player, pev_flags) & FL_ONGROUND)
			g_flyEnergy[player] = g_flyEnergy[player] + get_pcvar_num(cvar_regain_energy);// Decrease distance counter
}

public attack(player) {
//code snippa from TS_Jetpack 1.0 - Jetpack plugin for The Specialists.
//http://forums.alliedmods.net/showthread.php?t=55709&highlight=jetpack
//By: Bad_Bud
	if(fly[player])
	{
		static Float:JetpackData[3]
		pev(player,pev_velocity,JetpackData)

		new fOrigin[3],Float:Aim[3]
		VelocityByAim(player, 10, Aim)
		get_user_origin(player,fOrigin)
		fOrigin[0] -= floatround(Aim[0])
		fOrigin[1] -= floatround(Aim[1])
		fOrigin[2] -= floatround(Aim[2])


		if((pev(player,pev_button)&IN_JUMP && pev(player,pev_button)&IN_DUCK) && !(pev(player, pev_flags) & FL_ONGROUND))
			{

				message_begin(MSG_ALL,SVC_TEMPENTITY)
				write_byte(17)
				write_coord(fOrigin[0])
				write_coord(fOrigin[1])
				write_coord(fOrigin[2])
				write_short(flame)
				write_byte(8)
				write_byte(50)
				message_end()

				static Float:Speed
				Speed=floatsqroot(JetpackData[0]*JetpackData[0]+JetpackData[1]*JetpackData[1])

				if(Speed!=0.0)//Makes players only lay down if their speed isn't 0; if they are thrusting forward.
				{
					set_pev(player,EV_INT_movetype,6)
					set_pev(player, pev_frame, 0.9)
				}

				if(Speed<get_pcvar_float(cvar_jetpackSpeed))
					Speed+=get_pcvar_float(cvar_jetpackAcrate)

				static Float:JetpackData2[3]
				pev(player,pev_angles,JetpackData2)
				JetpackData2[2]=0.0//Remove the Z value/

				angle_vector(JetpackData2,ANGLEVECTOR_FORWARD,JetpackData2)
				JetpackData2[0]*=Speed
				JetpackData2[1]*=Speed

				JetpackData[0]=JetpackData2[0]
				JetpackData[1]=JetpackData2[1]
			}

		if(JetpackData[2]<get_pcvar_float(cvar_jetpackSpeed)&&JetpackData[2]>0.0)//Jetpacks get more power on the way down -- it helps landing.
				JetpackData[2]+=get_pcvar_float(cvar_jetpackUpSpeed)
			else if(JetpackData[2]<0.0)
				JetpackData[2]+=(get_pcvar_float(cvar_jetpackUpSpeed)*1.15)

		set_pev(player,pev_velocity,JetpackData)
	}
}

public attack2(player) {

	if (rocket[player])
	{

		new rocket = create_entity("info_target")
		if(rocket == 0) return PLUGIN_CONTINUE

		entity_set_string(rocket, EV_SZ_classname, "zp_jp_rocket")
		entity_set_model(rocket, ROCKET_MDL)

		entity_set_size(rocket, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0})
		entity_set_int(rocket, EV_INT_movetype, MOVETYPE_FLY)
		entity_set_int(rocket, EV_INT_solid, SOLID_BBOX)

		new Float:vSrc[3]
		entity_get_vector(player, EV_VEC_origin, vSrc)

		new Float:Aim[3],Float:origin[3]
		VelocityByAim(player, 64, Aim)
		entity_get_vector(player,EV_VEC_origin,origin)

		vSrc[0] += Aim[0]
		vSrc[1] += Aim[1]
		entity_set_origin(rocket, vSrc)

		new Float:velocity[3], Float:angles[3], fOrigin[3]
		VelocityByAim(player, get_pcvar_num(cvar_RocketSpeed), velocity)

		entity_set_vector(rocket, EV_VEC_velocity, velocity)
		vector_to_angle(velocity, angles)
		entity_set_vector(rocket, EV_VEC_angles, angles)
		entity_set_edict(rocket,EV_ENT_owner,player)
		entity_set_float(rocket, EV_FL_takedamage, 1.0)

		set_pev(rocket, pev_effects, EF_LIGHT)

                message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(rocket)
		write_short(trail)
		write_byte(25)
		write_byte(8)
		write_byte(255)
		write_byte(255)
		write_byte(255)
		write_byte(100)
		message_end()

				message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
				write_byte( TE_BEAMTORUS );
				write_coord( fOrigin[0]); // Start X
				write_coord( fOrigin[1] ); // Start Y
				write_coord( fOrigin[2]); // Start Z
				write_coord( fOrigin[0] ); // End X
				write_coord( fOrigin[1] ); // End Y
				write_coord( fOrigin[2] + 10); // End Z
				write_short( flame ); // sprite
				write_byte( 0 ); // Starting frame
				write_byte( 50  ); // framerate * 0.1
				write_byte( 5 ); // life * 0.1
				write_byte( 50 ); // width
				write_byte( 0 ); // noise
				write_byte( 0 ); // color r,g,b
				write_byte( 255 ); // color r,g,b
				write_byte( 0 ); // color r,g,b
				write_byte( 100 ); // brightness
				write_byte( 0 ); // scroll speed
				message_end();

		emit_sound(rocket, CHAN_WEAPON, ROCKET_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM)

		shot[player] = true
		last_Rocket[player] = gltime + get_pcvar_num(cvar_RocketDelay)
	}
	return PLUGIN_CONTINUE
}

public check_models(id) {

	if (zp_get_user_zombie(id) || zp_get_user_nemesis(id))
		return FMRES_IGNORED

	if(hasjet[id]) {
		new clip,ammo
		new wpnid = get_user_weapon(id,clip,ammo)

		if ( wpnid == CSW_KNIFE ) {
			switchmodel(id)
		}
		else if (wpnid == CSW_HEGRENADE )
		{
			entity_set_string(id,EV_SZ_viewmodel,"models/v_hegrenade.mdl")
			entity_set_string(id,EV_SZ_weaponmodel,"models/p_hegrenade.mdl")

		}
		else if ( wpnid == CSW_FLASHBANG )
		{
			entity_set_string(id,EV_SZ_viewmodel,"models/v_flashbang.mdl")
			entity_set_string(id,EV_SZ_weaponmodel,"models/p_flashbang.mdl")

		}
				else if ( wpnid == CSW_SMOKEGRENADE )
		{
			entity_set_string(id,EV_SZ_viewmodel,"models/v_smokegrenade.mdl")
			entity_set_string(id,EV_SZ_weaponmodel,"models/p_smokegrenade.mdl")

		}
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public switchmodel(id) {
	entity_set_string(id,EV_SZ_viewmodel,"models/v_egon.mdl")
	entity_set_string(id,EV_SZ_weaponmodel,"models/p_egon.mdl")
}

public remove_jetpacks() {
	new nextitem  = find_ent_by_class(-1,"zp_jp_jetpack")
	while(nextitem) {
		remove_entity(nextitem)
		nextitem = find_ent_by_class(-1,"zp_jp_jetpack")
	}
	return PLUGIN_CONTINUE
}

public emitsound(entity, channel, const sample[]) {
	if(is_user_alive(entity)) {

		if(hasjet[entity]) {
			if(equal(sample,"weapons/knife_slash1.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_slash2.wav")) return FMRES_SUPERCEDE

			if(equal(sample,"weapons/knife_deploy1.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hitwall1.wav")) return FMRES_SUPERCEDE

			if(equal(sample,"weapons/knife_hit1.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hit2.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hit3.wav")) return FMRES_SUPERCEDE
			if(equal(sample,"weapons/knife_hit4.wav")) return FMRES_SUPERCEDE

			if(equal(sample,"weapons/knife_stab.wav")) return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public human_fly(player) {

	if (g_flyEnergy[player] <= get_pcvar_num(cvar_fly_max_engery)*0.1)
	{
		jp_off(player);
	}
	if (g_flyEnergy[player] > get_pcvar_num(cvar_fly_max_engery)*0.1)
	{
		jp_on(player);
	}
}

public jp_on(player) {

	fly[player] = true

}

public jp_off(player) {

	fly[player] = false

}

public check_rocket(player) {

	if (last_Rocket[player] > gltime)
	{
		rk_forbidden(player)
		rksound[player] = true
	}
	else
	{

		if (shot[player])
		{
			rksound[player] = false
			shot[player] = false
		}
		rk_sound(player)
		rk_allow(player)
	}

}

public rk_allow(player) {

	rocket[player] = true
}

public rk_forbidden(player) {

	rocket[player] = false

}

public rk_sound(player) {

	if (!rksound[player])
	{
		engfunc(EngFunc_EmitSound, player, CHAN_WEAPON, getrocket, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_print(player, print_center, "")
		rksound[player] = true
	}
	else if (rksound[player])
	{

	}

}

public player_die() {

	new id = read_data(2)
	if(hasjet[id]) {
		drop_jetpack(id)
		hasjet[id] = 0
		rocket[id] = false
		g_flyEnergy[id] = 0
	}

	return PLUGIN_CONTINUE
}

public cmdDrop(id) {

	if(hasjet[id]) {
		new clip,ammo
		new weapon = get_user_weapon(id,clip,ammo)
		if(weapon == CSW_KNIFE) {
			drop_jetpack(id)
			if(!zp_get_user_zombie(id)){
				entity_set_string(id,EV_SZ_viewmodel,"models/v_knife.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/p_knife.mdl")
				}
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public drop_jetpack(player) {
	if(hasjet[player]) {
		new Float:Aim[3],Float:origin[3]
		VelocityByAim(player, 64, Aim)
		entity_get_vector(player,EV_VEC_origin,origin)

		origin[0] += Aim[0]
		origin[1] += Aim[1]

		new jetpack = create_entity("info_target")
		entity_set_string(jetpack,EV_SZ_classname,"zp_jp_jetpack")
		entity_set_model(jetpack,"models/p_egon.mdl")

		entity_set_size(jetpack,Float:{-16.0,-16.0,-16.0},Float:{16.0,16.0,16.0})
		entity_set_int(jetpack,EV_INT_solid,1)

		entity_set_int(jetpack,EV_INT_movetype,6)

		entity_set_vector(jetpack,EV_VEC_origin,origin)

		hasjet[player] = 0
		rocket[player] = false
	}
}

public pfn_touch(ptr, ptd) {
    if(is_valid_ent(ptr)) {
        new classname[32]
        entity_get_string(ptr,EV_SZ_classname,classname,31)

        if(equal(classname, "zp_jp_jetpack")) {
            if(is_valid_ent(ptd)) {
                new id = ptd
                if(id > 0 && id < 34) {
                    if(!hasjet[id] && !zp_get_user_zombie(id) && is_user_alive(id)) {

                        hasjet[id] = 1
                        //g_flyEnergy[id] = get_pcvar_num(cvar_fly_engery)
                        rocket[id] = true
                        client_cmd(id,"spk items/gunpickup2.wav")
                        engclient_cmd(id,"weapon_knife")
                        switchmodel(id)
                        remove_entity(ptr)
					}
				}
			}
		}else if(equal(classname, "zp_jp_rocket")) {
			new Float:fOrigin[3]
			new iOrigin[3]
			entity_get_vector(ptr, EV_VEC_origin, fOrigin)
			FVecIVec(fOrigin,iOrigin)
			jp_radius_damage(ptr)

			message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_EXPLOSION)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_short(explosion)
			write_byte(20)
			write_byte(15)
			write_byte(0)
			message_end()

                        message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_EXPLOSION)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_short(explosion)
			write_byte(30)
			write_byte(15)
			write_byte(0)
			message_end()

                        message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_EXPLOSION)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_short(explosion)
			write_byte(40)
			write_byte(15)
			write_byte(0)
			message_end()

			message_begin(MSG_ALL,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_BEAMCYLINDER)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2]+400)
			write_short(white)
			write_byte(0)
			write_byte(1)
			write_byte(6)
			write_byte(100)
			write_byte(1)
			write_byte(255)
			write_byte(255)
			write_byte(255)
			write_byte(100)
			write_byte(0)
			message_end()

                        message_begin(MSG_ALL,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_BEAMCYLINDER)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2]+400)
			write_short(white)
			write_byte(0)
			write_byte(1)
			write_byte(6)
			write_byte(100)
			write_byte(1)
			write_byte(255)
			write_byte(255)
			write_byte(255)
			write_byte(100)
			write_byte(0)
			message_end()

                        message_begin(MSG_ALL,SVC_TEMPENTITY,iOrigin)
			write_byte(TE_BEAMCYLINDER)
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2])
			write_coord(iOrigin[0])
			write_coord(iOrigin[1])
			write_coord(iOrigin[2]+400)
			write_short(white)
			write_byte(0)
			write_byte(1)
			write_byte(6)
			write_byte(100)
			write_byte(1)
			write_byte(255)
			write_byte(255)
			write_byte(255)
			write_byte(100)
			write_byte(0)
			message_end()

			if(is_valid_ent(ptd)) {
				new classname2[32]
				entity_get_string(ptd,EV_SZ_classname,classname2,31)

				if(equal(classname2,"func_breakable"))
					force_use(ptr,ptd)
			}

			remove_entity(ptr)
		}
	}
	return PLUGIN_CONTINUE
}

public zp_user_infected_pre(player, infector){


	drop_jetpack(player)
	hasjet[player] = 0
	rocket[player] = true
	g_flyEnergy[player] = get_pcvar_num(cvar_fly_max_engery)
	last_Rocket[player] = 0.0
}

public zp_extra_item_selected(player, itemid){


	new clip,ammo
	new weapon = get_user_weapon(player,clip,ammo)
         new name[32]
         get_user_name(player, name, 31)




	if (itemid == g_item_jetpack)
	{

		if(!g_buyabletime)
		{
		ColorChat(player,GREEN, "^x04[ZP]^x01 Please Wait ...")
		return
		}

		if(!hasjet[player])
		{
		set_hudmessage(205, 102, 29, -1.00, 0.80, 1, 0.00, 3.00, 2.00, 1.00, -1);
        ShowSyncHudMsg(0,g_iEventsHudmessage, "%s bought a Jetpack!!", name)
		ColorChat(player, GREY, "^x04[ZP]^x01 ^x01Press ^x03-CTRL+SPACE-^x01 to fly!", "green")
		ColorChat(player, GREY, "^x04[ZP]^x01 ^x01Press ^x03-RIGHT CLICK-^x01 to shoot!", "green")
		}

		cmdDrop(player)

		hasjet[player] = 1
		g_flyEnergy[player] = get_pcvar_num(cvar_fly_max_engery)
		rocket[player] = true
		last_Rocket[player] = 0.0
		client_cmd(player,"spk items/gunpickup2.wav")
		if(weapon == CSW_KNIFE){
			switchmodel(player)
		}
		else
		{
			engclient_cmd(player,"weapon_knife"),switchmodel(player)
		}
	}
}


stock jp_radius_damage(entity) {
	new id = entity_get_edict(entity,EV_ENT_owner)
	new packs,name[32];
	for(new i = 1; i < 33; i++) {
		if(is_user_alive(i)) {
			new dist = floatround(entity_range(entity,i))

			if(dist <= get_pcvar_num(cvar_Dmg_range)) {
				new hp = get_user_health(i)
				new damage

				if(zp_get_user_sniper(id))
				damage= get_pcvar_num(cvar_SniperDmg)
				else
				damage = floatround(get_pcvar_num(cvar_RocketDmg)-(get_pcvar_float(cvar_RocketDmg)/get_pcvar_float(cvar_Dmg_range))*float(dist))



				new Origin[3]
				get_user_origin(i,Origin)
				new iPos = ++g_iPlayerPos[id]
				if( iPos == sizeof(g_flCoords) )
			{
				iPos = g_iPlayerPos[id] = 0
			}

				if(zp_get_user_zombie(id) != zp_get_user_zombie(i)) {
						get_user_name(i,name,31);

						if(!zp_get_user_sniper(id))
						if(damage>=800)
							packs = 2;
						else
							packs = 1;

						if(hp > damage)
						{

							zp_set_user_ammo_packs ( id, zp_get_user_ammo_packs ( id ) + packs );
							jp_take_damage(i,damage,Origin,DMG_BLAST)
							ColorChat(id, GREY, "^x04[ZP]^x01 Damage to ^x04%s^x01 ::  ^x04%i^x01 damage", name, damage)

							set_hudmessage( 0, 40, 80, Float:g_flCoords[iPos][0], Float:g_flCoords[iPos][1], 0, 0.1, 2.5, 0.02, 0.02, -1 )
							show_hudmessage( id, "%i", damage )

						}
						else
						{
							log_kill(id,i,"Jetpack Rocket",0)
							zp_set_user_ammo_packs ( id, zp_get_user_ammo_packs ( id ) + 4 );
						}
					}
			}
		}
	}
}

stock log_kill(killer, victim, weapon[], headshot)
{
// code from MeRcyLeZZ
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, killer, 2) // set last param to 2 if you want victim to gib
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)


	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(killer)
	write_byte(victim)
	write_byte(headshot)
	write_string(weapon)
	message_end()
//

	if(get_user_team(killer)!=get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) +1)
	if(get_user_team(killer)==get_user_team(victim))
		set_user_frags(killer,get_user_frags(killer) -1)

	new kname[32], vname[32], kauthid[32], vauthid[32], kteam[10], vteam[10]

	get_user_name(killer, kname, 31)
	get_user_team(killer, kteam, 9)
	get_user_authid(killer, kauthid, 31)

	get_user_name(victim, vname, 31)
	get_user_team(victim, vteam, 9)
	get_user_authid(victim, vauthid, 31)

	log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"",
	kname, get_user_userid(killer), kauthid, kteam,
 	vname, get_user_userid(victim), vauthid, vteam, weapon)

 	return PLUGIN_CONTINUE;
}

stock jp_take_damage(victim,damage,origin[3],bit) {
    message_begin(MSG_ONE,get_user_msgid("Damage"),{0,0,0},victim)
    write_byte(21)
    write_byte(20)
    write_long(bit)
    write_coord(origin[0])
    write_coord(origin[1])
    write_coord(origin[2])
    message_end()

    set_user_health(victim,get_user_health(victim)-damage)
        client_cmd(victim,"spk fvox/flatline.wav")
        msg_screen_fade(victim, 1, 255, 0, 0, 115)
        msg_screen_shake( victim, 255<<10, 10<<10, 255<<10 );
}

stock msg_screen_fade(id, holdtime, r, g, b, a)
{
        message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0, 0, 0}, id)
        write_short(seconds_to_units(holdtime))
        write_short(seconds_to_units(holdtime))
        write_short(0)
        write_byte(r)
        write_byte(g)
        write_byte(b)
        write_byte(a)
        message_end()
}

stock seconds_to_units(time) {
        return ((1 << 10) * (time))
}

public msg_screen_shake( id,  Amplitud ,  Duracion, Frecuencia  ){

    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), {0,0,0}, id);
    write_short(255<<10);
    write_short(10<<10);
    write_short(255<<10);
    message_end()

}








public cmdJetpack(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new name2[32],  name[32]

	static arg[32], player
	read_argv(1, arg, 31)

	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE))


	if (!player)
	return PLUGIN_HANDLED



	new clip,ammo
	new weapon = get_user_weapon(player,clip,ammo)


		cmdDrop(player)

		hasjet[player] = 1
		g_flyEnergy[player] = get_pcvar_num(cvar_fly_max_engery)
		last_Rocket[player] = 0.0;
		rocket[player]=true
		client_cmd(player,"spk items/gunpickup2.wav")
		if(weapon == CSW_KNIFE){
			switchmodel(player)
		}
		else
		{
			engclient_cmd(player,"weapon_knife"),switchmodel(player)
		}




	get_user_name(id, name, 31)
	get_user_name(player, name2, 31)

	if (player == id)
	{
	ColorChat(0, GREY, "^4[ZP] ^3%s^1 Gave ^3Himself^1 A ^4Jetpack^1!", name);
	}
	else
	ColorChat(0, GREY, "^4[ZP] ^3%s^1 Gave ^3%s^1 A ^4Jetpack^1!", name, name2);

	return PLUGIN_HANDLED
}




public cmdDropJetpack(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new name2[32],  name[32]

	static arg[32], player
	read_argv(1, arg, 31)

	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE))

	if (!player)
		return PLUGIN_HANDLED

	cmdDrop(player);
	hasjet[player] = 0


	set_pev(player, pev_viewmodel2, "models/v_knife.mdl")
	set_pev(player, pev_weaponmodel2, "models/p_knife.mdl")

	get_user_name(id, name, 31)
	get_user_name(player, name2, 31)


	ColorChat(0, GREY, "^1[ZP] ^4%s^1 Removed ^4%s^1 ^3Jetpack^1 !", name, name2);

	return PLUGIN_HANDLED
}












public regain_dropped()
{

new ii

for(ii=0;ii<32;ii++)
{
	if(!hasjet[ii] && !zp_get_user_zombie(ii) && g_flyEnergy[ii] < get_pcvar_num(cvar_fly_max_engery))
	{
		g_flyEnergy[ii] = g_flyEnergy[ii] + get_pcvar_num(cvar_regain_energy);

    }
}

	set_task(get_pcvar_float(cvar_cal_time),"regain_dropped")

}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1030\\ f0\\ fs16 \n\\ par }
*/
