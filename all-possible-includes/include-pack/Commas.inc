#if !defined COMMAS_H

#define COMMAS_H

#include <amxmodx>

stock AddCommas( iNum , szOutput[] , iLen ){
	static szTmp[ 15 ] , iOutputPos , iNumPos , iNumLen;
	szTmp[0]='^0',iOutputPos=iNumPos=iNumLen=0;
	if ( iNum < 0 ){
		szOutput[ iOutputPos++ ] = '-';
		iNum = abs( iNum );}
	iNumLen = num_to_str( iNum , szTmp , charsmax( szTmp ) );
	if ( iNumLen <= 3 )iOutputPos += copy( szOutput[ iOutputPos ] , iLen , szTmp );
	else{
		while ( ( iNumPos < iNumLen ) && ( iOutputPos < iLen ) ){
			szOutput[ iOutputPos++ ] = szTmp[ iNumPos++ ];
			if( ( iNumLen - iNumPos ) && !( ( iNumLen - iNumPos ) % 3 ) )szOutput[ iOutputPos++ ] = ',';
		}
		szOutput[ iOutputPos ] = EOS;
	}return iOutputPos;}

#endif
