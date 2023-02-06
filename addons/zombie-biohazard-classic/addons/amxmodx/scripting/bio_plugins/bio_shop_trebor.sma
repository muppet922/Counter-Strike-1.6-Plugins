#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <biohazard>
#include <hamsandwich>

native bio_set_user_drag(id, value);
native bio_get_user_drag(id);

#define PLUGIN_NAME	"[Biohazard] Shop"
#define PLUGIN_AUTHOR	"Trebor Unaerugnu"
#define PLUGIN_VERSION	"1.0 Unfinished"

//#define is_user_player(%1) 	(1 <= %1 <= max_players)

// offset-uri (nu se modifica)
#define XTRA_OFS_WEAPON	4
#define XTRA_OFS_PLAYER		5
#define m_pPlayer			41
#define m_iId			43
#define m_flNextPrimaryAttack	46
#define m_flNextSecondaryAttack	47
#define m_flTimeWeaponIdle		48
#define m_iClip			51
#define m_fInReload		54
#define m_fInSpecialReload		55
#define m_flNextAttack		83
#define OFFSET_AMMO_BUCKSHOT	381

// nu modifica
#define ZOMBIE_SMOKER_ID	6

new g_HostName[64], menu_callback, money;
new /*max_players, */cvar_hostname;

// player vars
new bullets[33], weapon[33], got_hook[33];

// humans
enum
{
	COST_AMMO = 0
}

// zombies
enum
{
	COST_DRAG = 0
}

// nu modifica
new const g_weapon_ammo[][] =
{
	{ -1, -1 },	// null
	{ 13, 52 },	// p228
	{ -1, -1 },	// null
	{ 10, 90 },	// scout
	{ -1, -1 },	// he
	{ 7, 32 },	// xm1014
	{ -1, -1 },	// c4
	{ 30, 100 },// mac10
	{ 30, 90 },	// aug
	{ -1, -1 },	// smoke
	{ 30, 140 },// elite
	{ 20, 100 },// fiveseven
	{ 25, 100 },// ump45
	{ 30, 90 },	// sg550
	{ 35, 105 },// galil
	{ 25, 90 },	// famas
	{ 12, 100 },// usp
	{ 20, 120 },// glock18
	{ 10, 30 },	// awp
	{ 30, 120 },// mp5navy
	{ 100, 200 },// m249
	{ 8, 32 },	// m3
	{ 30, 90 },	// m4a1
	{ 35, 140 },// tmp
	{ 20, 90 },	// g3sg1
	{ -1, -1 },	// fb
	{ 7, 35 },	// deagle
	{ 30, 90 },	// sg552
	{ 30, 90 },	// ak47
	{ -1, -1 },	// knife
	{ 50, 100 }	// p90
}

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

enum
{
	idle,
	shoot1,
	shoot2,
	insert,
	after_reload,
	start_reload,
	draw
}

enum _:ShotGuns
{
	m3,
	xm1014
}

new HamHook:g_iHhPostFrame[CSW_P90+1], HamHook:g_iHhWeapon_WeaponIdle[ShotGuns];




// --------------------------------------------
//   ------------- DE EDITAT ---------------
// --------------------------------------------
// Costul itemelor din shop-ul oamenilor (in $)
new const SHOP_HUMANS[] = 
{
	1000		// COSTUL MUNITIEI
}

// Costul itemelor din shop-ul zombilor (in $)
new const SHOP_ZOMBIES[] = 
{
	1000		// COSTUL HOOK-ului
}

new const TAG[] = "[Biohazard]";	// TAG
// --------------------------------------------
//   ------------- DE EDITAT ---------------
// --------------------------------------------




public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_cvar("level_mod_", PLUGIN_VERSION, FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string("level_mod_", PLUGIN_VERSION);

	register_event("HLTV", "event_NewRound", "a", "1=0", "2=0");
	//register_event("DeathMsg", "event_DeathMsg", "a");
	register_clcmd("say /shop", "ShowShopMenu");
	register_clcmd("say_team /shop", "ShowShopMenu");
	register_clcmd("say shop", "ShowShopMenu");
	register_clcmd("say_team shop", "ShowShopMenu");
	
	cvar_hostname = get_cvar_pointer("hostname");
	//max_players = get_maxplayers();
}

public plugin_cfg()
{
	get_pcvar_string(cvar_hostname, g_HostName, charsmax(g_HostName));
}

public client_putinserver(id)
{
	bullets[id] = 0;
	got_hook[id] = 0;
}

public ShowShopMenu(id)
{
	if(!is_user_alive(id))
	{
		ColorChat(id, "!4%s!1 Trebuie sa fii in viata pentru a deschide shop-ul.", TAG);
		return PLUGIN_HANDLED;
	}
	if(!game_started())
	{
		ColorChat(id, "!4%s!1 Infectia nu s-a raspandit inca pentru a accesa shop-ul.", TAG);
		return PLUGIN_HANDLED;
	}

	Shop(id);
	return PLUGIN_CONTINUE;
}

