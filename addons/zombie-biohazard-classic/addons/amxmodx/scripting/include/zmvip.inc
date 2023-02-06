/******************************************************************

	Zm VIP for Zombie Plague 4.3
	Author: aaarnas

*******************************************************************

	This (zm vip) plugin uses it's own extra
	items simmilar like in main mod(Zombie Plague).
	There are the main natives/forward witch required to
	register extra items plugins on this zm vip plugin.

	Also it's has own authentication system (If MODE 1 is on)
	Use native zv_get_user_flags(id) to check player flags in
	other plugins:

	#include <zmvip>

	public function()
	{
		if(zv_get_user_flags(id) > 0) // Checks if player has any vip privilegies.
		if(zv_get_user_flags(id) & ZV_MAIN) // Checks if player has specific privilegie.
	}

*******************************************************************/
#if defined _zmvip_included
    #endinput
#endif

#define _zmvip_included

#define ZV_PLUGIN_HANDLED 97

/* Flags */
#define ZV_MAIN (1<<0)
#define ZV_MULTI (1<<1)
#define ZV_UNLIMITED (1<<2)
#define ZV_DAMAGE (1<<3)

/* Teams */
#define ZV_TEAM_ZOMBIE (1<<0)
#define ZV_TEAM_HUMAN (1<<1)
#define ZV_TEAM_NEMESIS (1<<2)
#define ZV_TEAM_SURVIVOR (1<<3)


/* Natives */

/* Registers extra items on this plugin for VIPs (Only if MODE 2 is active)
* 
*  @param name           Extra item name.
*  @param discription    Extra item discription (simmilar like zombie class discription).
*  @param cost           How much ammo packs will cost this item for player.
*  @param team           Teams allowed to buy this item. (0 for all teams)
*  @return               Extra item id.
*/
native zv_register_extra_item(const name[], const discription[], cost, team)

/* Gets user flags (Only if MODE 1 is active)
* 
*  @param id             Player index.
*  @return               Player flags.
*/
native zv_get_user_flags(id)


/* Forwards */

/* Called then player selects extra item in his VIP meniu. (Only if MODE 2 is active)
*
*  You can stop player of buing item returning ZV_PLUGIN_HANDLED.
*  Player will be refunded automaticaly
* 
*  @param id             Player index.
*  @param itemid         Extra item id, witch player bought.
*/
forward zv_extra_item_selected(id, itemid)