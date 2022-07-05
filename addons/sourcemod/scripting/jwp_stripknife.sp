#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define ITEM "stripknife"

bool g_bHaveKnife[MAXPLAYERS+1] = {true, ...};

public Plugin myinfo = 
{
	name = "[JWP] Strip Knife",
	description = "Warden can strip knife from terrorist",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWP_Started();
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	
	LoadTranslations("jwp_modules.phrases");
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
		g_bHaveKnife[i] = true;
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "StripKnife_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (!JWP_IsWarden(client)) return false;
	char langbuffer[32];
	Menu StripMenu = new Menu(StripMenu_Callback);
	Format(langbuffer, sizeof(langbuffer), "%T", "StripKnife_Title", LANG_SERVER);
	StripMenu.SetTitle(langbuffer);
	char id[4], name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i))
		{
			Format(name, sizeof(name), "[%s]%N", (g_bHaveKnife[i]) ? '+' : '-', i);
			IntToString(i, id, sizeof(id));
			StripMenu.AddItem(id, name);
		}
	}
	if (!StripMenu.ItemCount)
	{
		Format(langbuffer, sizeof(langbuffer), "%T", "General_No_Alive_Prisoners", LANG_SERVER);
		StripMenu.AddItem("", langbuffer, ITEMDRAW_DISABLED);
	}
	StripMenu.ExitBackButton = true;
	StripMenu.Display(client, MENU_TIME_FOREVER);
	return true;
}

public int StripMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack && JWP_IsWarden(client))
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			if (JWP_IsWarden(client))
			{
				char info[4];
				menu.GetItem(slot, info, sizeof(info));
				
				int target = StringToInt(info);
				if (target && CheckClient(target))
				{
					if (g_bHaveKnife[target])
					{
						int weapon = GetPlayerWeaponSlot(target, 2);
						if (IsValidEdict(weapon))
							AcceptEntityInput(weapon, "Kill");
						JWP_ActionMsgAll("%T", "StripKnife_ActionMessage_Taken", LANG_SERVER, client, target);
						g_bHaveKnife[target] = false;
					}
					else
					{
						GivePlayerItem(target, "weapon_knife");
						JWP_ActionMsgAll("%T", "StripKnife_ActionMessage_Given", LANG_SERVER, client, target);
						g_bHaveKnife[target] = true;
					}
				}
				else
					JWP_ActionMsg(client, "%T", "StripKnife_ActionMessage_Unable", LANG_SERVER);
				
				if (client && IsClientInGame(client) && JWP_IsWarden(client))
					OnFuncSelect(client);
			}
		}
	}

	return 0;
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client));
}