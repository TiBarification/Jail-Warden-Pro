#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"
#define ITEM "speed"

ConVar Cvar_SpeedValue;
bool g_bSpeed;

public Plugin myinfo = 
{
	name = "[JWP] Speed",
	description = "Warden can toggle own speed",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	Cvar_SpeedValue = CreateConVar("jwp_warden_speed", "1.5", "Скорость командира", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	if (JWP_IsStarted()) JWP_Started();
	AutoExecConfig(true, ITEM, "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void JWP_OnWardenChosen(int client)
{
	g_bSpeed = false;
}

public void JWP_OnWardenResigned(int client)
{
	if (client && IsClientInGame(client))
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	g_bSpeed = false;
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "[%s]%T", (g_bSpeed) ? '-' : '+', "Speed_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	char langbuffer[24];
	g_bSpeed = !g_bSpeed;
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", (g_bSpeed) ? Cvar_SpeedValue.FloatValue : 1.0);
	if (g_bSpeed)
	{
		Format(langbuffer, sizeof(langbuffer), "[-]%T", "Speed_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, langbuffer);
	}
	else
	{
		Format(langbuffer, sizeof(langbuffer), "[+]%T", "Speed_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, langbuffer);
	}
	JWP_ShowMainMenu(client);
	return true;
}