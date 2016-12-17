#define CMDMENU_PLUGIN 0
#define CMDMENU_DISPLAY 1
#define CMDMENU_SELECT 2

StringMap g_sMainMenuMap;
int g_iLastMenuItemPos;
Menu g_mMainMenu;

void Cmd_MenuCreateNatives()
{
	g_sMainMenuMap = new StringMap();
	
	CreateNative("JWP_AddToMainMenu", Cmd_AddToMainMenu);
	CreateNative("JWP_RemoveFromMainMenu", Cmd_RemoveFromMainMenu);
	CreateNative("JWP_ShowMainMenu", Cmd_ShowMainMenu);
}

public int Cmd_AddToMainMenu(Handle plugin, int numParams)
{
	char key[16];
	// Unique name of item
	GetNativeString(1, key, sizeof(key));
	DataPack dp = new DataPack();
	dp.WriteCell(plugin);
	dp.WriteFunction(GetNativeFunction(2));
	dp.WriteFunction(GetNativeFunction(3));
	if (!g_sMainMenuMap.SetValue(key, dp, false))
	{
		g_sMainMenuMap.GetValue(key, dp);
		if (dp != null) delete dp;
		
		LogToFile(LOG_PATH, "[WARNING] Failed to add module %s, already registered? Removing this module to avoid conflicts", key);
		g_sMainMenuMap.Remove(key);
		if (g_iWarden > 0)
			RehashMenu();
	}
}

public int Cmd_RemoveFromMainMenu(Handle plugin, int numParams)
{
	char key[16];
	
	StringMapSnapshot snap = g_sMainMenuMap.Snapshot();
	int len = snap.Length;
	bool found = false;
	DataPack dp;
	
	for (int i = 0; i < len; i++)
	{
		snap.GetKey(i, key, sizeof(key));
		if (g_sMainMenuMap.GetValue(key, dp))
		{
			if (dp != null)
			{
				dp.Reset();
				
				if (dp.ReadCell() == plugin)
				{
					delete dp;
					// LogToFile(LOG_PATH, "[DEBUG] Removed module %s", key);
					g_sMainMenuMap.Remove(key);
					if (g_iWarden > 0)
						RehashMenu();
					found = true;
				}
			}
		}
	}
	
	delete snap;
	
	if (found) return 1;
	else
	{
		char info[24];
		GetPluginInfo(plugin, PlInfo_Name, info, sizeof(info));
		LogToFile(LOG_PATH, "[ERROR] Failed to unload module %s", info);
		return 0;
	}
}

public int Cmd_ShowMainMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!CheckClient(client))
	{
		LogToFile(LOG_PATH, "[ERROR] Client index %d is not in game or a bot or doesn't exist on server", client);
		return;
	}
	else if (!IsWarden(client)) return;
	else
		Cmd_ShowMenu(client, g_iLastMenuItemPos);
}

