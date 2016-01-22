#include <sourcemod>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar	g_CvarWardenHealth,
		g_CvarWardenZamHealth;

public Plugin myinfo = 
{
	name = "[JWP] Warden health",
	description = "Health for warden and him zam",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarWardenHealth = CreateConVar("jwp_warden_hp", "150", "Здоровье командира", FCVAR_PLUGIN, true, 100.0);
	g_CvarWardenZamHealth = CreateConVar("jwp_warden_zam_hp", "140", "Здоровье ЗАМа командира", FCVAR_PLUGIN, true, 100.0);
	
	g_CvarWardenHealth.AddChangeHook(OnCvarChange);
	g_CvarWardenZamHealth.AddChangeHook(OnCvarChange);
	
	AutoExecConfig(true, "whealth", "jwp");
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarWardenHealth)
		cvar.SetInt(StringToInt(newValue));
	else if (cvar == g_CvarWardenZamHealth)
		cvar.SetInt(StringToInt(newValue));
}

public int JWP_OnWardenChosen(int client)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
		SetEntityHealth(client, g_CvarWardenHealth.IntValue);
}

public int JWP_OnWardenZamChosen(int client)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
		SetEntityHealth(client, g_CvarWardenZamHealth.IntValue);
}

public int JWP_OnWardenResigned(int client, bool self)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientHealth(client) > 100))
		SetEntityHealth(client, 100);
}