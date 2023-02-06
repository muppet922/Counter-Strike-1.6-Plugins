#include <amxmodx>
#include <amxmisc>

#define MAX_GROUPS 8
new g_groupNames[MAX_GROUPS][] = {
"Founders",
"Co-Owners",
"Gods",
"Super-Moderators",
"Moderators",
"Helpers",
"Legends",
"Slot"
}
new g_groupFlags[MAX_GROUPS][] = {
"abcdefghijklmnopqrstu",
"bcdefghijklmnopqrst",
"bcdefijmnopqr",
"bcdefijmnop",
"bcdefijmn",
"bcefijm",
"a",
"b"
}
new g_groupFlagsValue[MAX_GROUPS]
public plugin_init() {
register_plugin("Admin_Who", "1.0", "TEST")
register_concmd("amx_who", "cmdWho", ADMIN_KICK)
for(new i = 0; i < MAX_GROUPS; i++) {
g_groupFlagsValue[i] = read_flags(g_groupFlags[i])
}
}

public cmdWho(id, level, cid) 
{

if (!cmd_access(id, level, cid, 1))
   
   return PLUGIN_HANDLED
   
new players[32], inum, player, name[32], i, a
get_players(players, inum)
console_print(id, "[STAFF LIST]")
for(i = 0; i < MAX_GROUPS; i++) {
console_print(id, "-[%d]%s-", i+1, g_groupNames[i])
for(a = 0; a < inum; ++a) {
player = players[a]
get_user_name(player, name, 31)
if(get_user_flags(player) == g_groupFlagsValue[i]) {
console_print(id, "%s", name)
}
}
}
console_print(id, "[STAFF LIST]")
return PLUGIN_HANDLED
}