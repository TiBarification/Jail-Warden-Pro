/*
 * MyJailbreak - Icons Plugin.
 * by: shanapu
 * https://github.com/shanapu/MyJailbreak/
 * 
 * Copyright (C) 2016-2017 Thomas Schmidt (shanapu)
 * Contributer: Kxnrl
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "2.0"

ConVar g_hWardenIcon;
// Integers
int g_iIcon[MAXPLAYERS + 1] = {-1, ...};

// Strings
char g_sIconWardenPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "[JWP] Icon",
	description = "Icon above warden",
	author = "shanapu & White Wolf",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/doctor_white"
};

public void OnPluginStart()
{
	g_hWardenIcon = CreateConVar("jwp_icon_warden_path", "decals/MyJailbreak/warden", "Path to the warden icon DONT TYPE .vmt or .vft");
	g_hWardenIcon.GetString(g_sIconWardenPath, sizeof(g_sIconWardenPath));
	g_hWardenIcon.AddChangeHook(OnCvarChange);
	
	AutoExecConfig(true, "icon", "jwp");

	// Hooks
	HookEvent("round_poststart", Event_PostRoundStart);
	HookEvent("player_death", Event_PlayerDeathTeam);
	HookEvent("player_team", Event_PlayerDeathTeam);
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_hWardenIcon)
	{
		if (newValue[0])
		{
			strcopy(g_sIconWardenPath, sizeof(g_sIconWardenPath), newValue);
		}
	}
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	RemoveIcon(client);
}

public void JWP_OnWardenChosen(int client)
{
	SpawnIcon(client);
}

public void Event_PostRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Timer_Delay);
}

public void Event_PlayerDeathTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid")); // Get the dead clients id

	RemoveIcon(client);
}

public void OnClientDisconnect(int client)
{
	RemoveIcon(client);
}

public Action Timer_Delay(Handle timer, Handle pack)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, true, false))
			continue;

		SpawnIcon(i);
	}
}

void SpawnIcon(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	RemoveIcon(client);

	char iconbuffer[256];
	if (g_sIconWardenPath[0])
	{
		if (JWP_IsWarden(client))
		{
			FormatEx(iconbuffer, sizeof(iconbuffer), "materials/%s.vmt", g_sIconWardenPath);
		}
	}

	if (!strlen(iconbuffer)) {
		return;
	}

	g_iIcon[client] = CreateEntityByName("env_sprite");

	if (g_iIcon[client] == -1)
		return;

	DispatchKeyValue(g_iIcon[client], "model", iconbuffer);
	DispatchKeyValue(g_iIcon[client], "classname", "env_sprite");
	DispatchKeyValue(g_iIcon[client], "spawnflags", "1");
	DispatchKeyValue(g_iIcon[client], "scale", "0.3");
	DispatchKeyValue(g_iIcon[client], "rendermode", "1");
	DispatchKeyValue(g_iIcon[client], "rendercolor", "255 255 255");
	if (DispatchSpawn(g_iIcon[client]))
	{
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] += 90.0;

		TeleportEntity(g_iIcon[client], origin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(g_iIcon[client], "SetParent", client, g_iIcon[client], 0);
	}
}

void RemoveIcon(int client) 
{
	if (g_iIcon[client] > 0 && IsValidEdict(g_iIcon[client]))
	{
		AcceptEntityInput(g_iIcon[client], "Kill");
		g_iIcon[client] = -1;
	}
}

// Check for valid clients with bool for bots & dead player 
stock bool IsValidClient(int client, bool bots = true, bool dead = true)
{
	if (client <= 0)
		return false;

	if (client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (IsFakeClient(client) && !bots)
		return false;

	if (IsClientSourceTV(client))
		return false;

	if (IsClientReplay(client))
		return false;

	if (!IsPlayerAlive(client) && !dead)
		return false;

	return true;
}
