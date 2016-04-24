#include <sourcemod>
#include <cstrike>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required
#define ITEM "transwarden"

public Plugin myinfo =
{
	name = "[JWP] Transfer warden",
	description = "Transfer warden rights to another player",
	author = "White Wolf",
	version = "1.0",
	url = "https://tibari.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWP_Started();
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "Передать КМД");
	return true;
}

public bool OnFuncSelect(int client)
{
	Menu ctList = new Menu(ctList_Callback);
	ctList.SetTitle("Передать КМД:");
	char userid[4], name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && i != client && IsPlayerAlive(i))
		{
			IntToString(i, userid, sizeof(userid));
			GetClientName(i, name, sizeof(name));
			ctList.AddItem(userid, name);
		}
	}
	if (!ctList.ItemCount)
		ctList.AddItem("", "Нет свободных КТ", ITEMDRAW_DISABLED);
	
	ctList.ExitBackButton = true;
	ctList.ExitButton = true;
	ctList.Display(client, MENU_TIME_FOREVER);
	return true;
}

public int ctList_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				JWP_ShowMainMenu(param1);
		}
		case MenuAction_Select:
		{
			char userid[4];
			menu.GetItem(param2, userid, sizeof(userid));
			int target = StringToInt(userid);
			
			if (target && IsClientInGame(target) && IsPlayerAlive(target))
			{
				JWP_ActionMsgAll("\x04%N \x06передал командование игроку \x02%N", param1, target);
				JWP_SetWarden(target);
			}
		}
	}
}