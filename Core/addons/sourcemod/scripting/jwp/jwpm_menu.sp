#define CMD_RESIGN 0

#define CMDMENU_PLUGIN 0
#define CMDMENU_DISPLAY 1
#define CMDMENU_SELECT 2

// ArrayList g_hMainMenuArray;
StringMap g_sMainMenuMap;
int g_iLastMenuItemPos;
Menu g_mMainMenu;

void Cmd_MenuCreateNatives()
{
	// g_hMainMenuArray = new ArrayList(3);
	g_sMainMenuMap = new StringMap();
	
	CreateNative("JWP_AddToMainMenu", Cmd_AddToMainMenu);
	CreateNative("JWP_RemoveFromMainMenu", Cmd_RemoveFromMainMenu);
	CreateNative("JWP_ShowMainMenu", Cmd_ShowMainMenu);
}

public int Cmd_AddToMainMenu(Handle plugin, int numParams)
{
	any tmp[3]; char key[16];
	// Unique name of item
	GetNativeString(1, key, sizeof(key));
	tmp[CMDMENU_PLUGIN] = plugin;
	tmp[CMDMENU_DISPLAY] = GetNativeCell(2);
	tmp[CMDMENU_SELECT] = GetNativeCell(3);
	
	g_sMainMenuMap.SetArray(key, tmp, sizeof(tmp));
}

public int Cmd_RemoveFromMainMenu(Handle plugin, int numParams)
{
	any tmp[3]; char key[16];
	GetNativeString(1, key, sizeof(key));
	if (g_sMainMenuMap.GetArray(key, tmp, sizeof(tmp)))
	{
		if (tmp[CMDMENU_DISPLAY] == GetNativeCell(2) && tmp[CMDMENU_SELECT] == GetNativeCell(3))
		{
			g_sMainMenuMap.Remove(key);
			return 1;
		}
	}
	
	return 0;
}

public int Cmd_ShowMainMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	char error[64];
	if (!CheckClient(client))
		ThrowNativeError(SP_ERROR_NATIVE, error);
	else if (!IsWarden(client)) return;
	Cmd_ShowMenu(client, g_iLastMenuItemPos);
}

void Cmd_ShowMenu(int client, int pos = 0)
{
	if (g_mMainMenu == null)
		MenuItemInitialization(client);
	g_mMainMenu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

void MenuItemInitialization(int client) // Run at first time as client become warden
{
	char buffer[48];
	g_mMainMenu = new Menu(Cmd_ShowMenu_Handler);
	FormatEx(buffer, sizeof(buffer), "%t", "warden_menu_title");
	g_mMainMenu.SetTitle(buffer);
	g_mMainMenu.ExitButton = true;
	int size = g_aSortedMenu.Length;
	
	if (!size)
	{
		FormatEx(buffer, sizeof(buffer), "%t", "warden_menu_empty");
		g_mMainMenu.AddItem("", buffer, ITEMDRAW_DISABLED);
	}
	else
	{
		any tmp[3]; char id[16], display[64];
		int bitflag;
		display[0] = '\0';
		for (int i = 0; i < size; i++)
		{
			g_aSortedMenu.GetString(i, id, sizeof(id));
			bitflag = g_aFlags.Get(i);
			
			
			/*----------------------*/
			if (strcmp("resign", id, true) == 0)
			{
					FormatEx(buffer, sizeof(buffer), "%t", "warden_menu_resign");
					g_mMainMenu.AddItem(id, buffer);
			}
			if (JWPM_HasFlag(client, bitflag))
			{
				if (strcmp("zam", id, true) == 0)
				{
					FormatEx(buffer, sizeof(buffer), "%t", "warden_menu_zam");
					g_mMainMenu.AddItem(id, buffer);
				}
				else if (g_sMainMenuMap.GetArray(id, tmp, sizeof(tmp)))
				{
					bool result = true;
					
					Call_StartFunction(tmp[CMDMENU_PLUGIN], tmp[CMDMENU_DISPLAY]);
					Call_PushCell(client);
					Call_PushStringEx(display, sizeof(display), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
					Call_PushCell(sizeof(display))
					Call_Finish(result);
					
					if (!display[0] || !result) continue;
					g_mMainMenu.AddItem(id, display);
				}
			}
		}
	}
}

public int Cmd_ShowMenu_Handler(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[16], cName[MAX_NAME_LENGTH];
			menu.GetItem(slot, info, sizeof(info));
			// Get and save last position of element
			g_iLastMenuItemPos = menu.Selection;
			
			if (!g_CvarDisableAntiFlood.BoolValue && Flood(client, 1)) return;		
			else if (strcmp("resign", info, true) == 0) Resign_Confirm(client);
			else if (strcmp("zam", info, true) == 0)
			{
				if (!g_iZamWarden)
				{
					Menu PList = new Menu(PList_Handler);
					PList.SetTitle("Выберите ЗАМа:\n");
					for (int i = 1; i <= MaxClients; ++i)
					{
						if (CheckClient(i) && i != g_iWarden && GetClientTeam(i) == CS_TEAM_CT)
						{
							FormatEx(cName, sizeof(cName), "%N", i);
							IntToString(i, info, sizeof(info));
							PList.AddItem(info, cName);
						}
					}
					if (!PList.ItemCount)
					{
						FormatEx(cName, sizeof(cName), "%t", "no_available_ct");
						PList.AddItem("", cName, ITEMDRAW_DISABLED);
					}
					PList.ExitButton = true;
					PList.Display(client, MENU_TIME_FOREVER);
				}
				else
				{
					if (g_bIsCSGO)
						CGOPrintToChat(client, "%t %t", "Core_Prefix", "zam_chosen", g_iZamWarden);
					else
						CPrintToChat(client, "%t %t", "Core_Prefix", "zam_chosen", g_iZamWarden);
				}
			}
			else
			{
				bool result = false;
				
				any tmp[3];
				if (g_sMainMenuMap.GetArray(info, tmp, sizeof(tmp)))
				{
					Call_StartFunction(tmp[CMDMENU_PLUGIN], tmp[CMDMENU_SELECT])
					Call_PushCell(client);
					Call_Finish(result);
				}
				
				if (!result) Cmd_ShowMenu(client, menu.Selection);
				
				return;
			}
		}
		// case MenuAction_End: menu.Close();
	}
}

