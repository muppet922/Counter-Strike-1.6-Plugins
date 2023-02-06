#include <amxmodx>
#include <fakemeta_util>

#define MODEL_GUNDROP			"models/zmgorod/drop_effect.mdl"

#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)
#define SAVE_WEAPONENT(%0,%1)		set_pev(%0, pev_iuser1, %1)
#define GET_WEAPONENT(%0)		pev(%0, pev_iuser1)

#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)

public plugin_init() 
{
	register_plugin("[ZP] Gundrop effect", "0.1", "PaXaN-ZOMBIE");
	register_forward(FM_SetModel, "FakeMeta_SetModel",false);
	register_forward(FM_Think, "FakeMeta_Think",false);
}

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_GUNDROP);
}

public FakeMeta_SetModel(const iEntity, const iModel[])
{
	if(!pev_valid(iEntity))
	{
		return FMRES_IGNORED;
	}

	static iClassname[33];pev(iEntity, pev_classname, iClassname, sizeof(iClassname));
		
	if(equal(iClassname, "weaponbox"))
	{
		new iszAllocStringCached,pEntity;
		new Origin[3];pev(iEntity, pev_origin, Origin);
		
		if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
		{
			pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		}
		
		if (pev_valid(pEntity))
		{
			set_pev(pEntity, pev_movetype, MOVETYPE_FOLLOW);
				
			SET_MODEL(pEntity, MODEL_GUNDROP);
			SET_ORIGIN(pEntity, Origin);
			SAVE_WEAPONENT(pEntity, iEntity);
	
			set_pev(pEntity, pev_classname, "drop_effect");
			set_pev(pEntity, pev_aiment, iEntity);
			set_pev(pEntity, pev_framerate, 0.5);
			set_pev(pEntity, pev_sequence, 0);
			set_pev(pEntity, pev_animtime, get_gametime());

			set_pev(pEntity, pev_nextthink, get_gametime() + 0.01);
		}
	}
	
	return FMRES_IGNORED;
}

public FakeMeta_Think(const iEntity)
{
	if (!pev_valid(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	new iClassname[32];pev(iEntity, pev_classname, iClassname, sizeof(iClassname));
	
	if (equal(iClassname, "drop_effect"))
	{
		new iWeapon = GET_WEAPONENT(iEntity);
		
		if (!pev_valid(iWeapon))
		{
			set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
			return FMRES_SUPERCEDE;
		}
		
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.1);
	}

	return FMRES_IGNORED;
}