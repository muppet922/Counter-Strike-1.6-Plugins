#include <amxmodx>

#define HartiMaxime	5

new NumeHarti[HartiMaxime][34];

public plugin_init() {
	register_plugin("Last maps", "1.0", "TEST")
	register_clcmd("say /maps", "HartiJucateCuSay")
	register_clcmd("say_team /maps", "HartiJucateCuSay")
}

public plugin_cfg() {
	new FisierHartiJucate[64]
	
	get_localinfo("amxx_configsdir", FisierHartiJucate, 63)
	format(FisierHartiJucate, 63, "%s/hartianterioare.txt", FisierHartiJucate)

	new Fisier = fopen(FisierHartiJucate, "rt")
	new i
	new Temporar[34]
	if(Fisier)
	{
		for(i=0; i<HartiMaxime; i++)
		{
			if(!feof(Fisier))
			{
				fgets(Fisier, Temporar, 33)
				replace(Temporar, 33, "^n", "")
				formatex(NumeHarti[i], 33, Temporar)
			}
		}
		fclose(Fisier)
	}

	delete_file(FisierHartiJucate)

	new CurrentMap[34]
	get_mapname(CurrentMap, 33)

	Fisier = fopen(FisierHartiJucate, "wt")
	if(Fisier)
	{
		formatex(Temporar, 33, "%s^n", CurrentMap)
		fputs(Fisier, Temporar)
		for(i=0; i<HartiMaxime-1; i++)
		{
			CurrentMap = NumeHarti[i]
			if(!CurrentMap[0])
				break
			formatex(Temporar, 33, "%s^n", CurrentMap)
			fputs(Fisier, Temporar)
		}
		fclose(Fisier)
	}
}

public HartiJucateCuSay(id) {
	new HartiAnterioare[192], n
	n += formatex(HartiAnterioare[n], 191-n, "!4[INFO-MAPS]!1 Last maps:")
	for(new i; i<HartiMaxime; i++)
	{
		if(!NumeHarti[i][0])
		{
			n += formatex(HartiAnterioare[n-1], 191-n+1, ".")
			break
		}
		n += formatex(HartiAnterioare[n], 191-n, " !3%s!1%s", NumeHarti[i], i+1 == HartiMaxime ? "." : ",")
	}
	ColorChat(id, HartiAnterioare)
	return PLUGIN_CONTINUE
}

stock ColorChat( id, String[  ], any:... ) {

	static szMesage[ 192 ];
	vformat( szMesage, charsmax( szMesage ), String, 3 );
	
	replace_all( szMesage, charsmax( szMesage ), "!1", "^1" );
	replace_all( szMesage, charsmax( szMesage ), "!3", "^3" );
	replace_all( szMesage, charsmax( szMesage ), "!4", "^4" );
	
	static g_msg_SayText = 0;
	if( !g_msg_SayText )
		g_msg_SayText = get_user_msgid( "SayText" );
	
	new Players[ 32 ], iNum = 1, i;

 	if( id ) Players[ 0 ] = id;
	else get_players( Players, iNum, "ch" );
	
	for( --iNum; iNum >= 0; iNum-- ) {

		i = Players[ iNum ];
	
		message_begin( MSG_ONE_UNRELIABLE, g_msg_SayText, _, i );
		write_byte( i );
		write_string( szMesage );
		message_end(  );
	}
}