void Cmd_ShowMenu(int client, int pos = 0)
{
	if (g_mMainMenu == null)
		MenuItemInitialization(client);
	else if (IsWarden(client))
		g_mMainMenu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

void MenuItemInitialization(int client) // Run at first time as client become warden
{
	char id[16], display[64];
	g_mMainMenu = new Menu(Cmd_ShowMenu_Handler);
	FormatEx(display, sizeof(display), "%T", "warden_menu_title", LANG_SERVER);
	g_mMainMenu.SetTitle(display);
	g_mMainMenu.ExitButton = true;
	int size = g_aSortedMenu.Length;
	
	if (!size)
	{
		FormatEx(display, sizeof(display), "%T", "warden_menu_empty", LANG_SERVER);
		g_mMainMenu.AddItem("", display, ITEMDRAW_DISABLED);
	}
	else
	{
		DataPack dp;
		int bitflag, menu_style;
		char error[48];
		Handle plugin;
		display[0] = '\0';
		// LogToFile(LOG_PATH, "Core loaded, waiting for modules response and add them to menu");
		for (int i = 0; i < size; i++)
		{
			g_aSortedMenu.GetString(i, id, sizeof(id));
			bitflag = g_aFlags.Get(i);
			
			
			/*----------------------*/
			if (!strcmp("resign", id, true))
			{
					SetGlobalTransTarget(client);
					Format(display, sizeof(display), "%T", "warden_menu_resign", LANG_SERVER);
					g_mMainMenu.AddItem(id, display);
			}
			if (g_ClientAPIInfo[client][grant] || g_ClientAPIInfo[client][is_dev] || JWPM_HasFlag(client, bitflag))
			{
				if (!strcmp("zam", id, true))
				{
					FormatEx(display, sizeof(display), "%T", "warden_menu_zam", LANG_SERVER);
					g_mMainMenu.AddItem(id, display);
				}
				else if (g_sMainMenuMap.GetValue(id, dp))
				{
					if (dp != null)
					{
						dp.Reset();
						plugin = dp.ReadCell();
						if (GetPluginStatus(plugin) == Plugin_Running)
						{
							bool result = true;
							Call_StartFunction(plugin, dp.ReadFunction());
							Call_PushCell(client);
							Call_PushStringEx(display, sizeof(display), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
							Call_PushCell(sizeof(display));
							Call_PushCell(menu_style);
							Call_Finish(result);
							
							if (!display[0] || !result) continue;
							
							if (menu_style != ITEMDRAW_DEFAULT && menu_style != ITEMDRAW_DISABLED) menu_style = ITEMDRAW_DEFAULT;
							g_mMainMenu.AddItem(id, display, menu_style);
						}
						else
						{
							GetPluginFilename(plugin, error, sizeof(error));
							LogToFile(LOG_PATH, "[WARNING] Module plugin '%s' has errors. Module not loaded.");
						}
					}
					else
						LogToFile(LOG_PATH, "[ERROR] Error in datapack. Failed to load item '%s'", id);
				}
			}
			
			// LogToFile(LOG_PATH, "[DEBUG] Module code '%s' - display name '%s' - menu style = %d", id, display, menu_style);
		}
	}
}

public int Cmd_ShowMenu_Handler(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsWarden(client)) return; // Block if not a warden
			char info[16], cName[MAX_NAME_LENGTH];
			menu.GetItem(slot, info, sizeof(info));
			// Get and save last position of element
			g_iLastMenuItemPos = menu.Selection;
			
			if (!g_CvarDisableAntiFlood.BoolValue && Flood(client, 1)) return;		
			else if (!strcmp("resign", info, true)) Resign_Confirm(client);
			else if (!strcmp("zam", info, true))
			{
				if (!g_iZamWarden)
				{
					Menu PList = new Menu(PList_Handler);
					FormatEx(cName, sizeof(cName), "%T", "warden_zam_choose", LANG_SERVER);
					PList.SetTitle(cName);
					for (int i = 1; i <= MaxClients; ++i)
					{
						if (CheckClient(i) && i != g_iWarden && !g_ClientAPIInfo[i][is_banned] && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i))
						{
							FormatEx(cName, sizeof(cName), "%N", i);
							IntToString(i, info, sizeof(info));
							PList.AddItem(info, cName);
						}
					}
					if (!PList.ItemCount)
					{
						FormatEx(cName, sizeof(cName), "%T", "no_available_ct", LANG_SERVER);
						PList.AddItem("", cName, ITEMDRAW_DISABLED);
					}
					PList.ExitButton = true;
					PList.Display(client, MENU_TIME_FOREVER);
				}
				else
				{
					if (g_bIsCSGO)
						CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "zam_chosen", LANG_SERVER, g_iZamWarden);
					else
						CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "zam_chosen", LANG_SERVER, g_iZamWarden);
					if (IsWarden(client)) Cmd_ShowMenu(client);
				}
			}
			else
			{
				DataPack dp;
				Handle plugin;
				bool result = false;
				
				if (g_sMainMenuMap.GetValue(info, dp))
				{
					if (dp != null)
					{
						dp.Reset();
						plugin = dp.ReadCell();
						if (GetPluginStatus(plugin) == Plugin_Running)
						{
							dp.ReadFunction();
							Call_StartFunction(plugin, dp.ReadFunction());
							Call_PushCell(client);
							Call_Finish(result);
						}
						else
						{
							char error[48];
							GetPluginFilename(plugin, error, sizeof(error));
							LogToFile(LOG_PATH, "[WARNING] Module plugin '%s' has errors. Module not loaded.", info);
						}
					}
					else
						LogToFile(LOG_PATH, "[ERROR] Failed to load select callback for module '%s'", info);
				}
				
				if (!result) Cmd_ShowMenu(client, menu.Selection);
				
				return;
			}
		}
	}
}

