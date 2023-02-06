#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

new Array:g_aBots;

public plugin_init()
{
	register_plugin("Fake Ping For Bots", "1.0", "fl0wer");

	register_forward(FM_UpdateClientData, "@FM_Hook_UpdateClientData_Post", true);

	g_aBots = ArrayCreate(1);
}

public client_putinserver(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;

	ArrayPushCell(g_aBots, iPlayer);
}

public client_disconnected(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;

	new iValue = ArrayFindValue(g_aBots, iPlayer);

	if (iValue == -1)
		return;

	ArrayDeleteItem(g_aBots, iValue);
}

@FM_Hook_UpdateClientData_Post(iPlayer)
{
	static bool:bSending;
	static iBits, iAdded;
	static iSize;
	static i;

	bSending = false;
	iBits = iAdded = 0;
	iSize = ArraySize(g_aBots);

	for (i = 0; i < iSize; i++)
	{
		if (!bSending)
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_PINGS, _, iPlayer);
			bSending = true;
		}

		AddBits(iBits, iAdded, 1, 1);
		AddBits(iBits, iAdded, ArrayGetCell(g_aBots, i) - 1, 5);
		AddBits(iBits, iAdded, (i % 2 == 0 ? 25 : 45) + random_num(-5, 5), 12);
		AddBits(iBits, iAdded, 0, 7);

		WriteBytes(iBits, iAdded, false);
	}
	
	if (bSending)
	{
		AddBits(iBits, iAdded, 0, 1);

		WriteBytes(iBits, iAdded, true);

		message_end();
	}
}

AddBits(&iBits, &iAdded, iValue, iBitCount)
{
	if (iBitCount > (32 - iAdded) || iBitCount < 1)
		return;

	if (iValue >= (1<<iBitCount))
		iValue = (1<<iBitCount) - 1;

	iBits = iBits + (iValue<<iAdded);
	iAdded += iBitCount;
}

WriteBytes(&iBits, &iAdded, iRemaining)
{
	while (iAdded >= 8)
	{
		write_byte(iBits & ((1<<8) - 1));

		iBits = (iBits>>8);
		iAdded -= 8;
	}

	if (iRemaining && iAdded > 0)
	{
		write_byte(iBits);

		iBits = iAdded = 0;
	}
}
