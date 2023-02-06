#include <amxmodx>
#define MAX_CVARS 150
new g_Cvars[MAX_CVARS][64],g_CvarsCount;
public plugin_init(){register_plugin("Hide Server Cvars","1.0","DJ_WEST");new s_File[128];static s_Error[]="[CEPBEP] Упс! Файл hide_cvars.ini не обнаружен!";get_configsdir(s_File,charsmax(s_File));format(s_File,charsmax(s_File),"%s/hide_cvars.ini",s_File);if(file_exists(s_File)){set_task(0.1,"Read_HideCvars",0,s_File,charsmax(s_File));}else{server_print(s_Error);log_amx(s_Error);}}
public Read_HideCvars(const s_FilePath[]){
	new s_Line[64],i_LineCount,i_LineLen,i_Index;while(read_file(s_FilePath,i_LineCount++,s_Line,charsmax(s_Line),i_LineLen)){if(i_LineLen&&(!equal(s_Line,"//",2))){g_Cvars[i_Index]=s_Line;i_Index++;}}
	g_CvarsCount=i_Index;set_task(0.1,"Hide_Cvars");return PLUGIN_HANDLED;
}
public Hide_Cvars(){new i_Flags,s_Cvar[64];for(new i=0;i<g_CvarsCount;i++){s_Cvar=g_Cvars[i];if(cvar_exists(s_Cvar)){i_Flags=get_cvar_flags(s_Cvar);remove_cvar_flags(s_Cvar);if(i_Flags >= 32){set_cvar_flags(s_Cvar,i_Flags&~FCVAR_SERVER|FCVAR_PROTECTED);}else{set_cvar_flags(s_Cvar,i_Flags&~FCVAR_SERVER);}}}}
stock get_configsdir(s_Name[],i_Len){return get_localinfo("amxx_configsdir",s_Name,i_Len);}