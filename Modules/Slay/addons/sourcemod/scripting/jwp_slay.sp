#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "slay"

public Plugin myinfo = 
{
	name = "[JWP] Slay",
	description = "Warden can slay terrorists",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWC_Started();
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
	FormatEx(buffer, maxlength, "Убить зека");
	return true;
}

public bool OnFuncSelect(int client)
{
	Menu SlayMenu = new Menu(SlayMenu_Callback);
	SlayMenu.SetTitle("Убить зека:");
	char id[4], name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i))
		{
			Format(name, sizeof(name), "%N", i);
			IntToString(i, id, sizeof(id));
			SlayMenu.AddItem(id, name);
		}
	}
	if (!SlayMenu.ItemCount)
		SlayMenu.AddItem("", "Нет живых зеков", ITEMDRAW_DISABLED);
	SlayMenu.ExitBackButton = true;
	SlayMenu.Display(client, MENU_TIME_FOREVER);
	return true;
}

public int SlayMenu_Callback(Menu menu, MenuAction action, int client, int slot)
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
			
			int target = StringToInt(info, sizeof(info));
			if (CheckClient(target))
			{
				ForcePlayerSuicide(target);
				JWP_ActionMsgAll("%N: убил зека %N", client, target);
			}
			else
				JWP_ActionMsg(client, "Не удалось убить игрока. Возможно он ливнул?");
			JWP_ShowMainMenu(client);
		}
	}
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T) && IsPlayerAlive(client));
}