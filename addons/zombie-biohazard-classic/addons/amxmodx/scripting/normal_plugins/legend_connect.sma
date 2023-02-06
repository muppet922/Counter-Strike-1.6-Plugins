#include <amxmodx>
#include <amxmisc>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "TEST"

new Prefix[] = "[WARNING]"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
}

public client_putinserver(id) {
	if(is_user_connected(id) && get_user_flags(id) == read_flags( "a"))
		set_task(2.0, "ConnectMessage", id)
}

public client_disconnect(id) {
	if(get_user_flags(id) == read_flags( "abcdefghijklmnopqrstu"))
		set_task(2.0, "DisconnectMessage", id)
}

public ConnectMessage(id) {
	new Name[32]
	get_user_name(id, Name, 31)
	ColorChat(0, "!g%s!t The Legend !g%s!t just joined the game, try not to stay in his way!", Prefix, Name)
}

public DisconnectMessage(id) {
	new Name[32]
	get_user_name(id, Name, 31)
	ColorChat(0, "!g%s!t The Legend !g%s!t got bored with you all and left the game...", Prefix, Name)	
}

stock ColorChat(const id, const input[], any:...) {
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
	
	replace_all(msg, 190, "!g", "^4");
	replace_all(msg, 190, "!n", "^1");
	replace_all(msg, 190, "!t", "^3");
	
	if(id) players[0] = id;
	else get_players(players, count, "ch"); {
		for(new i = 0; i < count; i++) {
			if(is_user_connected(players[i])) {
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	} 
}