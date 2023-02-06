// Credite: Aragon pentru countdown putere (furien30_ultimates) & Dias Leon pentru AvalancheFrost

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <cstrike>
#include <dhudmessage>
#include <biohazard>

#define PLUGIN_NAME	"[BIO] Class: Frosty"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"TEST"

#define TASK_DELAY 	21249

new const TAG[] = "[Biohazard]";

new g_PowerDelay[33], g_PowerIsUsed[33], class;

// -------------------------
// AVALANCHE FROST
// -------------------------

#define MODEL_ICEBLOCK "models/biohazard/frosty/avfrost_iceblock.mdl"

#define SOUND_EXPLOSION "biohazard/frosty/frostnova.wav"
#define SOUND_HIT "biohazard/frosty/impalehit.wav"
#define SOUND_RELEASE "biohazard/frosty/impalelaunch1.wav"

#define FROST_RADIUS		200.0	// raza 
#define FROST_HOLDTIME		3.0	// cat timp sa fie inghetat
#define POWER_COOLDOWN		50	// la cate secunde sa refolosesti puterea

new const Float:NOVA_COLOR[3] = {0.0, 127.0, 255.0}

#define TASK_HOLD 212015

new g_IsFrozen[33], Float:g_FrozenOrigin[33][3], g_MyNova[33]
new g_Exp_SprID, g_Ball_SprID, g_Flame_SprID
new g_GlassGib_SprID
new g_MaxPlayers;

// -------------------------
// AVALANCHE FROST
// -------------------------

// ----------------------------
// INREGISTRARE CLASA
// ----------------------------
#define ZOMBIE_NAME 	"Zombie Frost [Freeze]"     	// Zombie Name
#define ZOMBIE_DESC 	"Can freeze players Press [G]"	// Zombie Description
#define DEFAULT_PMODEL	"models/player/ultimate_frostgirl/ultimate_frostgirl.mdl"	// Zombie Model
#define DEFAULT_WMODEL	"models/player/ultimate_frostgirl/ultimate_claws.mdl"	// Claws Model
#define ZOMBIE_HEALTH		250.0	// Health value
#define ZOMBIE_SPEED		300.0	// Speed value
#define ZOMBIE_GRAVITY		0.90	// Gravity multiplier
#define ZOMBIE_ATTACK		2.5	// Zombie damage multiplier
#define ZOMBIE_REGENDLY		0.1	// LA CATE SECUNDE REGENEREAZA 1 HP
#define ZOMBIE_HITREGENDLY	2.0	// LA CATE SECUNDE DUPA CE PRIMESTE DAUNE VA INCEPE REGENERAREA
#define ZOMBIE_KNOCKBACK	2.0	// Knockback multiplier
// ----------------------------
// INREGISTRARE CLASA
// ----------------------------

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	register_clcmd("drop", "cmd_power");
	
	register_event("DeathMsg", "event_DeathMsg", "a");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1);
	
	g_MaxPlayers = get_maxplayers()

}

public plugin_precache()
{
	// Frost Nave
	precache_model(MODEL_ICEBLOCK)
	
	precache_sound(SOUND_EXPLOSION)
	precache_sound(SOUND_HIT)
	precache_sound(SOUND_RELEASE)
                precache_model(DEFAULT_PMODEL)
                precache_model(DEFAULT_WMODEL)
	
	// Cache
	g_Exp_SprID = precache_model("sprites/shockwave.spr")
	g_Ball_SprID = precache_model("sprites/biohazard/frosty/blueball.spr")
	g_Flame_SprID = precache_model("sprites/biohazard/frosty/blueflame.spr")
	g_GlassGib_SprID = precache_model("models/glassgibs.mdl")

                class = register_class(ZOMBIE_NAME, ZOMBIE_DESC)
                set_class_pmodel(class, DEFAULT_PMODEL)
                set_class_wmodel(class, DEFAULT_WMODEL)
                set_class_data(class, DATA_HEALTH, ZOMBIE_HEALTH);
                set_class_data(class, DATA_SPEED, ZOMBIE_SPEED);
                set_class_data(class, DATA_GRAVITY, ZOMBIE_GRAVITY);
                set_class_data(class, DATA_ATTACK, ZOMBIE_ATTACK);
                set_class_data(class, DATA_REGENDLY, ZOMBIE_REGENDLY);
                //set_class_data(class, DATA_HITREGENDLY, ZOMBIE_HITREGENDLY);
                set_class_data(class, DATA_KNOCKBACK, ZOMBIE_KNOCKBACK);

}

