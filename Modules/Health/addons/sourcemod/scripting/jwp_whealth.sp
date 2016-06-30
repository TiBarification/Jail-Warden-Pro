#include <sourcemod>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

ConVar	g_CvarWardenHealth,
		g_CvarWardenZamHealth;

public Plugin myinfo = 
{
	name = "[JWP] Warden health",
	description = "Health for warden and him zam",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarWardenHealth = CreateConVar("jwp_warden_hp", "150", "Здоровье командира", _, true, 100.0);
	g_CvarWardenZamHealth = CreateConVar("jwp_warden_zam_hp", "140", "Здоровье ЗАМа командира", _, true, 100.0);
	
	AutoExecConfig(true, "whealth", "jwp");
}

public void JWP_OnWardenChosen(int client)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
		SetEntityHealth(client, g_CvarWardenHealth.IntValue);
}

public void JWP_OnWardenZamChosen(int client)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
		SetEntityHealth(client, g_CvarWardenZamHealth.IntValue);
}

public void JWP_OnWardenResigned(int client, bool self)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientHealth(client) > 100))
		SetEntityHealth(client, 100);
}