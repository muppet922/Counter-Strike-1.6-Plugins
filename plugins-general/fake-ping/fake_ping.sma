#include <amxmodx>
#include <fakemeta>

#define CheckFlag(%1,%2)  (%1 &   (1 << (%2 & 31)))
#define SetFlag(%1,%2)    (%1 |=  (1 << (%2 & 31)))
#define ClearFlag(%1,%2)  (%1 &= ~(1 << (%2 & 31)))

#define PING_MILTIPLIER 25			// Сколько процентов от реального пинга отображать  [По умолчанию: 25%]

#define TASK_ARGUMENTS 100

new g_argping[33], g_pingoverride[33] = { -1, ... }

new g_maxplayers, isUserConnect

public plugin_init()
{
	register_plugin("Fake Ping", "1.1", "MeRcyLeZZ/gyxoBka")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData")
	register_event("DeathMsg", "fix_fake_pings", "a")
	register_event("TeamInfo", "fix_fake_pings", "a")
	
	g_maxplayers = get_maxplayers()
	
	set_task(2.0, "calculate_arguments", TASK_ARGUMENTS, _, _, "b")
}

public client_putinserver(id) 
{
	SetFlag( isUserConnect, id );
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(id) 
#else
public client_disconnected(id) 
#endif
{
	ClearFlag( isUserConnect, id );
	g_pingoverride[id] = -1
}	

public fix_fake_pings()
{
	static player
	for (player = 1; player <= g_maxplayers; player++)
	{
		// Player not in game?
		if (!CheckFlag( isUserConnect, player ))
			 continue;
		
		// Resend fake pings
		fw_UpdateClientData(player)
	}
}

public calculate_arguments()
{
	static player, ping, loss
	for (player = 1; player <= g_maxplayers; player++)
	{
		// Calculate target ping (clamp if out of bounds)
		if (g_pingoverride[player] < 0)
		{
			get_user_ping(player, ping, loss)
			g_argping[player] = clamp(floatround(ping * 0.PING_MILTIPLIER), 0, 4095)
		}
		else
			g_argping[player] = g_pingoverride[player]
	}
}

public fw_UpdateClientData(id)
{
	// Scoreboard key being pressed?
	if (!(pev(id, pev_button) & IN_SCORE) && !(pev(id, pev_oldbuttons) & IN_SCORE))
		return;
	
	// Send fake player's pings
	static player, sending, bits, bits_added
	sending = false
	bits = 0
	bits_added = 0
	
	for (player = 1; player <= g_maxplayers; player++)
	{
		// Player not in game?
		if (!CheckFlag( isUserConnect, id ))
			 continue;

		// Start message
		if (!sending)
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_PINGS, _, id)
			sending = true
		}
		
		// Add bits for this player
		AddBits(bits, bits_added, 1, 1) // flag = 1
		AddBits(bits, bits_added, player-1, 5) // player-1 since HL uses ids 0-31
		AddBits(bits, bits_added, g_argping[player], 12) // ping
		AddBits(bits, bits_added, 0, 7) // loss
		
		// Write group of 8 bits (bytes)
		WriteBytes(bits, bits_added, false)
	}
	
	// End message
	if (sending)
	{
		// Add empty bit at the end
		AddBits(bits, bits_added, 0, 1) // flag = 0
		
		// Write remaining bits
		WriteBytes(bits, bits_added, true)
		
		message_end()
	}
}

AddBits(&bits, &bits_added, value, bit_count)
{
	// No more room (max 32 bits / 1 cell)
	if (bit_count > (32 - bits_added) || bit_count < 1)
		return;
	
	// Clamp value if its too high
	if (value >= (1 << bit_count))
		value = ((1 << bit_count) - 1)
	
	// Add new bits
	bits = bits + (value << bits_added)
	// Increase bits added counter
	bits_added += bit_count
}

WriteBytes(&bits, &bits_added, write_remaining)
{
	// Keep looping if there are more bytes to write
	while (bits_added >= 8)
	{
		// Write group of 8 bits
		write_byte(bits & ((1 << 8) - 1))
		
		// Remove bits we just sent by moving all bits to the right 8 times
		bits = bits >> 8
		bits_added -= 8
	}
	
	// Write remaining bits too?
	if (write_remaining && bits_added > 0)
	{
		write_byte(bits)
		bits = 0
		bits_added = 0
	}
}