public int PList_Handler(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel: Cmd_ShowMenu(client);
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(slot, info, sizeof(info));
			int target = StringToInt(info);
			if (!g_iZamWarden)
			{
				SetZam(target);
				if (g_bIsCSGO)
					CGOPrintToChatAll("%t %t", "Core_Prefix", "zam_notify", client, target);
				else
					CPrintToChatAll("%t %t", "Core_Prefix", "zam_notify", client, target);
			}
			Cmd_ShowMenu(client);
		}
	}
}

void Resign_Confirm(int client)
{
	if (CheckClient(client) && IsWarden(client))
	{
		Menu ConfirmMenu = new Menu(ConfirmMenu_Callback);
		ConfirmMenu.SetTitle("Вы действительно хотите покинуть пост командира?");
		ConfirmMenu.ExitButton = false;
		ConfirmMenu.ExitBackButton = false;
		ConfirmMenu.AddItem("y", "ДА");
		ConfirmMenu.AddItem("n", "НЕТ");
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
				if (!slot) RemoveCmd(true);
				else Cmd_ShowMenu(client);
			}
		}
	}
}

void EmptyPanel(int client)
{
	if (CheckClient(client))
	{
		/* close menu if exists with empty panel */
		Panel panel = new Panel();
		panel.SetTitle(" ");
		panel.Send(client, EmptyPanel_Callback, 2);
	}
}

public int EmptyPanel_Callback(Menu menu, MenuAction action, int client, int slot)
{
	if (action == MenuAction_End)
		menu.Close();
}

void RehashMenu()
{
	g_aSortedMenu.Clear();
	g_aFlags.Clear();
	Load_SortingWardenMenu();
	if (g_iWarden != 0)
	{
		delete g_mMainMenu;
		MenuItemInitialization(g_iWarden);
	}
}

bool JWPM_HasFlag(int client, int bitflag)
{
	if (!bitflag) return true;
	else if (bitflag != 0 && (GetUserFlagBits(client) & bitflag) && GetUserAdmin(client) != INVALID_ADMIN_ID) return true;
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
			ReplyToCommand(client, "%t", "anti_flood", delay - time);
		else
			CReplyToCommand(client, "%t %t", "Core_Prefix", "anti_flood", delay - time);
		return true;
	}
	last_time[client] = curr_time;
	return false;
}