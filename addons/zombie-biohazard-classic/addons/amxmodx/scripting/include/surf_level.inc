/* Credite -> cheap_suit (Biohazard mod) */



#define LEVEL_MOD



/*
* Inregistram o clasa
*/

#if defined LEVEL_MOD
native surf_register_class(classname[], description[], primary_weapon[], level, health, armor, Float:speed, Float:gravity, Float:attack)
#else
native surf_register_class(classname[], description[], primary_weapon[], health, armor, Float:speed, Float:gravity, Float:attack)
#endif


/*
* Aflam clasa pentru fiecare in parte
*
* param id  -  index
*/
native get_user_class(id);