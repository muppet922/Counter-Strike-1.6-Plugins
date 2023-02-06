native get_param(param);
native set_array(param, const source[], size);

enum 
{
	IpAddress,
	CountryName,
	CountryCode,
	CountryCode3,
	City,
	Region,
	RegionName,
	TimeZone,
	ContinentCode,
	ContinentName,
	Latitude,
	Longitude,
	PostalCode,
	MetroCode,
	AreaCode,

	__GEO_DATA_COUNT__
};

new Data[ 33 ][ __GEO_DATA_COUNT__ ][ 128 ], bool: Loaded[ 33 ];

StripName( Name[ ] ) 
{
	for( new i = 0; i < strlen( Name ); i++ ) 
	{
		Name[ i ] = tolower( Name[ i ] );

		if( !isalpha( Name[ i ] ) )
		{
			Name[ i ] = '_';
		}
	}
}

LoadData( Player ) 
{
	new Name[ 32 ];
	get_user_name( Player, Name, 31 );
	StripName( Name );
	new FileLine[ 256 ]
	formatex( FileLine, 255, "addons/SpecialGeoip/PlayerData/%s.ini", Name );
	new File = fopen( FileLine, "r" );
	if( File ) 
	{
		new Row[ 256 ], Key[ 128 ], Value[ 128 ], i = 0;

		while( !feof( File ) ) 
		{
			fgets( File, Row, 255 );
			trim( Row );
			if( Row[ 0 ] == '"' ) 
			{
				parse( Row, Key, 127, Value, 127 );
				if( i < __GEO_DATA_COUNT__ )
					formatex( Data[ Player ][ i ], 127, "%s", Value );
				i++;
			}
		}
		fclose( File );
		Loaded[ Player ] = true;
	}
}

public LoadPlayer( Player )
{
	if( is_user_connected( Player ) && !is_user_bot( Player ) )
	{
		LoadData( Player );
	}
}

public plugin_natives( ) 
{
	//register_library( "SpecialGeoip" );

	register_native( "GeoipInfo", "___GetGeoData___" );
}

public ___GetGeoData___( Plugin, Params ) 
{
	new Client = get_param( 1 ), DataType = get_param( 2 );

	if( is_user_connected( Client ) && !is_user_bot( Client ) && Loaded[ Client ] && DataType >= IpAddress && DataType < __GEO_DATA_COUNT__ )
		set_array( 3, Data[ Client ][ DataType ], get_param( 4 ) );
}