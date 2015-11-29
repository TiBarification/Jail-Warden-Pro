// SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", velocidad)
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "speed"

ConVar Cvar_SpeedValue;
bool g_bSpeed;

public Plugin myinfo = 
{
	name = "[JWP] Speed",
	description = "Warden can toggle own speed",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	Cvar_SpeedValue = CreateConVar("jwp_warden_speed", "1.5", "Скорость командира", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	Cvar_SpeedValue.AddChangeHook(OnCvarChange);
	if (JWP_IsStarted()) JWC_Started();
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == Cvar_SpeedValue) Cvar_SpeedValue.SetFloat(StringToFloat(newValue));
}

public int JWC_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "[%s]Скорость", (g_bSpeed) ? "-" : "+");
	return true;
}

public bool OnFuncSelect(int client)
{
	g_bSpeed = !g_bSpeed;
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", (g_bSpeed) ? Cvar_SpeedValue.FloatValue : 1.0);
	JWP_ShowMainMenu(client);
	return true;
}