public Shop(id)
{
	new menu, text_menu[128];
	formatex(text_menu, charsmax(text_menu), "\wShop-ul %s | Banii tai:\r %d^n\y%s", is_user_zombie(id) ? "Zombilor" : "Oamenilor", cs_get_user_money(id), g_HostName);
	menu = menu_create(text_menu, "ShopHandler");
	menu_callback = menu_makecallback("CallBackMenu");
	

	if(is_user_zombie(id))
		formatex(text_menu, charsmax(text_menu), "+1 hook (doar pentru SMOKERI) -\r %d$\d^n^n^n\dInca se lucreaza la shop...", SHOP_ZOMBIES[COST_DRAG]);
	else
		formatex(text_menu, charsmax(text_menu), "+10 gloante -\r %d$\d^n^n^n\dInca se lucreaza la shop...", SHOP_HUMANS[COST_AMMO]);
	menu_additem(menu, text_menu, "1", 0, menu_callback);
	

	//menu_additem(menu, "item 2", "2", 0, menu_callback);
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	
	return PLUGIN_CONTINUE;
}

public CallBackMenu(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	money = cs_get_user_money(id);
	
	switch(item)
	{
		case 0:
		{
			if(is_user_zombie(id))
			{
				if(SHOP_ZOMBIES[COST_DRAG] > money || got_hook[id] == 1 || get_user_class(id) != ZOMBIE_SMOKER_ID)
					return ITEM_DISABLED;
			}
			else
			{
				new weapons[32], num, i;
				new bool:gasit = false;
				get_user_weapons(id, weapons, num);
	
				for(i = 0; i < num; i++)
				{
					if(PRIMARY_WEAPONS_BIT_SUM & (1<<weapons[i]))
					{
						gasit = true;
						break;
					}
				}

				if(!gasit || bullets[id] == 1 || SHOP_HUMANS[COST_AMMO] > money)
					return ITEM_DISABLED;
			}
		}
		/*
		case 1:
		{
			if(is_user_zombie(id))
			{
				
			}
			else
			{
				
			}
			return ITEM_DISABLED;
		}
		*/
	}
	
	return ITEM_ENABLED;
}

public ShopHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	money = cs_get_user_money(id);
	new cost;
	
	switch(item)
	{
		case 0:
		{
			if(is_user_zombie(id))
			{
				cost = SHOP_ZOMBIES[COST_DRAG];				
				got_hook[id] = 1;
				bio_set_user_drag(id, bio_get_user_drag(id) + 1);
				ColorChat(id, "!4%s!1 Ai cumparat!3 +1 hook!1 pentru zombie smoker cu!3 %d!1$.", TAG, cost);
			}
			else
			{
				cost = SHOP_HUMANS[COST_AMMO];
				bullets[id] = 1;
				
				new weapons[32], num, i;
				get_user_weapons(id, weapons, num);
	
				for(i = 0; i < num; i++)
				{
					if(PRIMARY_WEAPONS_BIT_SUM & (1<<weapons[i]))
					{
						break;
					}
				}
			
				new weaponname[32];
				get_weaponname(weapons[i], weaponname, 31);
				
				weapon[id] = get_weaponid(weaponname);
				
				new bool:bIsShotGun = !!((1<<CSW_M3)|(1<<CSW_XM1014) & (1<<weapon[id]));
				if(bIsShotGun)
				{
					g_iHhWeapon_WeaponIdle[weapon[id] == CSW_M3 ? m3 : xm1014] = RegisterHam(Ham_Weapon_WeaponIdle, weaponname, "Shotgun_WeaponIdle");
				}

				new ent;
				ent = fm_find_ent_by_owner(-1, weaponname, id);
				set_pdata_int(ent, 51, g_weapon_ammo[weapon[id]][0] + 10, 4);
				
				// pentru modul biohazard, nu e necesar sa ii mai dam full munitie (modul face asta deja)
				//cs_set_user_bpammo(id, weapon[id], g_weapon_ammo[weapon[id]][1]);
				
				// ii permitem sa atace dupa 1 secunda dupa ce a cumparat gloantele (NU MODIFICA)
				set_pdata_float(id, m_flNextAttack, 1.0, XTRA_OFS_WEAPON);
				
				g_iHhPostFrame[weapon[id]] = RegisterHam(Ham_Item_PostFrame, weaponname, "fw_ItemPostFrame");
				set_task(0.1, "add_weapon", id);

				new wp_name[32];
				num = strlen(weaponname);
				for(i = 7; i < num; i++) {wp_name[i-7] = weaponname[i];}
				ColorChat(id, "!4%s!1 Ai cumparat!3 +10 gloante!1 pentru arma!3 %s!1 cu!3 %d!1$.", TAG, wp_name, cost);
			}
			
			cs_set_user_money(id, money - cost);
		}
		/*
		case 1:
		{
			
		}
		*/
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public add_weapon(id)
{
	EnableHamForward(g_iHhPostFrame[weapon[id]]);

	new bool:bIsShotGun = !!((1<<CSW_M3)|(1<<CSW_XM1014) & (1<<weapon[id]));
	if(bIsShotGun)
	{
		EnableHamForward(g_iHhWeapon_WeaponIdle[weapon[id] == CSW_M3 ? m3 : xm1014]);
	}
}

public fw_ItemPostFrame(iEnt)
{
	static id;
	id = pev(iEnt, pev_owner);

	if(is_user_alive(id) && bullets[id] == 1)
	{
		static iBpAmmo;
		iBpAmmo = cs_get_user_bpammo(id, weapon[id]);

		static iClip;
		iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON);

		static iMaxClip;
		iMaxClip = g_weapon_ammo[weapon[id]][0] + 10;

		static Float:flNextAttack;
		flNextAttack = get_pdata_float(id, m_flNextAttack, XTRA_OFS_PLAYER);

		static fInReload;
		fInReload = get_pdata_int(iEnt, m_fInReload, XTRA_OFS_WEAPON);

		if(fInReload && flNextAttack <= 0.0)
		{
			new j = min(iMaxClip - iClip, iBpAmmo);
			set_pdata_int(iEnt, m_iClip, iClip + j, XTRA_OFS_WEAPON);
			cs_set_user_bpammo(id, weapon[id], iBpAmmo - j);

			set_pdata_int(iEnt, m_fInReload, 0, XTRA_OFS_WEAPON);
			cs_set_weapon_ammo(iEnt, iMaxClip);
		
			fInReload = 0;
		}

		if(!(weapon[id] == CSW_XM1014 || weapon[id] == CSW_M3))
			return;

		// https://forums.alliedmods.net/showthread.php?p=728613#post728613
		static iButton;
		iButton = pev(id, pev_button);
		if(iButton & IN_ATTACK && get_pdata_float(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) <= 0.0)
		{
			return;
		}
	
		if(iButton & IN_RELOAD)
		{
			if(iClip >= iMaxClip)
			{
				// oprim animatia
				set_pev(id, pev_button, iButton & ~IN_RELOAD);
				set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.5, XTRA_OFS_WEAPON); 
			}
			else if(iClip == iMaxClip)
			{
				if(iBpAmmo)
				{
					Shotgun_Reload(iEnt, weapon[id], iMaxClip, iClip, iBpAmmo, id);
				}
			}
		}
	}
}

Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
{
	if(iBpAmmo <= 0 || iClip == iMaxClip)
		return;

	if(get_pdata_int(iEnt, m_flNextPrimaryAttack, XTRA_OFS_WEAPON) > 0.0)
		return;

	switch(get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON))
	{
		case 0:
		{
			SendWeaponAnim(id , start_reload);
			set_pdata_int(iEnt, m_fInSpecialReload, 1, XTRA_OFS_WEAPON);
			set_pdata_float(id, m_flNextAttack, 0.55, XTRA_OFS_PLAYER);
			set_pdata_float(iEnt, m_flTimeWeaponIdle, 0.55, XTRA_OFS_WEAPON);
			set_pdata_float(iEnt, m_flNextPrimaryAttack, 0.55, XTRA_OFS_WEAPON);
			set_pdata_float(iEnt, m_flNextSecondaryAttack, 0.55, XTRA_OFS_WEAPON);
			return
		}
		case 1:
		{
			if(get_pdata_float(iEnt, m_flTimeWeaponIdle, XTRA_OFS_WEAPON) > 0.0)
			{
				return;
			}
			set_pdata_int(iEnt, m_fInSpecialReload, 2, XTRA_OFS_WEAPON);
			emit_sound(id, CHAN_ITEM, random_num(0, 1) ? "weapons/reload1.wav" : "weapons/reload3.wav", 1.0, ATTN_NORM, 0, 85 + random_num(0, 0x1f)); // ??
			SendWeaponAnim(id, insert);

			set_pdata_float(iEnt, m_flTimeWeaponIdle, iId == CSW_XM1014 ? 0.30 : 0.45, XTRA_OFS_WEAPON);
		}
		default:
		{
			set_pdata_int(iEnt, m_iClip, iClip + 1, XTRA_OFS_WEAPON);
			set_pdata_int(id, OFFSET_AMMO_BUCKSHOT, iBpAmmo - 1, XTRA_OFS_PLAYER);
			set_pdata_int(iEnt, m_fInSpecialReload, 1, XTRA_OFS_WEAPON);
		}
	}
}

