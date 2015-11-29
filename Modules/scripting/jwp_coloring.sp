#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "coloring"

bool g_bColoring;

public Plugin myinfo = 
{
	name = "[JWP] Coloring",
	description = "Warden can divide players of terrorist team",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	if (JWP_IsStarted()) JWC_Started();
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bColoring = false;
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bColoring = false;
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
	FormatEx(buffer, maxlength, "[%s]Разделить по цветам", (g_bColoring) ? "-" : "+");
	return true;
}

public bool OnFuncSelect(int client)
{
	g_bColoring = !g_bColoring;
	if (g_bColoring)
	{
		bool red;
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i) && !JWP_PrisonerHasFreeday(i))
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				
				red = !red;
				if (red)
				{
					SetEntityRenderColor(i, 255, 0, 0, 255);
					PrintToChat(i, "\x01\x04Ваш цвет: КРАСНЫЙ");
				}
				else
				{
					SetEntityRenderColor(i, 0, 0, 255, 255);
					PrintToChat(i, "\x01\x04Ваш цвет: СИНИЙ");
				}
			}
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i) && !JWP_PrisonerHasFreeday(i))
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, 255, 255, 255, 255);
				PrintToChat(i, "\x01\x04Ваш цвет: СТАНДАРТНЫЙ");
			}
		}
	}
	JWP_ActionMsg(client, "\x03Разделение по цветам \x02%s", (g_bColoring) ? "включено" : "отключено")
	JWP_ShowMainMenu(client);
	return true;
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && /* !IsFakeClient(client) && */ (GetClientTeam(client) == CS_TEAM_T) && IsPlayerAlive(client));
}