public fw_PlayerSpawn(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	if(!is_user_zombie(id))
		set_user_rendering(id);

	return PLUGIN_CONTINUE;
}

public event_DeathMsg()
{
	new victim = read_data(2)

	if(is_user_connected(victim) && is_user_zombie(victim) && get_user_class(victim) == class)
	{
		PowerReset(victim);
	
		if(g_IsFrozen[victim])
			Release_Player(victim+TASK_HOLD)
	}
}

public event_infect(id)
{
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == class)
	{	
		task_exists(TASK_DELAY + id) ? remove_task(TASK_DELAY + id) : 0;	
		
		g_PowerDelay[id] = 0;

		if(!g_PowerDelay[id])	// nu modifica
			g_PowerDelay[id] = 3;//get_pcvar_num(cvar_power_countdown);
			
		if(!task_exists(id + TASK_DELAY))
			PowerDelay(id);
	}
}

public cmd_power(id)
{
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == class)
	{
		set_dhudmessage(0, 255, 255, -1.0, 0.88, 0, _, 1.0);

		if(g_PowerDelay[id] > 0 || g_PowerIsUsed[id])
		{
			show_dhudmessage(id, "Charging.^n(%d second%s left)", g_PowerDelay[id], g_PowerDelay[id] == 1 ? "a" : "e");
		}
		else
		{
			PowerWizard(id);
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public PowerDelay(id)
{
	if(id >= TASK_DELAY)
		id -= TASK_DELAY;
	
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == class)
	{
		if(g_PowerDelay[id] > 1)
		{
			g_PowerDelay[id]--;
			set_task(1.0, "PowerDelay", id+TASK_DELAY);
		}
		else if(g_PowerDelay[id] <= 1)
		{
			g_PowerDelay[id] = 0;
			
			set_dhudmessage(255, 255, 0, -1.0, 0.88, 0, _, 2.0);
			show_dhudmessage(id, "Frost Power is Ready.^nPress G to use it.");
		}
	}
}

public PowerReset(id)
{
	task_exists(TASK_DELAY + id) ? remove_task(TASK_DELAY + id) : 0;
	
	g_PowerDelay[id] = 0;
}

public PowerWizard(id)
{
	if(is_user_connected(id) && is_user_zombie(id) && get_user_class(id) == class)
	{
		g_PowerDelay[id] = POWER_COOLDOWN;//get_pcvar_num(cvar_power_countdown);
		PowerDelay(id);

		new target, body;
		static Float:StartPos[3], Float:EndPos[3];
	
		pev(id, pev_origin, StartPos);
		fm_get_aim_origin(id, EndPos);
		
		StartPos[2] += 16.0;
		EndPos[2] += 16.0;
		get_user_aiming(id, target, body, 90000);
		
		//if(cs_get_user_team(id) != cs_get_user_team(target))
		if(!is_user_zombie(target))
		{
			if(is_user_alive(target))
			{
				AvalancheFrost_Explosion(id, target);
				ColorChat(target, "!4%s!1 You are frosted! You can't shot or move for !3 %1.f sec!1.", TAG, FROST_HOLDTIME);
				
				if(!target)
				{
					set_dhudmessage(id, 255, 0, -1.0, 0.6, 0);
					show_dhudmessage(id, "You missed the target.^nTry again.");
					PowerReset(id);
				}
				else
				{
					ColorChat(id, "!4%s!1 You've frosted the target !3 %s!1.", TAG, get_name(target));
					ShakeScreen(id, 2.0);
				}
			}
		}
		else
		{
			set_dhudmessage(id, 255, 0, -1.0, 0.6, 0);
			show_dhudmessage(id, "You can't Freeze your teamates.");
			PowerReset(id);
		}
		
	}
}

public client_PreThink(id)
{	
	if(!is_user_alive(id))
		return
	if(!g_IsFrozen[id])
		return
	
	// il oprim sa mai traga
	entity_set_int(id, EV_INT_button, entity_get_int(id, EV_INT_button) & ~IN_ATTACK);

	static Float:Origin[3]; pev(id, pev_origin, Origin)
	if(get_distance_f(Origin, g_FrozenOrigin[id]) > 8.0)
		HookEnt(id, g_FrozenOrigin[id], 50.0)
}

public ShakeScreen(id, const Float:iSeconds)
{
	static g_msg_SS = 0;
	if(!g_msg_SS)
		g_msg_SS = get_user_msgid("ScreenShake");
	
	message_begin(MSG_ONE, g_msg_SS, _, id);
	write_short(floatround(4096.0 * iSeconds, floatround_round));
	write_short(floatround(4096.0 * iSeconds, floatround_round));
	write_short(1<<13);
	message_end();
}

stock get_name(id)
{
	new name[32];
	get_user_name(id, name, charsmax(name));
	return name;
}

stock fm_get_aim_origin(id, Float:fOrigin[3])
{
	new Float:start[3], Float:view_ofs[3];
	pev(id, pev_origin, start);
	pev(id, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	
	new Float:dest[3];
	pev(id, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);
	
	engfunc(EngFunc_TraceLine, start, dest, 0, id, 0);
	get_tr2(0, TR_vecEndPos, fOrigin);
	
	return PLUGIN_HANDLED;
}

// AVALANCHE FROST
public AvalancheFrost_Explosion(id, target)
{
	static Float:Origin[3];
	pev(target, pev_origin, Origin)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Flame_SprID)	// sprite index
	write_byte(15)	// scale in 0.1's
	write_byte(20)	// framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND)	// flags
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 50)
	write_short(g_Ball_SprID) // (sprite index)
	write_byte(25) // (count)
	write_byte(random_num(2, 5)) // (life in 0.1's)
	write_byte(5) // byte (scale in 0.1's)
	write_byte(random_num(10, 50)) // (velocity along vector in 10's)
	write_byte(5) // (randomness of velocity in 10's)
	message_end()
	
	static RGB[3];
	FVecIVec(NOVA_COLOR, RGB)
	Effect_Ring(Origin, g_Exp_SprID, RGB, FROST_RADIUS)
	
	emit_sound(target, CHAN_BODY, SOUND_EXPLOSION, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// Check Affect
	static Float:Origin2[3]
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i) || id == i || is_user_zombie(i)/*cs_get_user_team(target) != cs_get_user_team(i)*/ || entity_range(target, i) > FROST_RADIUS)
			continue
		
		pev(i, pev_origin, Origin2)
		if(is_wall_between_points(Origin, Origin2, 0))
			continue
		
		emit_sound(i, CHAN_ITEM, SOUND_HIT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		Freeze_Player(i)
	}
}

