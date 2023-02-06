#include <amxmodx>
#include <amxmisc>
#include <csstats>
#define HUD_INTERVAL 1.0
#define RANK_NOTHING 0
#define RANK_PRIVATE 1
#define RANK_PRIVATE_FIRST_CLASS 2
#define RANK_CORPORAL 3
#define RANK_SERGEANT 4
#define RANK_STAFF_SERGEANT 5
#define RANK_GUNNERY_SERGEANT 6
#define RANK_MASTER_SERGEANT 7
#define RANK_COMMAND_SERGEANT 8
#define RANK_SECOND_LIEUTENANT 9
#define RANK_FIRST_LIEUTENANT 10
#define RANK_COLONEL 11
#define RANK_BRIGADIER_GENERAL 12
#define RANK_MAJOR_GENERAL 13
#define RANK_LIEUTENANT_GENERAL 14
#define RANK_GENERAL 15
#define RANK_GENERAL_OF_THE_ARMY 16
#define MAXRANKS 17
new PlayerRank[33]
new const rankNames[MAXRANKS][] =
{
"Level 1 Trainee",
"Level 2 Assistant",
"Level 3 Scholar",
"Level 4 Master",
"Level 5 High Seer",
"Level 6 Emperor",
"Level 7 Drug Dealer",
"Level 8 Imperator",
"Level 9 Warmaster",
"Level 10 Purifier",
"Level 11 Count",
"Level 12 Strategos",
"Level 13 Templar",
"Level 14 Bishop",
"Level 15 Archseer",
"Level 16 Warlord",
"Level 17 Royal Justicar"
}
new const rankXP[MAXRANKS] =
{
0, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 650, 700, 800, 1000
}

public plugin_init()

{
register_plugin("Rank Display", "1.1","TEST")
}

public client_putinserver(id)
{
set_task(HUD_INTERVAL, "ShowHUD", id)
return PLUGIN_HANDLED
}

public ShowHUD(id)
{

if(!is_user_connected(id))
return 0
static stats[8], hits[8], name[33]
get_user_stats(id, stats, hits)
get_user_name(id, name, 32)

new currentPlayerRank = 0;
while
(currentPlayerRank < (MAXRANKS - 1))
{
if(stats[0] >= rankXP[currentPlayerRank + 1])
++currentPlayerRank;
else
break;
}
new leftkills = rankXP[currentPlayerRank + 1] - stats[0];
//I have no idea why you are storing the rank here, maybe you're planning to use it later
PlayerRank[id] = currentPlayerRank;
set_hudmessage(0, 255, 20, -1.0, 0.8, 0, 3.0, 6.0)
show_hudmessage(id, "[%s] ^n[Current Rank: %s] ^n[Kills needed for next rank]: %i", name, rankNames[currentPlayerRank], leftkills)
set_task(HUD_INTERVAL, "ShowHUD", id)
return PLUGIN_HANDLED
}
