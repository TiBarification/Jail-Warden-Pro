// Menu g_mMainMenu;

#define CMD_RESIGN 0

#define CMDMENU_PLUGIN 0
#define CMDMENU_DISPLAY 1
#define CMDMENU_SELECT 2

// ArrayList g_hMainMenuArray;
StringMap g_sMainMenuMap;

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
	Cmd_ShowMenu(client);
}

void Cmd_ShowMenu(int client, int pos = 0)
{
	Menu menu = new Menu(Cmd_ShowMenu_Handler);
	menu.SetTitle("Меню командования:");
	menu.ExitButton = true;
	int size = g_aSortedMenu.Length;
	
	if (size)
	{
		
		any tmp[3]; char id[16], display[64];
		display[0] = '\0';
		for (int i = 0; i < size; i++)
		{
			g_aSortedMenu.GetString(i, id, sizeof(id));
			if (strcmp("resign", id, true) == 0)
				menu.AddItem(id, "Покинуть пост");
			else if (strcmp("zam", id, true) == 0)
				menu.AddItem(id, "Выбрать ЗАМа");
			else if (g_sMainMenuMap.GetArray(id, tmp, sizeof(tmp)))
			{
				bool result = true;
				
				Call_StartFunction(tmp[CMDMENU_PLUGIN], tmp[CMDMENU_DISPLAY]);
				Call_PushCell(client);
				Call_PushStringEx(display, sizeof(display), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCell(sizeof(display))
				Call_Finish(result);
				
				if (!display[0] || !result) continue;
				menu.AddItem(id, display);
			}
		}
	}
	
	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

public int Cmd_ShowMenu_Handler(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[16], cName[MAX_NAME_LENGTH];
			menu.GetItem(slot, info, sizeof(info));
			
			if (Flood(client, 1)) return;
			else if (strcmp("resign", info, true) == 0) RemoveCmd();
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
						PList.AddItem("", "Нет доступных КТ для ЗАМа", ITEMDRAW_DISABLED);
					PList.ExitButton = true;
					PList.Display(client, MENU_TIME_FOREVER);
				}
				else
					PrintToChat(client, "%s Замом был назначен %N", PREFIX, g_iZamWarden);
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
		case MenuAction_End: menu.Close();
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
				PrintToChatAll("%s %N назначил ЗАМа %N", PREFIX, client, target);
			}
			Cmd_ShowMenu(client);
		}
	}
}


//ANTI-FLOOD
bool Flood(int client, int delay)
{
	static int last_time[MAXPLAYERS+1]; static int curr_time; static int time;
	curr_time = GetTime();
	time = curr_time - last_time[client];
	if (time < delay)
	{
		ReplyToCommand(client, "%s Не флуди командой, подожди %d с.", PREFIX, delay - time);
		return true;
	}
	last_time[client] = curr_time;
	return false;
}