public int PList_Handler(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (IsWarden(client)) Cmd_ShowMenu(client);
		}
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(slot, info, sizeof(info));
			int target = StringToInt(info);
			if (!g_iZamWarden)
			{
				SetZam(target);
				if (g_bIsCSGO)
					CGOPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "zam_notify", LANG_SERVER, client, target);
				else
					CPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "zam_notify", LANG_SERVER, client, target);
			}
			if (IsWarden(client)) Cmd_ShowMenu(client);
		}
	}
}

void Resign_Confirm(int client)
{
	if (CheckClient(client) && IsWarden(client))
	{
		char buffer[100];
		Menu ConfirmMenu = new Menu(ConfirmMenu_Callback);
		Format(buffer, sizeof(buffer), "%T", "warden_resign_confirm", LANG_SERVER);
		ConfirmMenu.SetTitle(buffer);
		ConfirmMenu.ExitButton = false;
		ConfirmMenu.ExitBackButton = false;
		
		Format(buffer, sizeof(buffer), "%T", "Yes", LANG_SERVER);
		ConfirmMenu.AddItem("y", buffer);
		Format(buffer, sizeof(buffer), "%T", "No", LANG_SERVER);
		ConfirmMenu.AddItem("n", buffer);
		ConfirmMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int ConfirmMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Select:
		{
			if (IsWarden(client))
			{
				if (!slot)
				{
					if (Forward_OnWardenResign(client))
						RemoveCmd(true);
					else return;
				}
				else Cmd_ShowMenu(client);
			}
		}
	}
}

void EmptyPanel()
{
	if (g_mMainMenu != null)
		g_mMainMenu.Cancel();
}

void RehashMenu()
{
	g_aSortedMenu.Clear();
	g_aFlags.Clear();
	Load_SortingWardenMenu();
	if (g_iWarden != 0)
	{
		if (g_mMainMenu != null)
			delete g_mMainMenu;
		MenuItemInitialization(g_iWarden);
	}
}

bool JWPM_HasFlag(int client, int bitflag)
{
	if (!bitflag) return true;
	else if (bitflag != 0 && ((GetUserFlagBits(client) & bitflag) || (GetUserFlagBits(client) & ADMFLAG_ROOT)) && GetUserAdmin(client) != INVALID_ADMIN_ID)
		return true;
	return false;
}

//ANTI-FLOOD
bool Flood(int client, int delay)
{
	static int last_time[MAXPLAYERS+1]; static int curr_time; static int time;
	curr_time = GetTime();
	time = curr_time - last_time[client];
	if (time < delay)
	{
		if (g_bIsCSGO)
			ReplyToCommand(client, "%T", "anti_flood", LANG_SERVER, delay - time);
		else
			CReplyToCommand(client, "%T %T", "Core_Prefix", LANG_SERVER, "anti_flood", LANG_SERVER, delay - time);
		return true;
	}
	last_time[client] = curr_time;
	return false;
}

bool RefreshMenuItem(char[] item, char[] newdisp = "", int style = ITEMDRAW_DEFAULT)
{
	if (g_mMainMenu != null)
	{
		int oldstyle;
		char id[16], display[64];
		for (int i = 0; i < g_aSortedMenu.Length; i++)
		{
			g_mMainMenu.GetItem(i, id, sizeof(id), oldstyle, display, sizeof(display));
			if (!strcmp(item, id, true))
			{
				if (newdisp[0] != '\0')
					strcopy(display, sizeof(display), newdisp);
				if (style != oldstyle)
					oldstyle = style;
				if (g_mMainMenu.RemoveItem(i))
				{
					if (!g_mMainMenu.InsertItem(i, id, display, oldstyle))
						g_mMainMenu.AddItem(id, display, oldstyle);
					return true;
				}
			}
		}
	}
	return false;
}