#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>

#define VERSION "1.2"

native cs_get_weapon_id(index);
native cs_set_user_bpammo(index, weapon, amount);
native cs_get_user_bpammo(index, weapon);
native give_item(index, const item[]);
native set_user_health(index, health);

/*
Toxic Air Bomb
Trown a Toxic Air Bomb
*/

// Ignore it my Pawn Studio not can see dmg LOL, manualy need added
#define DMG_GENERIC                     0           // Generic damage was done
#define DMG_CRUSH                       (1<<0)      // Crushed by falling or moving object
#define DMG_BULLET                      (1<<1)      // Shot
#define DMG_SLASH                       (1<<2)      // Cut, clawed, stabbed
#define DMG_BURN                        (1<<3)      // Heat burned
#define DMG_FREEZE                      (1<<4)      // Frozen
#define DMG_FALL                        (1<<5)      // Fell too far
#define DMG_BLAST                       (1<<6)      // Explosive blast damage
#define DMG_CLUB                        (1<<7)      // Crowbar, punch, headbutt
#define DMG_SHOCK                       (1<<8)      // Electric shock
#define DMG_SONIC                       (1<<9)      // Sound pulse shockwave
#define DMG_ENERGYBEAM                  (1<<10)     // Laser or other high energy beam
#define DMG_NEVERGIB                    (1<<12)     // With this bit OR'd in, no damage type will be able to gib victims upon death
#define DMG_ALWAYSGIB                   (1<<13)     // With this bit OR'd in, any damage type can be made to gib victims upon death.
#define DMG_DROWN                       (1<<14)     // Drowning
#define DMG_PARALYZE                    (1<<15)     // Slows affected creature down
#define DMG_NERVEGAS                    (1<<16)     // Nerve toxins, very bad
#define DMG_POISON                      (1<<17)     // Blood poisioning
#define DMG_RADIATION                   (1<<18)     // Radiation exposure
#define DMG_DROWNRECOVER                (1<<19)     // Drowning recovery
#define DMG_ACID                        (1<<20)     // Toxic chemicals or acid burns
#define DMG_SLOWBURN                    (1<<21)     // In an oven
#define DMG_SLOWFREEZE                  (1<<22)     // In a subzero freezer
#define DMG_MORTAR                      (1<<23)     // Hit by air raid (done to distinguish grenade from mortar)
#define DMG_TIMEBASED                   (~(0x3fff)) // Mask for time-based damage

new const zombiebomb[3][] = { "models/toxicbomb/v_zombibomb-s.mdl", "models/toxicbomb/p_zombibomb.mdl", "models/toxicbomb/w_zombibomb.mdl" };
new const sprtoxicbomb[] = "sprites/toxicbomb/gas_puff_01g.spr"
new const sound_buyammo[] = "items/9mmclip1.wav"
new const toxic_sound[] = "fans/fan5.wav"


new g_szSmokeSprites, g_ToxicAir, g_ToxicDmg, g_ToxicTyp, g_ToxicRad, g_ToxicTim, g_ToxicTim2
new g_currentweapon[33], g_HasToxic[33] = false, g_ClearData = false

// HACK: pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_TOXIC = 1290

// CS Weapon CBase Offsets (win32)
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

// Message IDs vars
new g_msgAmmoPickup

const TASK_TOXIC = 1

#define ID_TASK_TOXIC (taskid - TASK_TOXIC)

public plugin_init()
{
	// New plugin
	register_plugin("Extra Item: Toxic Air", VERSION, "bogdyutzu & Night Dreamer");

	// Game-Monitor support
	register_cvar("TOXIC_AIR_VERSION",    VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	set_cvar_string("TOXIC_AIR_VERSION",    VERSION);

	// Cvars
	g_ToxicTyp = register_cvar("toxic_air_type","1")
	g_ToxicDmg = register_cvar("toxic_air_damage","20")
	g_ToxicRad = register_cvar("toxic_air_radius","150")
	g_ToxicTim = register_cvar("toxic_air_time_dmg","24")
	g_ToxicTim2 = register_cvar("toxic_air_take_dmg","1")
	g_ToxicAir = zp_register_extra_item("\r[\yZP\r]\yToxic Bomb", 5, ZP_TEAM_ZOMBIE)

	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	// FM Forwards
	register_forward(FM_SetModel, "fw_SetModel", 1)

	// Message IDs
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")

	// HAM Forwards
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "fw_Item_Deploy_Post", 1)
}