public Freeze_Player(id)
{
	if(g_IsFrozen[id])
	{
		// Hold Time
		remove_task(id+TASK_HOLD)
		set_task(FROST_HOLDTIME + random_float(-0.5, 1.0), "Release_Player", id+TASK_HOLD)
		
		return
	}
	
	// Stop
	set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})
	
	pev(id, pev_origin, g_FrozenOrigin[id])
	g_IsFrozen[id] = 1;
	
	// Effect
	static RGB[3]; FVecIVec(NOVA_COLOR, RGB)
	set_user_rendering(id, kRenderFxGlowShell, RGB[0], RGB[1], RGB[2], kRenderNormal, 1);
	Create_ICEBlock(id)
	
	// Hold Time
	remove_task(id+TASK_HOLD)
	set_task(FROST_HOLDTIME + random_float(-0.5, 1.0), "Release_Player", id+TASK_HOLD)
}

public Create_ICEBlock(id)
{
	static NOVA;
	NOVA = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

	engfunc(EngFunc_SetSize, NOVA, Float:{-16.0, -16.0, -36.0},Float:{16.0, 16.0, 36.0});
	engfunc(EngFunc_SetModel, NOVA, MODEL_ICEBLOCK)

	static Float:Angles[3]
	Angles[1] = random_float(0.0, 360.0)
	set_pev(NOVA, pev_angles, Angles)

	static Float:NovaOrigin[3]
	pev(id, pev_origin, NovaOrigin)
	NovaOrigin[2] -= 36.0
	engfunc(EngFunc_SetOrigin, NOVA, NovaOrigin)

	set_pev(NOVA, pev_rendercolor, NOVA_COLOR)
	set_pev(NOVA, pev_rendermode, kRenderTransAlpha)
	set_pev(NOVA, pev_renderfx, kRenderFxGlowShell)
	set_pev(NOVA, pev_renderamt, 128.0)

	g_MyNova[id] = NOVA
}

