
#include <amxmodx>
#include <biohazard>
#include <fakemeta_util>
#include <hamsandwich>

new g_first_zombie_sounds[][] = {
	"zm/zombie/Z_Vision/Activate.wav"
}

new g_zombie_die_sounds[][] = 
{ 
	"biohazard/biohazard_new/Tank_Death_01.wav",
	"biohazard/biohazard_new/Tank_Death_02.wav",
	"biohazard/biohazard_new/Tank_Death_03.wav" 
}

new g_attack_hit[][] = 
{
	"zm/zombie/snd/attack/hit/biohazard_new/Z_Hit-01.wav",
	"zm/zombie/snd/attack/hit/biohazard_new/Z_Hit-02.wav",
	"zm/zombie/snd/attack/hit/biohazard_new/Z_Hit-03.wav",
	"zm/zombie/snd/attack/hit/biohazard_new/Z_Hit-04.wav",
	"zm/zombie/snd/attack/hit/biohazard_new/Z_Hit-05.wav",
	"zm/zombie/snd/attack/hit/biohazard_new/Z_Hit-06.wav"
}

new g_attack_swipe[][] = 
{
	"zm/zombie/snd/attack/swipe/biohazard_new/z-swipe-1.wav",
	"zm/zombie/snd/attack/swipe/biohazard_new/z-swipe-2.wav",
	"zm/zombie/snd/attack/swipe/biohazard_new/z-swipe-3.wav",
	"zm/zombie/snd/attack/swipe/biohazard_new/z-swipe-4.wav",
	"zm/zombie/snd/attack/swipe/biohazard_new/z-swipe-5.wav",
	"zm/zombie/snd/attack/swipe/biohazard_new/z-swipe-6.wav"
}

new zom1_attack[][] = 
{
	"zm/zombie/snd/zom1/attack/biohazard_new/Tank_Attack_1.wav",
	"zm/zombie/snd/zom1/attack/biohazard_new/Tank_Attack_2.wav",
	"zm/zombie/snd/zom1/attack/biohazard_new/Tank_Attack_3.wav",
	"zm/zombie/snd/zom1/attack/biohazard_new/Tank_Attack_4.wav",
	"zm/zombie/snd/zom1/attack/biohazard_new/Tank_Attack_5.wav",
	"zm/zombie/snd/zom1/attack/biohazard_new/Tank_Attack_6.wav"
}



new zom2_attack[][] = 
{
	"zm/zombie/snd/zom2/attack/biohazard_new/zombie_attack1.wav",
	"zm/zombie/snd/zom2/attack/biohazard_new/zombie_attack2.wav",
	"zm/zombie/snd/zom2/attack/biohazard_new/zombie_attack3.wav",
	"zm/zombie/snd/zom2/attack/biohazard_new/zombie_attack4.wav",
	"zm/zombie/snd/zom2/attack/biohazard_new/zombie_attack5.wav",
	"zm/zombie/snd/zom2/attack/biohazard_new/zombie_attack6.wav"
}


new zom3_attack[][] = 
{
	"zm/zombie/snd/zom3/attack/biohazard_new/Monster_Attack_01.wav",
	"zm/zombie/snd/zom3/attack/biohazard_new/Monster_Attack_02.wav",
	"zm/zombie/snd/zom3/attack/biohazard_new/Monster_Attack_03.wav",
	"zm/zombie/snd/zom3/attack/biohazard_new/Monster_Attack_04.wav",
	"zm/zombie/snd/zom3/attack/biohazard_new/Monster_Attack_05.wav",
	"zm/zombie/snd/zom3/attack/biohazard_new/Monster_Attack_06.wav",
	"zm/zombie/snd/zom3/attack/biohazard_new/Monster_Attack_07.wav"
}



new g_speech[][] =
{
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak1.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak2.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak3.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak4.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak5.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak6.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak07.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak0008.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak0009.wav",
	"zm/zombie/snd/speech/biohazard_new/Zombie_speak10.wav"
}


	
new Float: g_players[33]
new Float: g_moaning[33]
new g_class[33]

new g_oldtalk[33]
new Float:g_old_pa[33]
new cvar_primattack;

new cvar_moaningdelay

public plugin_init() {         
	register_plugin("bio_painsounds","1.1","TEST")
	is_biomod_active() ? plugin_init2() : pause("ad")	
}
	
public plugin_init2() {
	cvar_primattack = register_cvar("bh_pasounds","1")
	
	cvar_moaningdelay = register_cvar("bh_moaningdelay", "10")
	
	RegisterHam(Ham_Player_PostThink, "player",  "bacon_prethink", 1)
	register_forward(FM_EmitSound,		"fwd_emitsound")	
} 
public client_connect(id) {
	g_class[id]=0
	g_oldtalk[id]=0
}

