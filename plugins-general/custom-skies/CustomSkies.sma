#include <amxmodx>
#include <amxmisc>

new const PLUGIN_VERSION[] = "0.0.1";

#define MAX_SKY_NAME_LENGTH 32

new const g_szTypeOfSky[6][3] = { "bk", "dn", "ft", "lf", "rt", "up" };

new g_szSkyName[MAX_SKY_NAME_LENGTH];
new Array:g_aListOfSkies;
new g_iArraySkiesSize;

new const CONFIG_FILE[] = "CustomSkies.ini";  // Name of the config file

public plugin_init()
{
    register_plugin("Custom skies", PLUGIN_VERSION, "Nordic Warrior");

    register_cvar("CustomSkies_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);
}

public plugin_precache()
{
    ReadConfig();

    SetRandomSky();
}

ReadConfig()
{
    new szConfigFile[MAX_RESOURCE_PATH_LENGTH];
    get_configsdir(szConfigFile, charsmax(szConfigFile));

    add(szConfigFile, charsmax(szConfigFile), fmt("/%s", CONFIG_FILE));

    new iFilePointer = fopen(szConfigFile, "r");

    if(!iFilePointer)
    {
        set_fail_state("File <%s> is missing or not enough rights!", szConfigFile);
        return;
    }

    new szBuffer[MAX_SKY_NAME_LENGTH];

    g_aListOfSkies = ArrayCreate(MAX_SKY_NAME_LENGTH, 1);

    while(!feof(iFilePointer))
    {
        fgets(iFilePointer, szBuffer, charsmax(szBuffer));
        trim(szBuffer);

        if(!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '#')
            continue;

        if(CheckAndPrecacheFiles(szBuffer))
        {
            ArrayPushString(g_aListOfSkies, szBuffer);
        }
    }
    fclose(iFilePointer);

    g_iArraySkiesSize = ArraySize(g_aListOfSkies);

    if(!g_iArraySkiesSize)
    {
        set_fail_state("File <%s> is empty or incorrect!", szConfigFile);
    }
}

CheckAndPrecacheFiles(szFileName[])
{
    static szFilePath[MAX_RESOURCE_PATH_LENGTH];
    static bool:bFileExists;

    for(new i; i < sizeof g_szTypeOfSky; i++)
    {
        formatex(szFilePath, charsmax(szFilePath), "gfx/env/%s%s.tga", szFileName, g_szTypeOfSky[i]);

        bFileExists = bool:file_exists(szFilePath);

        if(bFileExists)
        {
            precache_generic(szFilePath);
        }
        else
        {
            log_amx("File <%s> is missing!", szFilePath);
            break;
        }
    }
    return bFileExists;
}

SetRandomSky()
{
    new iRandomNumberSky = random(g_iArraySkiesSize);

    ArrayGetString(g_aListOfSkies, iRandomNumberSky, g_szSkyName, charsmax(g_szSkyName));

    server_cmd("sv_skyname %s", g_szSkyName);
}