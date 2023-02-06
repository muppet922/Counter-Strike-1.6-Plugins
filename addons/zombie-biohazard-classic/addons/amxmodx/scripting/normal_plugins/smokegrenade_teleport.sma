/* AMX Mod X
*   Teleport Smoke Grenade
*
* (c) Copyright 2006 by VEN
*
* This file is provided as is (no warranties)
*
*     DESCRIPTION
*       Plugin changes the smoke grenade to teleport grenade with a bit of smoke.
*       Usage: drop the grenade, you will be teleported to the spot of explosion.
*       Try to crouch if the height of the spot are small for uncrouched player.
*
*     CREDITS
*       Dread Pirate - idea
*/

#include <amxmodx>
#include <biohazard>
#include <fakemeta>

#define PLUGIN_NAME "Teleport Smoke Grenade"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "TEST"

#define SMOKE_SCALE 30
#define SMOKE_FRAMERATE 12
#define SMOKE_GROUND_OFFSET 6

// do not edit
new const g_sound_explosion[] = "weapons/sg_explode.wav"
new const g_classname_grenade[] = "grenade"

new const Float:g_sign[4][2] = {{1.0, 1.0}, {1.0, -1.0}, {-1.0, -1.0}, {-1.0, 1.0}}

new g_spriteid_steam1
new g_eventid_createsmoke

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	register_forward(FM_EmitSound, "forward_emitsound")
	register_forward(FM_PlaybackEvent, "forward_playbackevent")

	// we do not precaching, but retrieving the indexes
	g_spriteid_steam1 = engfunc(EngFunc_PrecacheModel, "sprites/steam1.spr")
	g_eventid_createsmoke = engfunc(EngFunc_PrecacheEvent, 1, "events/createsmoke.sc")
}

public forward_emitsound(ent, channel, const sound[]) {
	if (!equal(sound, g_sound_explosion) || !is_grenade(ent))
		return FMRES_IGNORED

	static id, Float:origin[3]
	id = pev(ent, pev_owner)
	pev(ent, pev_origin, origin)
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, g_sound_explosion, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_SetOrigin, ent, Float:{8191.0, 8191.0, 8191.0})
	origin[2] += SMOKE_GROUND_OFFSET
	create_smoke(origin)

	if (is_user_alive(id) && !is_user_zombie(id)) {
		static Float:mins[3], hull
		pev(id, pev_mins, mins)
		origin[2] -= mins[2] + SMOKE_GROUND_OFFSET
		hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
		if (is_hull_vacant(origin, hull))
			engfunc(EngFunc_SetOrigin, id, origin)
		else { // close to a solid object, trying to find a vacant spot
			static Float:vec[3]
			vec[2] = origin[2]
			for (new i; i < sizeof g_sign; ++i) {
				vec[0] = origin[0] - mins[0] * g_sign[0]
				vec[1] = origin[1] - mins[1] * g_sign[1]
				if (is_hull_vacant(vec, hull)) {
					engfunc(EngFunc_SetOrigin, id, vec)
					break
				}
			}
		}
	}

	return FMRES_SUPERCEDE
}

public forward_playbackevent(flags, invoker, eventindex) {
	// we do not need a large amount of smoke
	if (eventindex == g_eventid_createsmoke)
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

bool:is_grenade(ent) {
	if (!pev_valid(ent))
		return false

	static classname[sizeof g_classname_grenade + 1]
	pev(ent, pev_classname, classname, sizeof g_classname_grenade)
	if (equal(classname, g_classname_grenade))
		return true

	return false
}

create_smoke(const Float:origin[3]) {
	// engfunc because origin are float
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(g_spriteid_steam1)
	write_byte(SMOKE_SCALE)
	write_byte(SMOKE_FRAMERATE)
	message_end()
}

stock bool:is_hull_vacant(const Float:origin[3], hull) {
	new tr = 0
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, tr)
	if (!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid) && get_tr2(tr, TR_InOpen))
		return true
	
	return false
}