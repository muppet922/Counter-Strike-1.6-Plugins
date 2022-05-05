#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombie_plague_special>

#define PLUGIN  "Bn_zp_armor"
#define VERSION "1.5"
#define AUTHOR  "NEO"

#define SOZDATEL_FLAG  ADMIN_RCON
#define ADMIN_FLAG     ADMIN_BAN
#define VIP_FLAG       ADMIN_LEVEL_H

#define PREFIKS "!t[!gZP!t]"                     // Префикс в чате

new const g_Buy[] = { "items/tr_kevlar.wav" }    // Звук покупки (Стандартный)
new const COST = 10                              // Цена

new itemid_armor

new g_give_armor_sozdatel,g_give_armor_admin,g_give_armor_vip,g_give_armor_user
new g_armor_limit_sozdatel,g_armor_limit_admin,g_armor_limit_vip,g_armor_limit_user

public plugin_cfg()
{
    new szCfgDir[64], szFile[192];
    get_configsdir(szCfgDir, charsmax(szCfgDir));
    formatex(szFile,charsmax(szFile),"%s/bn_plague/extra/bn_armor.cfg",szCfgDir)
    if(file_exists(szFile))
    server_cmd("exec %s", szFile);
}

public plugin_precache()
{
    precache_sound(g_Buy)
}

public plugin_init()
{
    register_plugin("[ZP]Extra: Armor with limit", "1.0", "Sergey Kazancev")

    set_cvar_string("bn_armor",VERSION)

    g_give_armor_sozdatel = register_cvar("zp_give_armor_sozdatel", "0")
    g_give_armor_admin = register_cvar("zp_give_armor_admin", "0")
    g_give_armor_vip = register_cvar("zp_give_armor_vip", "0")
    g_give_armor_user = register_cvar("zp_give_armor_user", "0")

    g_armor_limit_sozdatel = register_cvar("zp_armor_limit_sozdatel", "0")
    g_armor_limit_admin = register_cvar("zp_armor_limit_admin", "0")
    g_armor_limit_vip = register_cvar("zp_armor_limit_vip", "0")
    g_armor_limit_user = register_cvar("zp_armor_limit_user", "0")

    itemid_armor = zp_register_extra_item("\r[\yZP\r]\yT-Virus armor", COST, ZP_TEAM_HUMAN)
}

public zp_extra_item_selected(id, itemid)
{
    if(itemid == itemid_armor)
    {
    if(get_user_flags(id) & SOZDATEL_FLAG)
    {
    if(get_user_armor(id) >= get_pcvar_num(g_armor_limit_sozdatel))
    {
    color_print(id, "%s You have reached the maximum limit wich is !t[!g%d!t]",PREFIKS,get_pcvar_num(g_armor_limit_sozdatel))
    zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + COST)
    }
    else
    {
    set_pev(id, pev_armorvalue, float(min(pev(id, pev_armorvalue) + get_pcvar_num(g_give_armor_sozdatel), get_pcvar_num(g_armor_limit_sozdatel))))
    }
    }
    else
    {
    if(get_user_flags(id) & ADMIN_FLAG)
    {
    if(get_user_armor(id) >= get_pcvar_num(g_armor_limit_admin))
    {
    color_print(id, "%s !gYou have reached the limit !t[!g%d!t]",PREFIKS,get_pcvar_num(g_armor_limit_admin))
    zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + COST)
    }
    else
    {
    set_pev(id, pev_armorvalue, float(min(pev(id, pev_armorvalue) + get_pcvar_num(g_give_armor_admin), get_pcvar_num(g_armor_limit_admin))))
    }
    }
    else
    {
    if(get_user_flags(id) & VIP_FLAG)
    {
    if(get_user_armor(id) >= get_pcvar_num(g_armor_limit_vip))
    {
    color_print(id, "%s !gYou have reached the limit of !t[!g%d!t]",PREFIKS,get_pcvar_num(g_armor_limit_vip))
    zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + COST)
    }
    else
    {
    set_pev(id, pev_armorvalue, float(min(pev(id, pev_armorvalue) + get_pcvar_num(g_give_armor_vip), get_pcvar_num(g_armor_limit_vip))))
    }
    }
    else
    {
    if(get_user_armor(id) >= get_pcvar_num(g_armor_limit_user))
    {
    color_print(id, "%s !gЛимит брони !t[!g%d!t]",PREFIKS,get_pcvar_num(g_armor_limit_user))
    zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + COST)
    }
    else
    {
    set_pev(id, pev_armorvalue, float(min(pev(id, pev_armorvalue) + get_pcvar_num(g_give_armor_user), get_pcvar_num(g_armor_limit_user))))
    }
    }
    }
    }
    engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_Buy, 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
}

stock color_print(const id, const input[], any:...)
{
        new count = 1, players[32];
        static msg[191];
        vformat(msg, 190, input, 3);

        replace_all(msg, 190, "!g", "^x04"); // Green Color
        replace_all(msg, 190, "!n", "^x01"); // Default Color
        replace_all(msg, 190, "!t", "^x03"); // Team Color

        if (id) players[0] = id; else get_players(players, count, "ch");
        {
            for (new i = 0; i < count; i++)
            {
                if (is_user_connected(players[i]))
                {
                    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
                    write_byte(players[i]);
                    write_string(msg);
                    message_end();
                }
            }
        }
    }
