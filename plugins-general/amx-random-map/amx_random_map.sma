// Плагин скачан с https://amx-x.ru/viewtopic.php?t=41472

#include <amxmodx>
#include <amxmisc>

new const maps_list_file[] = "addons/amxmodx/configs/maps.ini"

#define PLUGIN "AMX Random Map"
#define VERSION "1.2.1"
#define AUTHOR "BOYSplayCS / Leo_[BH]"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_concmd("amx_random_map", "eventChangeMap", ADMIN_MAP, "<randomly change the map>");
}

public eventChangeMap(id, level, cid)
{
	if (cmd_access(id, level, cid, 1))
	{
		new szMap[128];
		
		if (GetRandomMap(maps_list_file, szMap, charsmax(szMap))){
			client_cmd(id, "amx_map %s", szMap);
		}
	}

	return PLUGIN_HANDLED;
}

GetRandomMap(const szMapFile[ ], szReturn[ ], const iLen)
{
	new iFile = fopen(szMapFile, "rt");
	
	if (!iFile)
	{
		return 0;
	}
	
	new Array:aMaps = ArrayCreate(64);
	new Trie:tArrayPos = TrieCreate( );
	new iTotal = 0;
	
	static szData[128], szMap[64];
	
	while (!feof(iFile))
	{
		fgets(iFile, szData, charsmax(szData));
		parse(szData, szMap, charsmax(szMap));
		strtolower(szMap);
		
		if (is_map_valid(szMap) && !TrieKeyExists(tArrayPos, szMap))
		{
			ArrayPushString(aMaps, szMap);
			TrieSetCell(tArrayPos, szMap, iTotal);
			
			iTotal++;
		}
	}
	
	TrieDestroy(tArrayPos);
	
	if (!iTotal)
	{
		ArrayDestroy(aMaps);
		
		return 0;
	}
	
	ArrayGetString(aMaps, random(iTotal), szReturn, iLen);
	
	ArrayDestroy(aMaps);
	
	fclose(iFile);
	
	return 1;
}

// Скачать плагины от Leo_[BH] = https://vk.com/cs_rain