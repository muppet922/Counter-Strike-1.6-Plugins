#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <fakemeta>
#include <cstrike>

#include <xs>

#define PLUGIN "Remove Lasermine"
#define VERSION "v0.2"
#define AUTHOR "TEST"

#define BIOHAZARD_SUPPORT

new const g_szLMClass[] = "lasermine";
new g_pShowOwner, g_pReturnMoney, g_pLtmCost;

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_clcmd("amx_removelaser", "cmdLmRemove", ADMIN_KICK);
    
    g_pShowOwner = register_cvar("lmr_showowner", "1");
    g_pReturnMoney = register_cvar("lmr_returnmoney", "-1");
    
    #if defined BIOHAZARD_SUPPORT
        g_pLtmCost = get_cvar_pointer("bio_ltm_cost");
    #else
        g_pLtmCost = get_cvar_pointer("amx_ltm_cost");
    #endif
}

public cmdLmRemove(id, iLevel, iCid)
{
    if(!cmd_access(id, iLevel, iCid, 1))
        return PLUGIN_HANDLED;
        
    new Float: fvOrigin[3], Float: fvViewOfs[3], Float: fvEnd[3];
    pev(id, pev_origin, fvOrigin); pev(id, pev_view_ofs, fvViewOfs);
    xs_vec_add(fvOrigin, fvViewOfs, fvOrigin);
    velocity_by_aim(id, 4096, fvEnd); xs_vec_add(fvOrigin, fvEnd, fvEnd);
    
    engfunc(EngFunc_TraceLine, fvOrigin, fvEnd, DONT_IGNORE_MONSTERS, id, 0);
    
    new Float: fFraction; get_tr2(0, TR_flFraction, fFraction);
    if(fFraction == 1.0)
        return PLUGIN_HANDLED;
        
    new iHit = get_tr2(0, TR_pHit);
    if((1 <= iHit <= 32))
        ColorChat(id, GREEN, "^4[Biohazard] ^1You can't remove the lasermine.");
    else
    {
        if(pev_valid(iHit))
        {
            new szClassname[32]; pev(iHit, pev_classname, szClassname, charsmax(szClassname));
            if(equal(szClassname, g_szLMClass))
            {
                new szName[32], iOwner;
                get_user_name(id, szName, charsmax(szName));
                iOwner = pev(iHit, pev_iuser2);

                if(get_pcvar_num(g_pShowOwner))
                {
                    new szOwnerName[32]; 
                    get_user_name(iOwner, szOwnerName, charsmax(szOwnerName));
                    ColorChat(0, GREEN, "^4[Biohazard] ^1Admin^4 [%s] ^1removed^4 %s^1 lasermines.", szName, szOwnerName);
                }
                else
                    ColorChat(0, GREEN, "^4[Biohazard] ^1Admin^4 [%s] ^1removed lasermines.", szName);
                    
                if(get_pcvar_num(g_pReturnMoney) == 0)
                    cs_set_user_money(iOwner, cs_get_user_money(iOwner) + get_pcvar_num(g_pLtmCost))
                else if(get_pcvar_num(g_pReturnMoney) > 0)
                    cs_set_user_money(iOwner, cs_get_user_money(iOwner) + get_pcvar_num(g_pReturnMoney));
                
                engfunc(EngFunc_RemoveEntity, iHit);
            }
        }
    }
    
    return PLUGIN_HANDLED;
}  
