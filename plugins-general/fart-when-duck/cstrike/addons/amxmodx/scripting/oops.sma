#include <amxmodx>
#include <reapi>

#define AUTO_CFG // Закомментируйте, если не нужно автоматическое создание конфига

enum Cvars {
	FART_CHANCE,
	Float:DUCK_BREAK
}

new g_eCvar[Cvars]

new g_iFartChance

new const g_szFartingSounds[][] = {
	"farting/farting1.wav",
	"farting/farting2.wav",
	"farting/farting3.wav",
	"farting/farting4.wav",
	"farting/farting5.wav"
}

public plugin_precache() {
	for(new i; i < sizeof(g_szFartingSounds); i++) {
		precache_sound(g_szFartingSounds[i])
	}
}

public plugin_init() {
	register_plugin("Oops!", "1.0", "CHEL74")
	
	RegisterHookChain(RG_CBasePlayer_Duck, "Duck_Post", true)
	
	bind_pcvar_num(create_cvar("oops_fart_chance", "10",
	.description = "Шанс пердежа при приседании в процентах"),
	g_eCvar[FART_CHANCE])
	bind_pcvar_float(create_cvar("oops_duck_break", "0.2",
	.description = "Через сколько секунд возможен повторный пердёж (нужно, чтобы это не случалось часто при^n\
	удерживании клавиши приседания, выполнении Double Duck и т. п.)"),
	g_eCvar[DUCK_BREAK])
	
	#if defined AUTO_CFG
		AutoExecConfig()
	#endif
}

public OnConfigsExecuted() {
	g_iFartChance = g_eCvar[FART_CHANCE] * 100
}

public Duck_Post(pPlayer) {
	static Float:fLastDuckTime[MAX_PLAYERS + 1]
	new Float:fCurrentTime = get_gametime()
	
	if(fCurrentTime - fLastDuckTime[pPlayer] < g_eCvar[DUCK_BREAK]) {
		fLastDuckTime[pPlayer] = fCurrentTime
		
		return
	}
	
	fLastDuckTime[pPlayer] = fCurrentTime
	
	if(random_num(1, 10000) <= g_iFartChance) {
		emit_sound(pPlayer, CHAN_VOICE, g_szFartingSounds[random(sizeof(g_szFartingSounds))], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}