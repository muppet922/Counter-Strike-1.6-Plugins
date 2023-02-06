#if defined _credits_included
  #endinput
#endif
#define _credits_included

/**
 * Returns whether Credits is active.
 */
stock is_credits_active()
{
	if(!cvar_exists("bb_credits_active"))
	{
		log_amx("Cvar: ^"bb_credits_active^" does not exist.")
		return 0;
	}
	return 1;
}

/**
 * Returns a users credits.
 *
 * @param id		Player index.
 * @return		Returns current credits
 */
native credits_get_user_credits(id)

/**
 * Sets a users credits to the desired amount.
 *
 * @param id		Player index.
 * @param credits	Credit amount.
 * @return		Returns current credits
 */
native credits_set_user_credits(id, credits)

/**
 * Adds an amount to a users credits.
 *
 * @param id		Player index.
 * @param credits	Adds this amount to current credits.
 * @return		Returns current credits
 */
native credits_add_user_credits(id, credits)

/**
 * Subtracts an amount to a users credits.
 *
 * @param id		Player index.
 * @param credits	Subtracts this amount from current credits.
 * @return		Returns current credits
 */
native credits_subtract_user_credits(id, credits)

/**
 * Returns a users current credits goal.
 *
 * @param id		Player index.
 * @return		Returns current goal
 */
native credits_get_user_goal(id)

/**
 * Sets a users current credits goal..
 *
 * @param id		Player index.
 * @param credits	Amount to get goal to.
 * @return		Returns current goal
 */
native credits_set_user_goal(id, credits)

/**
 * Opens the unlocks menu for the player specified..
 *
 * @param id		Player index.
 */
native credits_show_unlocksmenu(id)

/**
 * Opens the guns menu for the player specified..
 *
 * @param id		Player index.
 */
native credits_show_gunsmenu(id)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
