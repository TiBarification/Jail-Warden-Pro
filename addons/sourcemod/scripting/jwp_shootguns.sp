#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_CvarAccess;

public Plugin myinfo = 
{
	name = "[JWP] Shootguns",
	description = "Remove guns on ground by shoot on them",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarAccess = CreateConVar("jwp_shootguns_access", "2", "Who can remove weapons on shoot 1 - warden / 2 - warden & deputy / 3 - every ct", _, true, 1.0, true, 3.0);
	AutoExecConfig(true, "shootguns", "jwp");
	
	HookEvent("bullet_impact", Event_OnBulletImpact);
}

public void Event_OnBulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	int ent = GetClientAimTarget(client, false);
	
	int iAccess = g_CvarAccess.IntValue;
	
	switch (iAccess)
	{
		case 1:
		{
			if (JWP_IsWarden(client) && isValidWeapon(ent))
			{
				AcceptEntityInput(ent, "Kill");
			}
		}
		case 2:
		{
			if ((JWP_IsWarden(client) || JWP_IsZamWarden(client)) && isValidWeapon(ent))
			{
				AcceptEntityInput(ent, "Kill");
			}
		}
		case 3:
		{
			if (GetClientTeam(client) == CS_TEAM_CT && isValidWeapon(ent))
			{
				AcceptEntityInput(ent, "Kill");
			}
		}
	}
}

bool isValidWeapon(int ent)
{
	if (ent > (MaxClients+1) && ent <= 2048 && IsValidEntity(ent))
	{
		char cBuffer[48];
		if (GetEntityClassname(ent, cBuffer, sizeof(cBuffer)))
		{
			if (StrContains(cBuffer, "weapon_", true) != -1)
				return true;
		}
	}
	
	return false;
}