public Release_Player(id)
{
	id -= TASK_HOLD
	
	if(!is_user_connected(id))
		return
		
	g_IsFrozen[id] = 0;
	if(!is_user_zombie(id)) set_user_rendering(id)
	
	// Effect
	static Float:Origin[3];
	pev(id, pev_origin, Origin)

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_IMPLOSION);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 8.0)
	write_byte(64)
	write_byte(10)
	write_byte(3)
	message_end()

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	message_end();

	// add the shatter
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 24.0)
	engfunc(EngFunc_WriteCoord, 16.0)
	engfunc(EngFunc_WriteCoord, 16.0)
	engfunc(EngFunc_WriteCoord, 16.0)
	write_coord(random_num(-50,50)); // velocity x
	write_coord(random_num(-50,50)); // velocity y
	engfunc(EngFunc_WriteCoord, 25.0)
	write_byte(10); // random velocity
	write_short(g_GlassGib_SprID); // model
	write_byte(25); // count
	write_byte(25); // life
	write_byte(0x01/*BREAK_GLASS*/); // flags
	message_end();
	
	static RGB[3];
	FVecIVec(NOVA_COLOR, RGB)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 250.0)
	write_short(g_Exp_SprID); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(RGB[0]); // red
	write_byte(RGB[1]); // green
	write_byte(RGB[2]); // blue
	write_byte(250); // brightness
	write_byte(0); // speed
	message_end();
	
	// Sound
	emit_sound(id, CHAN_ITEM, SOUND_RELEASE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// Remove Effect
	if(pev_valid(g_MyNova[id]))
		set_pev(g_MyNova[id], pev_flags, pev(g_MyNova[id], pev_flags) | FL_KILLME)
}

stock HookEnt(Ent, Float:VicOrigin[3], Float:Speed)
{
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	pev(Ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / Speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(Ent, pev_velocity, fl_Velocity)
}

public Effect_Ring(Float:Origin[3], SpriteID, RGB[3], Float:Radius)
{
	// smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 500.0)
	write_short(SpriteID); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(RGB[0]); // red
	write_byte(RGB[1]); // green
	write_byte(RGB[2]); // blue
	write_byte(250); // brightness
	write_byte(0); // speed
	message_end();

	// medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 750.0)
	write_short(SpriteID); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(RGB[0]); // red
	write_byte(RGB[1]); // green
	write_byte(RGB[2]); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();

	// largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 1000.0)
	write_short(SpriteID); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(RGB[0]); // red
	write_byte(RGB[1]); // green
	write_byte(RGB[2]); // blue
	write_byte(150); // brightness
	write_byte(0); // speed
	message_end();

	// light effect
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(floatround(Radius/5.0)); // radius
	write_byte(RGB[0]); // r
	write_byte(RGB[1]); // g
	write_byte(RGB[2]); // b
	write_byte(8); // life
	write_byte(60); // decay rate
	message_end();
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 

stock ColorChat(id, String[], any:...) 
{
	static szMesage[192];
	vformat(szMesage, charsmax(szMesage), String, 3);
	
	replace_all(szMesage, charsmax(szMesage), "!1", "^1");
	replace_all(szMesage, charsmax(szMesage), "!3", "^3");
	replace_all(szMesage, charsmax(szMesage), "!4", "^4");
	
	static g_msg_SayText = 0;
	if(!g_msg_SayText)
		g_msg_SayText = get_user_msgid("SayText");
	
	new Players[32], iNum = 1, i;
	
	if(id) Players[0] = id;
	else get_players(Players, iNum, "ch");
	
	for(--iNum; iNum >= 0; iNum--) 
	{
		i = Players[iNum];
		
		message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i);
		write_byte(i);
		write_string(szMesage);
		message_end();
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
