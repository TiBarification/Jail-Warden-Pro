#include <sourcemod>
#include <sdkhooks>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[JWP] Freeday no weapon & rebel",
	description = "If player has freeday, he can't be a rebel",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnClientPutInServer(int client)
{
	if (client && IsClientInGame(client))
	{
		SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (attacker > 0 && (attacker <= MaxClients) && IsClientInGame(attacker) && JWP_PrisonerHasFreeday(attacker))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action OnWeaponEquip(int client, int weapon)
{
	if (JWP_PrisonerHasFreeday(client))
		return Plugin_Handled;
	return Plugin_Continue;
}