#include <sourcemod>
#include <cstrike>
#include <adminmenu>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required;

#define PLUGIN_VERSION "1.3"

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
	LoadTranslations("jwp_modules.phrases");
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
	char lang[48];
	FormatEx(lang, sizeof(lang), "%T", "Admin_Control_Title", LANG_SERVER);
	g_mAdminControlMain.SetTitle(lang);
	FormatEx(lang, sizeof(lang), "%T", "Admin_Control_Change", LANG_SERVER);
	g_mAdminControlMain.AddItem("", lang);
	FormatEx(lang, sizeof(lang), "%T", "Admin_Control_Remove", LANG_SERVER);
	g_mAdminControlMain.AddItem("", lang);
	g_mAdminControlMain.ExitBackButton = true;
}

public void AdminMenu_AdminControl(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "Admin_Control_Main", LANG_SERVER);
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
				char lang[48];
				FormatEx(lang, sizeof(lang), "%T", "Admin_Control_Choose", LANG_SERVER);
				mPlayerMenu.SetTitle(lang);
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
					ShowActivity2(param1, "[SM] ", "%T", "Admin_Control_FiredActivity", LANG_SERVER, warden);
					JWP_SetWarden(0);
				}
				else
					ReplyToCommand(param1, "[SM] %T", "Admin_Control_FiredFailed", LANG_SERVER);
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
				ShowActivity2(param1, "[SM] ", "Admin_Control_ChangeActivity", LANG_SERVER, target);
			else
				ReplyToCommand(param1, "[SM] %T", "Admin_Control_ChangeFailed", LANG_SERVER);
			g_mAdminControlMain.Display(param1, MENU_TIME_FOREVER);
		}
	}
}