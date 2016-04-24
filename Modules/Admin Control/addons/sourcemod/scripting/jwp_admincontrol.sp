#include <sourcemod>
#include <cstrike>
#include <adminmenu>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required;

#define PLUGIN_VERSION "1.1"

Handle hAdminMenu = null;
Menu g_mAdminControlMain;

public Plugin myinfo =
{
	name = "[JWP] Admin Control",
	description = "Admin can set or remove warden",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWP_Started();
}

public void JWP_Started()
{
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == hAdminMenu) return; /* Block us from being called twice */
	hAdminMenu = topmenu;
	
	TopMenuObject player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands == INVALID_TOPMENUOBJECT) return; /* Error */
	AddToTopMenu(hAdminMenu, "jwp_admincontrol", TopMenuObject_Item, AdminMenu_AdminControl, player_commands, "jwp_admincontrol", ADMFLAG_BAN);
	
	/* Create custom menu */
	g_mAdminControlMain = new Menu(AdminControlMain_Callback);
	g_mAdminControlMain.SetTitle("Управление командиром:\n\n");
	g_mAdminControlMain.AddItem("", "Сменить командира");
	g_mAdminControlMain.AddItem("", "Удалить командира");
	g_mAdminControlMain.ExitBackButton = true;
}

public void AdminMenu_AdminControl(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		strcopy(buffer, maxlength, "Командование");
	else if (action == TopMenuAction_SelectOption)
		g_mAdminControlMain.Display(param, MENU_TIME_FOREVER);
}

public int AdminControlMain_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (param2 == 0)
			{
				char id[4], name[MAX_NAME_LENGTH];
				Menu mPlayerMenu = new Menu(mPlayerMenu_Callback);
				mPlayerMenu.SetTitle("Выберите нового командира:\n");
				for (int i = 1; i <= MaxClients; ++i)
				{
					if (IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_CT) && !JWP_IsWarden(i) && IsPlayerAlive(i))
					{
						IntToString(i, id, sizeof(id));
						GetClientName(i, name, sizeof(name));
						mPlayerMenu.AddItem(id, name);
					}
				}
				mPlayerMenu.ExitBackButton = true;
				mPlayerMenu.Display(param1, MENU_TIME_FOREVER);
			}
			else if (param2 == 1)
			{
				int warden = JWP_GetWarden();
				if (warden)
				{
					ShowActivity2(param1, "[SM] ", "снял %N с поста командира", warden);
					JWP_SetWarden(0);
				}
				else
					ReplyToCommand(param1, "[SM] Не удалось снять командира с поста");
			}
		}
	}
}

public int mPlayerMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				g_mAdminControlMain.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_Select:
		{
			char id[4];
			menu.GetItem(param2, id, sizeof(id));
			int target = StringToInt(id);
			if (JWP_SetWarden(target))
				ShowActivity2(param1, "[SM] ", "сменил командира на %N", target);
			else
				ReplyToCommand(param1, "[SM] Не удалось сменить командира");
			g_mAdminControlMain.Display(param1, MENU_TIME_FOREVER);
		}
	}
}