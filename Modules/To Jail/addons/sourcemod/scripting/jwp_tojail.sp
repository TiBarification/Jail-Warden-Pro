#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "tojail"

float g_fCoords[MAXPLAYERS+1][3];

public Plugin myinfo = 
{
	name = "[JWP] To Jail",
	description = "Warden can teleport terrorist to jail",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_Post);
	if (JWP_IsStarted()) JWC_Started();
}

public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (CheckClient(i))
			GetClientAbsOrigin(i, g_fCoords[i]);
	}
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
	FormatEx(buffer, maxlength, "Вернуть в камеру");
	return true;
}

public bool OnFuncSelect(int client)
{
	Menu ToJailMenu = new Menu(ToJailMenu_Callback);
	ToJailMenu.SetTitle("Вернуть в камеру:");
	char id[4], name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			Format(name, sizeof(name), "%N", i);
			IntToString(i, id, sizeof(id));
			ToJailMenu.AddItem(id, name);
		}
	}
	if (!ToJailMenu.ItemCount)
		ToJailMenu.AddItem("", "Нет живых зеков", ITEMDRAW_DISABLED);
	ToJailMenu.ExitBackButton = true;
	ToJailMenu.Display(client, MENU_TIME_FOREVER);
	return true;
}

public int ToJailMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(slot, info, sizeof(info));
			
			int target = StringToInt(info);
			if (target && CheckClient(target) && GetClientTeam(target) == CS_TEAM_T)
			{
				if (CoordsExists(target))
				{
					if (TeleportEntity(target, g_fCoords[target], NULL_VECTOR, NULL_VECTOR))
						JWP_ActionMsgAll("%N: телепортировал зека %N обратно в камеру", client, target);
				}
				else
					JWP_ActionMsg(client, "Не удалось телепортировать игрока %N", target);
			}
			else
				JWP_ActionMsg(client, "Не удалось телепортировать в камеру");
			JWP_ShowMainMenu(client);
		}
	}
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && IsPlayerAlive(client));
}

bool CoordsExists(int client)
{
	if (g_fCoords[client][0] != 0.0 && g_fCoords[client][1] != 0.0 && g_fCoords[client][2] != 0.0)
		return true;
	return false;
}