#if defined _basebuilder_included
  #endinput
#endif
#define _basebuilder_included

enum
{
	COLOR_RED = 0, 		//200, 000, 000
	COLOR_REDORANGE, 	//255, 083, 073
	COLOR_ORANGE, 		//255, 117, 056
	COLOR_YELLOWORANGE, 	//255, 174, 066
	COLOR_PEACH, 		//255, 207, 171
	COLOR_YELLOW, 		//252, 232, 131
	COLOR_LEMONYELLOW, 	//254, 254, 034
	COLOR_JUNGLEGREEN, 	//059, 176, 143
	COLOR_YELLOWGREEN, 	//197, 227, 132
	COLOR_GREEN, 		//000, 200, 000
	COLOR_AQUAMARINE, 	//120, 219, 226
	COLOR_BABYBLUE, 		//135, 206, 235
	COLOR_SKYBLUE, 		//128, 218, 235
	COLOR_BLUE, 		//000, 000, 200
	COLOR_VIOLET, 		//146, 110, 174
	COLOR_PINK, 		//255, 105, 180
	COLOR_MAGENTA, 		//246, 100, 175
	COLOR_MAHOGANY,		//205, 074, 076
	COLOR_TAN, 		//250, 167, 108
	COLOR_LIGHTBROWN, 	//234, 126, 093
	COLOR_BROWN, 		//180, 103, 077
	COLOR_GRAY, 		//149, 145, 140
	COLOR_BLACK, 		//000, 000, 000
	COLOR_WHITE 		//255, 255, 255
}

enum
{
	PUSHING = 1,
	PULLING
}

enum
{
	ATT_HEALTH = 0,
	ATT_SPEED,
	ATT_GRAVITY
}

/**
 * Returns whether Base Builder is active.
 */
stock is_basebuilder_active()
{
	if(!cvar_exists("bb_enabled"))
	{
		log_amx("Cvar: ^"bb_enabled^" does not exist.")
		return 0
	}
	return get_cvar_num("bb_enabled")
}

/**
 * Registers a custom class which will be added to the zombie classes menu of BB.
 *
 * Note: The returned zombie class ID can be later used to identify
 * the class when calling the bb_get_user_zombie_class() natives.
 *
 * @param name		Caption to display on the menu.
 * @param info		Brief description of the class.
 * @param model		Player model to be used.
 * @param clawmodel	Claws model to be used.
 * @param hp		Initial health points.
 * @param speed		Maximum speed.
 * @param gravity	Gravity multiplier.
 * @param knockback	Empty value.
 * @param adminflags	Set flag of admin only class, ADMIN_USER is normal players.
 * @param credits	Cost of unlocking this class (if credits is enabled).
 * @return		An internal zombie class ID, or -1 on failure.
 */
native bb_register_zombie_class(const name[], const info[], const model[], const clawmodel[], hp, speed, Float:gravity, Float:knockback = 0.0, adminflags = ADMIN_ALL, credits = 0 )
native zp_register_zombie_class(const name[], const info[], const model[], const clawmodel[], hp, speed, Float:gravity, Float:knockback = 0.0, adminflags = ADMIN_ALL, credits = 0 )

/**
 * Returns a zombie classes cost.
 *
 * @param classid	A valid zombie class ID.
 */
native bb_get_class_cost(classid)

/**
 * Returns a player's current zombie class ID.
 *
 * @param id		Player index.
 * @return		Internal zombie class ID, or -1 if not yet chosen.
 */
native bb_get_user_zombie_class(id)
native zp_get_user_zombie_class(id)

/**
 * Returns a player's next zombie class ID (when they respawn).
 *
 * @param id		Player index.
 * @return		Internal zombie class ID, or -1 if not yet chosen.
 */
native bb_get_user_next_class(id)
native zp_get_user_next_class(id)

/**
 * Sets a player's next zombie class ID (when they respawn).
 *
 * @param id		Player index.
 * @param classid	A valid zombie class ID.
 * @return		True on success, false otherwise.
 */
native bb_set_user_zombie_class(id, classid)
native zp_set_user_zombie_class(id, classid)

/**
 * Returns whether a player is a zombie.
 *
 * @param id		Player index.
 * @return		True if it is, false otherwise.
 */
native bb_is_user_zombie(id)
native zp_get_user_zombie(id)

/**
 * Returns whether a player is banned from building.
 *
 * @param id		Player index.
 * @return		True if it is, false otherwise.
 */
native bb_is_user_banned(id)

/**
 * Returns whether the game is still in the build phase.
 *
 * @param id		Player index.
 * @return		True if it is, false otherwise.
 */
native bb_is_build_phase()

/**
 * Returns whether the game is in the preparation phase.
 *
 * @return		True if it is, false otherwise.
 */
native bb_is_prep_phase()

/**
 * Returns the current build time (in seconds).
 */
native bb_get_build_time()

/**
 * Sets the build timer to a specified number.
 *
 * @param time		Time to set build timer to. (integer)
 */
native bb_set_build_time(time)

