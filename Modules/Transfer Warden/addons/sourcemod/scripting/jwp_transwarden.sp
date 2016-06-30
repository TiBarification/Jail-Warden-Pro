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
	version = "1.1",
	url = "https://tibari.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWP_Started();
	LoadTranslations("jwp_modules.phrases");
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
	FormatEx(buffer, maxlength, "%T", "TransWarden_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	Menu ctList = new Menu(ctList_Callback);
	char lang[48];
	FormatEx(lang, sizeof(lang), "%T", "TransWarden_Title", LANG_SERVER);
	ctList.SetTitle(lang);
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
	{
		FormatEx(lang, sizeof(lang), "%T", "TransWarden_NoCT", LANG_SERVER);
		ctList.AddItem("", lang, ITEMDRAW_DISABLED);
	}
	
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
				JWP_ActionMsgAll("\x04%T", "TransWarden_Action", LANG_SERVER, param1, target);
				JWP_SetWarden(target);
			}
		}
	}
}