public plugin_precache( )
{
	g_szSmokeSprites = precache_model( sprtoxicbomb );
	engfunc(EngFunc_PrecacheSound, sound_buyammo)
	engfunc(EngFunc_PrecacheSound, toxic_sound)
	for (new i = 0; i < sizeof zombiebomb; i++)
		engfunc(EngFunc_PrecacheModel, zombiebomb[i])
}

public event_round_start()
{
	g_ClearData = true
}

public Cleat_Type(taskid)
{
	new id = ID_TASK_TOXIC
	remove_task(id+TASK_TOXIC) //force it to remove task
	if(pev_valid(id))
		engfunc(EngFunc_RemoveEntity, id) // Get rid of the grenade
}

public zp_round_started()
{
	g_ClearData = false
}

// Buy an extra item
public zp_extra_item_selected(id, Item)
{
	if(Item == g_ToxicAir)
	{
		// Already own one
		if (user_has_weapon(id, CSW_SMOKEGRENADE))
		{
			// Increase BP ammo on it instead
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, cs_get_user_bpammo(id, CSW_SMOKEGRENADE) + 1)

			// Flash ammo in hud
			message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
			write_byte(13) // ammo id
			write_byte(1) // ammo amount
			message_end()

			// Play clip purchase sound
			emit_sound(id, CHAN_ITEM, sound_buyammo, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

			return; // stop here
		}

		// Give weapon to the player
		give_item(id, "weapon_smokegrenade")
	}
}

public fw_Item_Deploy_Post(weapon_ent)
{
	// Get weapon's owner
	static owner
	owner = get_pdata_cbase(weapon_ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);

	// Get weapon's id
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)

	// Store current weapon's id for reference
	g_currentweapon[owner] = weaponid

	if(!zp_get_user_zombie(owner))
		return HAM_IGNORED;

	if(g_currentweapon[owner] == CSW_SMOKEGRENADE)
	{
		set_pev(owner,pev_viewmodel2,zombiebomb[0])
		set_pev(owner,pev_weaponmodel2,zombiebomb[1])
	}

	return HAM_IGNORED;
}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return;

	// Narrow down our matches a bit
	if (model[7] != 'w' || model[8] != '_')
		return;

	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)

	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return;

	static owner
	owner = pev(entity, pev_owner)
	// Get whether grenade's owner is a zombie
	if (zp_get_user_zombie(owner))
	{
		if (model[9] == 's' && model[10] == 'm') // Flare
		{
			// Set grenade type on the thrown grenade entity
			set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_TOXIC )
			engfunc(EngFunc_SetModel, entity, zombiebomb[2])
			//set_pev(entity, pev_model, zombiebomb[2])
		}
	}
}

