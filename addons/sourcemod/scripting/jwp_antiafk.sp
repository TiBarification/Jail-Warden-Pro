#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools_engine>
#include <sdktools_functions>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.4.2"

public Plugin myinfo = 
{
	name	= "[JWP] Anti-AFK",
	description = "Kills a player who did not show signs of life for a certain time",
	author	= "Bristwex,BaFeR",
	version	= PLUGIN_VERSION,
	url = "https://github.com/mrkos9i4ok/Jail-Warden-Pro"
};

float g_fEyePosition[MAXPLAYERS + 1][3];
Handle g_hTimer;
int g_iCheck;

public void OnPluginStart()
{
	LoadTranslations("jwp_modules.phrases");

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	//LoadTranslations("jwp_modules.phrases");
	//if (JWP_IsStarted()) JWP_Started();
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.5, Timer_GetEyePosition, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_GetEyePosition(Handle timer, any iUserId)
{
	int client = GetClientOfUserId(iUserId);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		GetClientAbsOrigin(client, g_fEyePosition[client]);
	}

	return Plugin_Stop;
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
	}
	
	g_iCheck = 0;
	g_hTimer = CreateTimer(5.0, Timer_CheckEyePosition, _, TIMER_REPEAT);
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}

public Action Timer_CheckEyePosition(Handle timer)
{
	if (++g_iCheck == 3)  //15 sec after round start
	{
		CheckEyePosition(CS_TEAM_CT);  //guards
	}
	else if (g_iCheck == 12) //60 sec after round start
	{
		CheckEyePosition(CS_TEAM_T);  //prisoners
		
		g_hTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void CheckEyePosition(int iTeam)
{
	float fEyePosition[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
		{
			GetClientAbsOrigin(i, fEyePosition);
			if (fEyePosition[0] == g_fEyePosition[i][0] 
			&& fEyePosition[1] == g_fEyePosition[i][1] 
			&& fEyePosition[2] == g_fEyePosition[i][2])
			{
				ForcePlayerSuicide(i);
				JWP_ActionMsgAll("%T %T", "antiafk_tag", "antiafk_kill", i);
				if (iTeam == CS_TEAM_CT)
				{
					ChangeClientTeam(i, CS_TEAM_T);
				}
			}
		}
	}
}
