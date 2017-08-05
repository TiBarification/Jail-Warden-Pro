#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools_engine>
#include <sdktools_functions>
#include <csgo_colors>

public Plugin:myinfo = 
{
	name	= "[JB] Anti-AFK",
	author	= "Bristwex,BaFeR",
	version	= "1.4.1[PRIVATE]"
};

new Float:g_fEyePosition[MAXPLAYERS + 1][3];
new bool:g_bChangeTeam[MAXPLAYERS + 1];
new Handle:g_hTimer;
new g_iCheck;

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.5, Timer_GetEyePosition, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_GetEyePosition(Handle:timer, any:iUserId)
{
	new client = GetClientOfUserId(iUserId);
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		GetClientAbsOrigin(client, g_fEyePosition[client]);
	}

	return Plugin_Stop;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
	}
	
	g_iCheck = 0;
	g_hTimer = CreateTimer(5.0, Timer_CheckEyePosition, _, TIMER_REPEAT);
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}

public Action:Timer_CheckEyePosition(Handle:timer)
{
	if (++g_iCheck == 3)
	{
		CheckEyePosition(CS_TEAM_CT);
	}
	else if (g_iCheck == 12)
	{
		CheckEyePosition(CS_TEAM_T);
		
		g_hTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

CheckEyePosition(iTeam)
{
	new Float:fEyePosition[3];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
		{
			GetClientAbsOrigin(i, fEyePosition);
			if (fEyePosition[0] == g_fEyePosition[i][0] 
			&& fEyePosition[1] == g_fEyePosition[i][1] 
			&& fEyePosition[2] == g_fEyePosition[i][2])
			{
				ForcePlayerSuicide(i);
				CGOPrintToChatAll("{GREEN}[{RED}F{PURPLE}'{BLUE}T{GREEN}] {RED}%N{DEFAULT}<--AFK-Игрок Убит!",i);
				if (iTeam == CS_TEAM_CT)
				{
					if (g_bChangeTeam[i])
					{
						ChangeClientTeam(i, CS_TEAM_T);
					}
					else
						//PrintToChat(i, " \x02Вас перекинет за Т, если Вы будете в следующий раз AFK!");
						CGOPrintToChatAll("{GREEN}[{RED}F{PURPLE}'{BLUE}T{GREEN}] {BLUE}%N {DEFAULT}получает  1/2 предупреждений",i);
					
					g_bChangeTeam[i] = !g_bChangeTeam[i];
				}
			}
		}
	}
}