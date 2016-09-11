#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define ITEM "speed"

ConVar Cvar_AutoSpeed, Cvar_SpeedValue;
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
	Cvar_AutoSpeed = CreateConVar("jwp_warden_autospeed", "1", "Enable speed of warden by default", _, true, 0.0, true, 1.0);
	Cvar_SpeedValue = CreateConVar("jwp_warden_speed", "1.5", "Скорость командира", _, true, 1.0, true, 3.0);
	if (JWP_IsStarted()) JWP_Started();
	AutoExecConfig(true, ITEM, "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void JWP_OnWardenChosen(int client)
{
	if (Cvar_AutoSpeed.IntValue)
		g_bSpeed = true;
	else
		g_bSpeed = false;
	
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", (g_bSpeed) ? Cvar_SpeedValue.FloatValue : 1.0);
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
	JWP_RemoveFromMainMenu();
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