public Shotgun_WeaponIdle(iEnt)
{
	if(get_pdata_float(iEnt, m_flTimeWeaponIdle, XTRA_OFS_WEAPON) > 0.0)
	{
		return;
	}

	static iId;
	iId = get_pdata_int(iEnt, m_iId, XTRA_OFS_WEAPON);

	static iMaxClip;
	iMaxClip =  g_weapon_ammo[weapon[pev(iEnt, pev_owner)]][0] + 10;

	static iClip;
	iClip = get_pdata_int(iEnt, m_iClip, XTRA_OFS_WEAPON);

	static fInSpecialReload;
	fInSpecialReload = get_pdata_int(iEnt, m_fInSpecialReload, XTRA_OFS_WEAPON);

	if(!iClip && !fInSpecialReload)
	{
		return;
	}

	if(fInSpecialReload)
	{
		static id;
		id = get_pdata_cbase(iEnt, m_pPlayer, XTRA_OFS_WEAPON);

		static iBpAmmo;
		iBpAmmo = get_pdata_int(id, OFFSET_AMMO_BUCKSHOT, XTRA_OFS_PLAYER);

		static iDftMaxClip;
		iDftMaxClip = g_weapon_ammo[weapon[id]][0];

		if(iClip < iMaxClip && iClip == iDftMaxClip && iBpAmmo)
		{
			Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id);
			return;
		}
		else if(iClip == iMaxClip && iClip != iDftMaxClip)
		{
			SendWeaponAnim(id, after_reload);

			set_pdata_int(iEnt, m_fInSpecialReload, 0, XTRA_OFS_WEAPON);
			set_pdata_float(iEnt, m_flTimeWeaponIdle, 1.5, XTRA_OFS_WEAPON);
		}
	}
	return;
}

SendWeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id);
	write_byte(iAnim);
	write_byte(pev(id, pev_body));
	message_end();
}

public event_NewRound()
{
/*
	new Players[32], Num, id, i;
	get_players(Players, Num);
	for(i = 0; i < Num; i++)
	{
		id = Players[i];
		if(!is_user_connected(id))
			continue;
	}
*/

	arrayset(bullets, 0, 33);
	arrayset(got_hook, 0, 33);
}

/*
public event_infect(victim, infector)
{
	if(!is_user_alive(victim) || !is_user_alive(infector))
		return;
	
}


public event_DeathMsg()
{
	new id = read_data(2);
	if(is_user_connected(id))
	{
		
	}
}
*/

stock ColorChat(id, String[], any:...)
{
	static szMesage[192];
	vformat(szMesage, charsmax(szMesage), String, 3);
	
	replace_all(szMesage, charsmax(szMesage), "!1", "^1");
	replace_all(szMesage, charsmax(szMesage), "!3", "^3");
	replace_all(szMesage, charsmax(szMesage), "!4", "^4");
	
	static g_msg_SayText = 0;
	if(!g_msg_SayText)
		g_msg_SayText = get_user_msgid("SayText");
	
	new Players[32], iNum = 1, i;

 	if(id) Players[0] = id;
	else get_players(Players, iNum, "ch");
	
	for(--iNum; iNum >= 0; iNum--)
	{
		i = Players[iNum];
	
		message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i);
		write_byte(i);
		write_string(szMesage);
		message_end();
	}
}

stock fm_find_ent_by_owner(id, const szClassName[], iOwner, jghgtype = 0)
{
	new str_type[11] = "classname", iEnt = id;

	switch(jghgtype) {

		case 1: str_type = "target";
		case 2: str_type = "targetname";
	}

	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, str_type, szClassName)) && pev(iEnt, pev_owner) != iOwner) {  }
	return iEnt;
}

stock bacon_strip_weapon(index, weapon[])
{
	if(!equal(weapon, "weapon_", 7)) 
		return PLUGIN_CONTINUE;

	static weaponid;
	weaponid = get_weaponid(weapon)
	
	if(!weaponid) 
		return PLUGIN_CONTINUE;

	static weaponent;
	weaponent = fm_find_ent_by_owner(-1, weapon, index);
	
	if(!weaponent)
		return PLUGIN_CONTINUE;

	if(get_user_weapon(index) == weaponid) 
		ExecuteHamB(Ham_Weapon_RetireWeapon, weaponent);

	if(!ExecuteHamB(Ham_RemovePlayerItem, index, weaponent)) 
		return PLUGIN_CONTINUE;
	
	ExecuteHamB(Ham_Item_Kill, weaponent);
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid));

	return PLUGIN_HANDLED;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