public eCurWeapon(id) {
	if (get_gametime() > g_old_pa[id]) {
		primaryattack(id)
		g_old_pa[id] = get_gametime()+2.5;
	}
}
public primaryattack(id) if (is_user_alive(id)) {
	if (get_gametime() > g_old_pa[id]) {
		if (is_user_zombie(id)) {
			switch(g_class[id]) {
				case 0: {
					engfunc(EngFunc_EmitSound, id, CHAN_VOICE, zom1_attack[_random(id, sizeof zom1_attack)], 1.0, ATTN_NORM, 0, PITCH_NORM); 
				}
				case 1: {
					engfunc(EngFunc_EmitSound, id, CHAN_VOICE, zom2_attack[_random(id, sizeof zom2_attack)], 1.0, ATTN_NORM, 0, PITCH_NORM); 
				}
				case 2: {
					engfunc(EngFunc_EmitSound, id, CHAN_VOICE, zom3_attack[_random(id, sizeof zom3_attack)], 1.0, ATTN_NORM, 0, PITCH_NORM); 
				}
			}		
		}
		g_old_pa[id] = get_gametime()+0.5;
	}
}
public event_infect(victim, attacker) {
	if (attacker == 0) {
		client_cmd(victim,"spk %s", g_first_zombie_sounds[random_num(0, sizeof g_first_zombie_sounds - 1)])
	}
	g_class[victim] = random_num(0,2)
}
 

public plugin_precache() {
	register_forward(FM_PrecacheSound,	"dontprecache")

	new i = 0;
	
	for(i = 0; i < sizeof g_attack_hit; i++)
		precache_sound(g_attack_hit[i])
	
	for(i = 0; i < sizeof g_attack_swipe; i++)
		precache_sound(g_attack_swipe[i])
	
	for(i = 0; i < sizeof zom1_attack; i++)
		precache_sound(zom1_attack[i])
	for(i = 0; i < sizeof zom2_attack; i++)
		precache_sound(zom2_attack[i])
	for( i = 0; i < sizeof zom3_attack; i++)
		precache_sound(zom3_attack[i])
	
	for(i = 0; i < sizeof g_zombie_die_sounds;  i++) precache_sound(g_zombie_die_sounds[i])
	
	for(i = 0; i < sizeof g_speech; i++)
		precache_sound(g_speech[i])	

	for(i = 0; i < sizeof g_first_zombie_sounds; i++)
		precache_sound(g_first_zombie_sounds[i])	

}

public bacon_prethink(iPlayer)
{
	if(is_user_alive(iPlayer) ) {
		if ((pev(iPlayer, pev_button) & IN_ATTACK) && get_pcvar_num(cvar_primattack)) primaryattack(iPlayer);
		if (is_user_zombie(iPlayer)) {
			if ( get_gametime() > g_moaning[iPlayer]) {
				static Float: origin[3]
				pev(iPlayer, pev_origin, origin)
				static ent ; ent = engfunc(EngFunc_FindEntityInSphere, iPlayer, origin, 250.0)
				if (ent) {
					engfunc(EngFunc_EmitSound, iPlayer, CHAN_VOICE, g_speech[_random(iPlayer, sizeof g_speech)], random_float(0.7, 1.0), ATTN_NORM, 0, PITCH_NORM); 
					g_moaning[iPlayer] = get_gametime() + random_float(0.0,5.0) + float(get_pcvar_num(cvar_moaningdelay));
				}	
			}
		}
	}
}
public fwd_emitsound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{	
	if(!is_user_connected(id) )
		return FMRES_IGNORED

	if (is_user_zombie(id)) {
		g_players[id] = get_gametime() + 1.0;

		//client_print(0,print_chat,"sample %s", sample)
		if (sample[0] == 'z' && sample[1] == 'm')
			return FMRES_IGNORED

		if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if(sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't' || sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
			{
				if(sample[17] == 'w' && sample[18] == 'a' && sample[19] == 'l') {
					emit_sound(id, CHAN_WEAPON, g_attack_swipe[_random(id, sizeof g_attack_swipe)], volume, attn, flag, pitch)
				} else {
					emit_sound(id, CHAN_WEAPON, g_attack_hit[_random(id, sizeof g_attack_hit)], volume, attn, flag, pitch)	
				}
				
				return FMRES_SUPERCEDE
			}
		} 
		else if(sample[7] == 'd' && (sample[8] == 'i' && sample[9] == 'e' || sample[12] == '6'))
		{
			emit_sound(id, channel, g_zombie_die_sounds[_random(id, sizeof g_zombie_die_sounds)], volume, attn, flag, pitch)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

stock _random(id, maxnum) {
	static luck
	luck = random_num(0, maxnum - 1)
	while (luck==g_oldtalk[id]) {
		luck = random_num(0, maxnum - 1)
	}
	g_oldtalk[id] = luck
	return luck;
}
public dontprecache(file[]) {

	if(file[0]=='h' && file[1]=='o' && file[2]=='s')
		return FMRES_SUPERCEDE
	
	return FMRES_IGNORED
}