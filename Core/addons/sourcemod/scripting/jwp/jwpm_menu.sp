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
			char info[16];
			menu.GetItem(slot, info, sizeof(info));
			
			if (Flood(client)) return;
			else if (strcmp("resign", info, true) == 0) RemoveCmd();
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

//ANTI-FLOOD
bool Flood(int client)
{
	static int last_time[MAXPLAYERS+1]; static int curr_time; static int time;
	curr_time = GetTime();
	time = curr_time - last_time[client];
	if (time < 1)
	{
		ReplyToCommand(client, "%s Не флуди командой, подожди %d с.", PREFIX, 1 - time);
		return true;
	}
	last_time[client] = curr_time;
	return false;
}