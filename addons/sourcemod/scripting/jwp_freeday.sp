#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.4"
#define FDGIVE "freeday_give"
#define FDTAKE "freeday_take"

public Plugin myinfo = 
{
	name = "[JWP] Freeday",
	description = "Give/Take freeday",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWP_Started();
	
	AutoExecConfig(true, "freeday", "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void JWP_Started()
{
	JWP_AddToMainMenu(FDGIVE, OnFuncFDGiveDisplay, OnFuncFDGiveSelect);
	JWP_AddToMainMenu(FDTAKE, OnFuncFDTakeDisplay, OnFuncFDTakeSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}
public bool OnFuncFDGiveDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Freeday_Menu_Give", LANG_SERVER);
	return true;
}

public bool OnFuncFDGiveSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		ShowFreedayMenu(client, false);
		return true;
	}
	return false;
}

public bool OnFuncFDTakeDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Freeday_Menu_Take", LANG_SERVER);
	return true;
}

public bool OnFuncFDTakeSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		ShowFreedayMenu(client, true);
		return true;
	}
	return false;
}

void ShowFreedayMenu(int client, bool fd_players)
{
	char id[4], name[MAX_NAME_LENGTH], langphrases[48];
	Menu PList = new Menu(PList_Callback);
	if (fd_players)
	{
		Format(langphrases, sizeof(langphrases), "%T \n", "Freeday_Players_TakeFD_Title", LANG_SERVER);
		PList.SetTitle(langphrases);
	}
	else
	{
		Format(langphrases, sizeof(langphrases), "%T \n", "Freeday_Players_GiveFD_Title", LANG_SERVER);
		PList.SetTitle(langphrases);
	}
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i))
		{
			GetClientName(i, name, sizeof(name))
			if (fd_players && JWP_PrisonerHasFreeday(i))
			{
				IntToString(i, id, sizeof(id));
				PList.AddItem(id, name);
			}
			else if (!fd_players && !JWP_PrisonerHasFreeday(i))
			{
				IntToString(i, id, sizeof(id));
				PList.AddItem(id, name);
			}
		}
	}
	if (!PList.ItemCount)
	{
		Format(langphrases, sizeof(langphrases), "%T", "General_No_Prisoners", LANG_SERVER);
		PList.AddItem("", langphrases, ITEMDRAW_DISABLED);
	}
	PList.ExitBackButton = true;
	PList.Display(client, MENU_TIME_FOREVER);
}

public int PList_Callback(Menu menu, MenuAction action, int client, int slot)
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
				bool state = JWP_PrisonerHasFreeday(target);
				
				bool b = state;
				if (target && CheckClient(target))
				{
					state = !state;
					
					JWP_PrisonerSetFreeday(target, state);
					JWP_ActionMsgAll("%T", (state) ? "Freeday_ActionMessage_Gived" : "Freeday_ActionMessage_Taken", LANG_SERVER, client, target);
				}
				menu.RemoveItem(slot);
				ShowFreedayMenu(client, b);
			}
		}
	}

	return 0;
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client));
}