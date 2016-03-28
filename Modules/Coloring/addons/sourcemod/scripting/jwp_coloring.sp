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
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	if (JWP_IsStarted()) JWC_Started();
	
	LoadTranslations("jwp_modules.phrases");
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

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "[%s]%T", (g_bColoring) ? '-' : '+', "Coloring_Menu", LANG_SERVER);
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
					PrintToChat(i, "\x01\x04%T %T", "Coloring_Your_Color", LANG_SERVER, "Coloring_Red_Color", LANG_SERVER);
				}
				else
				{
					SetEntityRenderColor(i, 0, 0, 255, 255);
					PrintToChat(i, "\x01\x04%T %T", "Coloring_Your_Color", LANG_SERVER, "Coloring_Blue_Color", LANG_SERVER);
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
				PrintToChat(i, "\x01\x04%T %T", "Coloring_Your_Color", LANG_SERVER, "Coloring_Standart_Color", LANG_SERVER);
			}
		}
	}
	
	char menuitem[48];
	if (g_bColoring)
	{
		FormatEx(menuitem, sizeof(menuitem), "[-]%T", "Coloring_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	else
	{
		FormatEx(menuitem, sizeof(menuitem), "[+]%T", "Coloring_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	JWP_ActionMsg(client, "\x03%T \x02%T", "Coloring_ActionMessage", LANG_SERVER, (g_bColoring) ? "Coloring_State_On" : "Coloring_State_Off", LANG_SERVER);
	JWP_ShowMainMenu(client);
	return true;
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T) && IsPlayerAlive(client));
}