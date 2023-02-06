#if defined _dmtb_api_included
	#endinput
#endif
#define _dmtb_api_included

/*
* Called before a player will be balanced
* You can stop execution of balancing process execution by this forward
*
* @param id     Index of a player
*
* @noreturn
*/
forward OnBalancePlayerPre(id);

/*
* Called after a player is balanced
*
* @param id     Index of a player
*
* @noreturn
*/
forward OnBalancePlayerPost(id);