/**
 * Returns the players current color ENUM.
 *
 * @param id		Player index.
 */
native bb_get_user_color(id)

/**
 * Sets the build timer to a specified number.
 *
 * @param id		Player index.
 * @param color		Color to set. (enum)
 */
native bb_set_user_color(id, color)

/**
 * Drops the users entity (if he has one).
 *
 * @param id		Player index.
 */
native bb_drop_user_block(id)

/**
 * Returns the users entity..
 *
 * @param id		Player index.
 * @return		Entity index if true, 0 if none
 */
native bb_get_user_block(id)

/**
 * Sets the users current moving block to the entity specified.
 *
 * @param id		Player index.
 * @param entity	Entity index.
 */
native bb_set_user_block(id, entity)

/**
 * Returns whether a block is locked or not.
 *
 * @param entity	Entity index.
 * @return		True if it is, false otherwise
 */
native bb_is_locked_block(entity)

/**
 * Locks specified block if applicable.
 *
 * @param entity	Entity index.
 */
native bb_lock_block(entity)

/**
 * Unlocks specified block if applicable.
 *
 * @param entity	Entity index.
 */
native bb_unlock_block(id, entity)

/**
 * Releases the zombies if valid.
 */
native bb_release_zombies()

/**
 * Sets their "primary weapon" (weapon that is drawn at round start).
 *
 * @param id		Player index.
 * @param csw_primary	CSW_ primary to set to from CSW_P228 to CSW_P90.
 */
native bb_set_user_primary(id, csw_gun)

/**
 * Returns their current primary weapon.
 *
 * @param id		Player index.
 * @return		Returns primary weapon as CSW_ constant.
 */
native bb_get_user_primary(id)

/**
 * Returns current mod admin flags for the following
 *
 * @return		Returns the ADMIN flags for specified level
 */
native bb_get_flags_build()
native bb_get_flags_lock()
native bb_get_flags_buildban()
native bb_get_flags_swap()
native bb_get_flags_revive()
native bb_get_flags_guns()
native bb_get_flags_release()
native bb_get_flags_override()

/*------------------------------------------------------------------------------------------------*/

//Disabled until fixed

/**
 * Sets a multiplier for a class (for use with credits add-on)
 *
 * @param id		Player index.
 * @param attribute	Attribute enum to change
 * @param amount	Float value hat will multiply by
 * @return		Returns 1 if successful, 0 if not
 */
//native bb_set_user_mult(id, attribute, Float:amount)
/*------------------------------------------------------------------------------------------------*/

/**
 * Called when the zombies are released
 * at the end of the build or preparation phase
 */
forward bb_round_started()

/**
 * Called when the preparation phase begins
 * at the end of the build phase, before zombie release
 */
forward bb_prepphase_started()

/**
 * Called when the build phase begins
 * When the round starts (logevent)
 */
forward bb_buildphase_started()

/**
 * Called when a player picks his NEXT zombie class
 *
 * @param id		Player index forwarding the event.
 * @param class		Class index picked
 */
forward bb_zombie_class_picked(id, class)

/**
 * Called when a player has his CURRENT class applied. (respawn)
 *
 * @param id		Player index forwarding the event.
 * @param class		Class index picked
 */
forward bb_zombie_class_set(id, class)

/**
 * Called when a player pushes or pulls an entity
 *
 * @param id		Player index forwarding the event.
 * @param entity	The entity index being moved
 * @param pushpull	Whether it's being pushed or pulled
 *			1 = pushing, 2 = pulling
 */
forward bb_block_pushpull(id, entity, pushpull)

/**
 * Called when a player grabs an entity
 *	Before entity successfully grabbed
 *
 * @param id		Player index forwarding the event.
 * @param entity	The entity index being grabbed
 */
forward bb_grab_pre(id, entity)

/**
 * Called when a player grabs an entity
 *	After the entity is grabbed
 *
 * @param id		Player index forwarding the event.
 * @param entity	The entity index being grabbed
 */
forward bb_grab_post(id, entity)

/**
 * Called when a player drops an entity
 *	Before entity actually dropped
 *
 * @param id		Player index forwarding the event.
 * @param entity	The entity index being dropped
 */
forward bb_drop_pre(id, entity)

/**
 * Called when a player drops an entity
 *	After the entity is dropped
 *
 * @param id		Player index forwarding the event.
 * @param entity	The entity index being dropped
 */
forward bb_drop_post(id, entity)

/**
 * Called when a player receives a new color
 *	Only when they random or select from menu
 *
 * @param id		Player index forwarding the event.
 * @param color		The entity index being dropped
 */
forward bb_new_color(id, color)

/**
 * Called when a player locks an entity
 *	Before entity actually locked
 *
 * @param id		Player index forwarding the event.
 * @param entity	The entity index being locked
 */
forward bb_lock_pre(id, entity)

/**
 * Called when a player locks an entity
 *	After the entity is locked
 *
 * @param id		Player index forwarding the event.
 * @param entity	The entity index being locked
 */
forward bb_lock_post(id, entity)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
