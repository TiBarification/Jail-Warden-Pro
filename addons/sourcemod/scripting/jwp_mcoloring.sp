#include <sourcemod>
#include <cstrike>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required
#define PLUGIN_VERSION "1.1"
#define ITEM "mcoloring"

KeyValues g_Kv;
Menu g_ColorsMenu;
int g_iTarget;

public Plugin myinfo =
{
	name = "[JWP] Manual Coloring",
	description = "Manual player coloring",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru http://tibari.ru"
};

public void OnPluginStart()
{
	LoadTranslations("jwp_modules.phrases");
	if (JWP_IsStarted()) JWP_Started();
}

public void JWP_Started()
{
	LoadColors();
	
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Manual_Coloring_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		PlayerListMenu(client);
		return true;
	}
	return false;
}

public int plList_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && JWP_IsWarden(param1))
				JWP_ShowMainMenu(param1);
		}
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			if (JWP_IsWarden(param1))
			{
				char idx[4];
				menu.GetItem(param2, idx, sizeof(idx));
				g_iTarget = StringToInt(idx);
				if (g_iTarget && IsClientInGame(g_iTarget) && GetClientTeam(g_iTarget) == CS_TEAM_T && IsPlayerAlive(g_iTarget))
					g_ColorsMenu.Display(param1, MENU_TIME_FOREVER);
				else
					JWP_ActionMsg(param1, "%T", "Manual_Coloring_UnableToColor", LANG_SERVER);
			}
		}
	}

	return 0;
}

public int ColorsMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && JWP_IsWarden(param1))
				PlayerListMenu(param1);
		}
		case MenuAction_Select:
		{
			if (JWP_IsWarden(param1))
			{
				char c_name[16];
				menu.GetItem(param2, c_name, sizeof(c_name));
				
				if (c_name[0] && g_Kv.JumpToKey(c_name, false))
				{
					if (g_iTarget && IsClientInGame(g_iTarget) && GetClientTeam(g_iTarget) == CS_TEAM_T && IsPlayerAlive(g_iTarget))
					{
						int color[4];
						SetEntityRenderMode(g_iTarget, RENDER_TRANSCOLOR);
						g_Kv.GetColor4("rgba", color);
						SetEntityRenderColor(g_iTarget, color[0], color[1], color[2], color[3]);
					}
					g_Kv.Rewind();
				}
				
				JWP_ShowMainMenu(param1);
			}
		}
	}

	return 0;
}

void PlayerListMenu(int client)
{
	char idx[4], name[PLATFORM_MAX_PATH];
	Menu plList = new Menu(plList_Callback);
	char lang[48];
	FormatEx(lang, sizeof(lang), "%T", "Manual_Coloring_Choose", LANG_SERVER);
	plList.SetTitle(lang);
	plList.ExitButton = true;
	plList.ExitBackButton = true;
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			IntToString(i, idx, sizeof(idx));
			GetClientName(i, name, sizeof(name));
			plList.AddItem(idx, name);
		}
	}
	plList.Display(client, MENU_TIME_FOREVER);
}

void LoadColors()
{
	g_Kv = new KeyValues("Colors");
	g_ColorsMenu = new Menu(ColorsMenu_Callback);
	char lang[48];
	FormatEx(lang, sizeof(lang), "%T", "Manual_Coloring_ChooseColor", LANG_SERVER);
	g_ColorsMenu.SetTitle(lang);
	if (!g_Kv.ImportFromFile("cfg/jwp/colors/mcolors.txt"))
	{
		SetFailState("Unable to open file mcolors.txt");
		return;
	}
	
	if (g_Kv.GotoFirstSubKey(true))
	{
		char c_name[16];
		do
		{
			if (g_Kv.GetSectionName(c_name, sizeof(c_name)))
				g_ColorsMenu.AddItem(c_name, c_name);
		} while (g_Kv.GotoNextKey(true));
		
		g_Kv.Rewind();
		g_ColorsMenu.ExitButton = true;
		g_ColorsMenu.ExitBackButton = true;
	}
	else
	{
		SetFailState("Unable to read KeyValues for 'mcolors'");
		return;
	}
}