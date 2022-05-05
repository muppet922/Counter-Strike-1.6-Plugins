#include <amxmodx>
#include <fakemeta>
#include <zombie_plague_special>
#include <chr_engine>
#include <colorchat>

#define MIN_DISTANCE 50

new const g_item_name[] = { "\r[\yZP\r]\yKnife Blinks" }
const g_item_cost = 5
const g_iMaxDistance = 300;

new Float:g_fSpeed = 1000.0;
new Float:g_fDelay = 1.0;

new g_iMaxPlayers;
new g_iEnemy[33];
new g_iInBlink[33];
new Float:g_fLastSlash[33];
new g_iCanceled[33];
new g_iSlash[33];
new g_iBlinks[33];
new g_itemid_blink;

public plugin_init(){

	register_plugin("[ZP] Extra Item: Knife Blinks", "1.3", "BlackRaven");

	g_iMaxPlayers = get_maxplayers();

	g_itemid_blink = zp_register_extra_item(g_item_name, g_item_cost, ZP_TEAM_ZOMBIE);

	register_forward(FM_TraceLine, "FW_TraceLine_Post", 1);
	register_forward(FM_PlayerPreThink, "FW_PlayerPreThink");

	register_event("HLTV", "EVENT_round_start", "a", "1=0", "2=0")
}

// ================================================== //
// 			FORWARDS / EVENTS
// ================================================== //

public FW_TraceLine_Post(Float:start[3], Float:end[3], conditions, id, trace){

	if (!CHECK_ValidPlayer(id))
		return FMRES_IGNORED;

	new iWeaponID = get_user_weapon(id);

	if ( iWeaponID != CSW_KNIFE ){

		OP_Cancel(id);
		return FMRES_IGNORED;
	}

	new enemy = g_iEnemy[id];

	if (!enemy){

		enemy = get_tr2(trace, TR_pHit);

		if ( !CHECK_ValidPlayer(enemy) || zp_get_user_zombie(enemy) ){

			OP_Cancel(id);
			return FMRES_IGNORED;
		}

		g_iEnemy[id] = enemy;
	}

	return FMRES_IGNORED;
}

public FW_PlayerPreThink(id){

	if (!CHECK_ValidPlayer(id))
		return FMRES_IGNORED;

	new iWeaponID = get_user_weapon(id);

	if ( iWeaponID != CSW_KNIFE || !zp_get_user_zombie(id) ){

		OP_Cancel(id);
		return FMRES_IGNORED;
	}

	if ( g_iBlinks[id] == 0 )
		return FMRES_IGNORED;

	new button = pev(id,pev_button);

	if ( !(button & IN_ATTACK) && !(button & IN_ATTACK2) ){

		OP_Cancel(id)
		return FMRES_IGNORED;
	}

	if (g_iSlash[id])
		g_iSlash[id] = 0;

	OP_NearEnemy(id);

	if( g_iInBlink[id] ){

		OP_SetBlink(id);
		OP_Blink(id);
		g_iCanceled[id] = 0;
	}

	return FMRES_IGNORED;
}

// Player buys our upgrade, add one blink
public zp_extra_item_selected(player, itemid)
{
		if (itemid == g_itemid_blink){

		g_iBlinks[player] += 5;
		ColorChat(player, GREY, "^4[ZP] ^1You have now ^4%d ^1Knife Blinks!", g_iBlinks[player]);
		new player_x[32]
		get_user_name(player, player_x, 31)
		ColorChat(0, GREY, "^4[ZP] ^3%s ^1bought ^4Knife Blinks!",player_x)
		set_hudmessage(226, 13, 108, -1.0, 0.7, 1, 6.0, 4.0, 0.0, 0.0, -1)
		show_hudmessage(player, "Now you can use Knife Blinks!")
		}
}

// Reset blinks for all players on newround
public EVENT_round_start()
{
	for (new id; id <= 32; id++) g_iBlinks[id] = 0;
}

// ================================================== //
// 			OPERATIONS
// ================================================== //

public OP_NearEnemy(id){

	new enemy = g_iEnemy[id];
	new Float:time = get_gametime();

	if (!enemy || g_fLastSlash[id]+g_fDelay>time){

		g_iInBlink[id] = 0;
		return;
	}

	new origin[3], origin_enemy[3];

	get_user_origin(id, origin, 0);
	get_user_origin(enemy, origin_enemy, 0);

	new distance = get_distance(origin, origin_enemy);

	if ( MIN_DISTANCE<=distance<=g_iMaxDistance){

		g_iInBlink[id] = 1;
		return;

	}else if (MIN_DISTANCE>distance && g_iInBlink[id])
	{
		OP_Slash(id);
	}
	OP_Cancel(id);
}

public OP_Blink(id){

	new Float:new_velocity[3];
	new enemy = g_iEnemy[id];
	new Float:origin_enemy[3];

	pev(enemy, pev_origin, origin_enemy);
	entity_set_aim(id, origin_enemy);

	get_speed_vector2(id, enemy, g_fSpeed, new_velocity)
	set_pev(id, pev_velocity, new_velocity);
}

public OP_Cancel(id){

	g_iInBlink[id] = 0;
	g_iEnemy[id] = 0;
	if (!g_iCanceled[id]){

		OP_SetBlink(id);
		g_iCanceled[id] = 1;
	}
}

public OP_Slash(id){

	set_pev(id, pev_velocity, {0.0,0.0,0.0});		// stop player's blink

	new weaponID = get_user_weapon(id, _, _);

	if(weaponID == CSW_KNIFE){

		new weapon[32]

		get_weaponname(weaponID,weapon,31)

		new ent = fm_find_ent_by_owner(-1,weapon,id)

		if(ent){

			set_pdata_float(ent,46, 0.0);
			set_pdata_float(ent,47, 0.0);
			g_iSlash[id] = 1;
			g_fLastSlash[id] = get_gametime();
			g_iBlinks[id] -= 1;
			new name[32];
			get_user_name(id,name,31)
			ColorChat(0, GREY, "^4[ZP] ^3%s ^1just used a ^4KnifeBlink! ^1(Blink remaining: ^4%d blink^1)", name, g_iBlinks[id]);
		}
	}
}

public OP_SetBlink(id){

	new blink = g_iInBlink[id];

	if (blink>1)
		return;

	if (blink)
		g_iInBlink[id] += 5;
}

// ================================================== //
// 			CHECKS
// ================================================== //

public CHECK_ValidPlayer(id){

	if (1<=id<=g_iMaxPlayers && is_user_alive(id))
		return 1;

	return 0;
}

// from fakemeta_util.inc
stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}

stock chat_color(const id, const input[], any:...)
{
    new count = 1, players[32]

    static msg[191]

    vformat(msg, 190, input, 3)

    replace_all(msg, 190, "!g", "^4")
    replace_all(msg, 190, "!y", "^1")
    replace_all(msg, 190, "!t", "^3")
    replace_all(msg, 190, "!t2", "^0")

    if (id) players[0] = id; else get_players(players, count, "ch")
    {
        for (new i = 0; i < count; i++)
        {
            if (is_user_connected(players[i]))
            {
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
                write_byte(players[i])
                write_string(msg)
                message_end()
            }
        }
    }
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1062\\ f0\\ fs16 \n\\ par }
*/
