#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <zombieplague>

#define PLUGIN "Zombie Prevolution : Save Ammo Packs"
#define VERSION "1.0.0"
#define AUTHOR "Kia"

// ===============================================================================
//     Editing begins here
// ===============================================================================

// Add SQL Data here

new Host[]        = ""
new User[]        = ""
new Pass[]        = ""
new Db[]       = ""

// ===============================================================================
//     and stops here. DO NOT MODIFY BELOW UNLESS YOU KNOW WHAT YOU'RE DOING
// ===============================================================================

// ===============================================================================
//     Variables
// ===============================================================================

/* Booleans */

new bool:g_authed[33]
new bool:g_sql_ready = false
new bool:g_loaded[33]

/* Handler */

new Handle:g_SqlConnection
new Handle:g_SqlTuple

/* Strings */

new g_Error[512]

/* Integer */

new maxplayers;

// ===============================================================================
//     plugin_init
// ===============================================================================

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	    
	/* SQL */
	    
	maxplayers = get_maxplayers()
	set_task(0.1, "MySql_Init")
}

// ===============================================================================
//     client_putinserver - Called when a player joins the Server
// ===============================================================================

public client_putinserver(id)
{
	g_authed[id] = true
	Load_MySql(id)
}

// ===============================================================================
//     client_disconnect - Called when a player leaves the Server
// ===============================================================================

public client_disconnected(id)
{
	Save_MySql(id)
}

// ===============================================================================
//     SQL
// ===============================================================================

public MySql_Init()
{
	// we tell the API that this is the information we want to connect to,
	// just not yet. basically it's like storing it in global variables
	g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db)
	    
	// ok, we're ready to connect
	new ErrorCode
	g_SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,charsmax(g_Error))
	if(g_SqlConnection == Empty_Handle)
	{
		 // stop the plugin with an error message
		set_fail_state(g_Error)
	}
	    
	new Handle:Queries
	// we must now prepare some random queries
	Queries = SQL_PrepareQuery(g_SqlConnection,"CREATE TABLE IF NOT EXISTS zpre_ap (name varchar(64), ap INT(11))")
	    
	if(!SQL_Execute(Queries))
	{
		// if there were any problems
		SQL_QueryError(Queries,g_Error,charsmax(g_Error))
		set_fail_state(g_Error)
	}
	    
	// close the handle
	SQL_FreeHandle(Queries)
	    
	g_sql_ready = true
	for(new i=1; i<=maxplayers; i++)
	{
		if(g_authed[i])
		{
			Load_MySql(i)
		}
	}
}

public Load_MySql(id)
{
	if(g_sql_ready)
	{
		if(g_SqlTuple == Empty_Handle)
		{
			set_fail_state(g_Error)
		}
		
		new szPlayerName[32], szQuotedName[64], szTemp[512]
		get_user_name(id, szPlayerName, charsmax(szPlayerName))
		SQL_QuoteString(g_SqlConnection, szQuotedName, charsmax(szQuotedName), szPlayerName)
		new Data[1]
		Data[0] = id
			
		//we will now select from the table `furienmoney` where the steamid match
		format(szTemp,charsmax(szTemp),"SELECT * FROM `zpre_ap` WHERE `name` = '%s'", szQuotedName)
		SQL_ThreadQuery(g_SqlTuple,"register_client", szTemp, Data,1)
	}
}

public register_client(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error)
	}
	else if(FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Load Query failed. [%d] %s", Errcode, Error)
	}
	new id
	id = Data[0]
	if(SQL_NumResults(Query) < 1)
	{
		//.if there are no results found
			
		new szName[32], szQuotedName[64]
		get_user_name(id, szName, 31) // get user's name
		SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName)
			
		new szTemp[512]
			
		// now we will insert the values into our table.
		format(szTemp,charsmax(szTemp),"INSERT INTO `zpre_ap` VALUES ('%s','0');", szQuotedName)
		SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp)
	}
	else
	{
		// if there are results found
		zp_set_user_ammo_packs(id, SQL_ReadResult(Query, 1))
	}
	g_loaded[id] = true
	return PLUGIN_HANDLED
}

public Save_MySql(id)
{
	if(g_loaded[id])
	{
		new szTemp[512], szName[32], szQuotedName[64]
		get_user_name(id, szName, 31)
		SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName)
			
		// Here we will update the user hes information in the database where the steamid matches.
		format(szTemp,charsmax(szTemp),"UPDATE `zpre_ap` SET `ap` = '%i' WHERE `name` = '%s';", zp_get_user_ammo_packs(id), szQuotedName)
		SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp)
	}
}

public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	SQL_FreeHandle(Query)
	    
	return PLUGIN_HANDLED
}

public plugin_end()
{
	if(g_SqlConnection != Empty_Handle)
	{
		SQL_FreeHandle(g_SqlConnection) //free connection handle here
	}
}