// Ham Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;

	// Get damage time of grenade
	static Float:dmgtime, Float:current_time
	pev(entity, pev_dmgtime, dmgtime)
	current_time = get_gametime()

	// Check if it's time to go off
	if (dmgtime > current_time)
		return HAM_IGNORED;

	// Check if it's one of our custom nades
	if((pev(entity, PEV_NADE_TYPE)) == NADE_TYPE_TOXIC)
	{
		if (zp_has_round_started())
		{
			new params[1]
			params[0] = entity
			new Float:rooood = random_float(0.1, 0.7)
			static Float:time, Float:time2
			time = get_pcvar_float(g_ToxicTim) + rooood
			time2 = get_pcvar_float(g_ToxicTim2) + rooood
			set_task(time, "Cleat_Type", entity+TASK_TOXIC)
			set_task(time/(time-4), "toxic_explozion", entity+TASK_TOXIC, _, _, "b")
			set_task(time2, "toxic_damage", entity+TASK_TOXIC, params, sizeof params, "b")
		}
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public zp_user_infect_attempt(id, infector)
{
	if(g_HasToxic[id])
	{
		//client_cmd(id, "nu il pot infecta pe %d. Cel care il infecteaza e%d :O", id,infector)
		//client_cmd(infector, "nu il pot infecta pe %d. Cel care il infecteaza e%d :O", id,infector)
		return ZP_PLUGIN_HANDLED//return PLUGIN_HANDLED
	}
	//else
	//	return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public toxic_damage(taskid, args[1])
{
	new id = ID_TASK_TOXIC

	if(g_ClearData)
	{
		remove_task(id+TASK_TOXIC), g_ClearData = false
		return
	}

	// Invalid entity
	if (!pev_valid(id)) return

	static owner
	owner = pev(id, pev_owner)

	// Get it's origin
	static Float:originF[ 3 ]
	pev(id, pev_origin, originF )

	// Get radius
	static radius
	radius = get_pcvar_num(g_ToxicRad)

	// Collisions
	static victim
	victim = -1
	while ( ( victim = engfunc( EngFunc_FindEntityInSphere, victim, originF, float(radius) ) ) != 0 )
	{
		// Only effect alive zombies
		if ( !is_user_alive ( victim ) || zp_get_user_zombie ( victim ))
			continue;

		static hp
		hp = pev(victim, pev_health)
		static damage
		damage = get_pcvar_num(g_ToxicDmg)+random(5)-random(5)

		if(get_pcvar_num(g_ToxicTyp))
		{
			if(hp >= damage || zp_get_user_last_human(victim))
				g_HasToxic[victim] = true
			//client_print(victim, print_chat, "tu esti sau nu esti %d", zp_get_user_last_human(victim))
			ExecuteHamB(Ham_TakeDamage, victim, args[0], owner, float(damage), DMG_NERVEGAS)
			g_HasToxic[victim] = false
		}
		else
		{
			g_HasToxic[victim] = true
			ExecuteHamB(Ham_TakeDamage, victim, args[0], owner, float(damage), DMG_NERVEGAS)
			g_HasToxic[victim] = false
		}
	}
}

public toxic_explozion(taskid)
{
	new id = ID_TASK_TOXIC

	if(g_ClearData)
	{
		remove_task(id+TASK_TOXIC), g_ClearData = false
		return
	}

	// Invalid entity
	if (!pev_valid(id)) return

	static Float:originF[3]
	pev(id, pev_origin, originF)

	// Get some cvars
	static radius, radius2, time
	radius = get_pcvar_num(g_ToxicRad) //150
	radius2 = radius-50
	time = (get_pcvar_num(g_ToxicTim)/2+10) //24

	//message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte( TE_FIREFIELD );
	engfunc( EngFunc_WriteCoord, originF[ 0 ] );
	engfunc( EngFunc_WriteCoord, originF[ 1 ] );
	engfunc( EngFunc_WriteCoord, originF[ 2 ] + 50 );
	write_short( radius2 );
	write_short( g_szSmokeSprites );
	write_byte( 100 );
	write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT | TEFIRE_FLAG_LOOP );
	write_byte( time );
	message_end();

	//message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte( TE_FIREFIELD );
	engfunc( EngFunc_WriteCoord, originF[ 0 ] );
	engfunc( EngFunc_WriteCoord, originF[ 1 ] );
	engfunc( EngFunc_WriteCoord, originF[ 2 ] + 50 );
	write_short( radius );
	write_short( g_szSmokeSprites );
	write_byte( 10 );
	write_byte( TEFIRE_FLAG_ALPHA | TEFIRE_FLAG_SOMEFLOAT | TEFIRE_FLAG_LOOP );
	write_byte( time );
	message_end( );
}
