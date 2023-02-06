/* 
	by Eugene N. [Russia, Lipetsk]
	ICQ 833783
 */

#if defined _geoipse_included
	#endinput
#endif
#define _geoipse_included

#pragma reqlib geoipse
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib geoipse
#endif

// IP addresses passed to these natives can contain ports, the ports will be ignored.

/**
 * Lookup the full city name for the given IP address. Sets the buffer to "error" on unsuccessful lookup.
 *
 * @param ip		The IP address to lookup.
 * @param result	The result of the geoip lookup.
 * @param len		The maximum length of the result buffer.
 */
native geoip_city( const ip[], result[], len=45 );


/**
 * Lookup the city's latitude for the given IP address. Returns 0 if latitude is not found.
 *
 * @param ip	The IP address to lookup.
 * @return		The result of the geoip lookup. (float)
 */
native Float:geoip_latitude( const ip[] );


/**
 * Lookup the city's longitude for the given IP address. Returns 0 if longitude is not found.
 *
 * @param ip	The IP address to lookup.
 * @return		The result of the geoip lookup. (float)
 */
native Float:geoip_longitude( const ip[] );
native geoip_country( const ip[], result[], len=45 );
