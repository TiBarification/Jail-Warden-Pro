#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.2"
#define ITEM "guns"

char cPath[18] = "cfg/jwp/guns.txt";

Menu g_WeaponMenu;
StringMap g_Slot;

public Plugin myinfo = 
{
	name = "[JWP] Guns",
	description = "Warden can use guns from menu",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_Slot = new StringMap();
	LoadTranslations("jwp_modules.phrases");
	if (JWP_IsStarted()) JWP_Started();
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
	LoadGunsFile();
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Guns_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	g_WeaponMenu.Display(client, MENU_TIME_FOREVER);
	return true;
}

void LoadGunsFile()
{
	KeyValues kv = new KeyValues("guns", "", "");
	if (!kv.ImportFromFile(cPath))
	{
		LogError("Failed to open %s", cPath);
		return;
	}
	if (!kv.GotoFirstSubKey(true)) return;
	
	char buffer[32], text[48];
	int options[2];
	g_WeaponMenu = new Menu(g_WeaponMenu_Callback);
	
	Format(text, sizeof(text), "%T:", "Guns_Menu", LANG_SERVER);
	
	g_WeaponMenu.SetTitle(text);
	do
	{
		if (kv.GetSectionName(buffer, sizeof(buffer)))
		{
			kv.GetString("text", text, sizeof(text), buffer);
			Format(buffer, sizeof(buffer), "weapon_%s", buffer);
			g_WeaponMenu.AddItem(buffer, text);
			
			// Get slot for item
			options[0] = kv.GetNum("slot", 0);
			options[1] = kv.GetNum("drop", 0);
			g_Slot.SetArray(buffer, options, sizeof(options), false);
		}
	} while (kv.GotoNextKey(true));
	g_WeaponMenu.ExitBackButton = true;
	
	delete kv;
}

public int g_WeaponMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			int options[2]; char info[32];
			menu.GetItem(slot, info, sizeof(info));
			g_Slot.GetArray(info, options, sizeof(options));
			
			if (!options[1])
			{
				if (JWP_IsFlood(client, 2)) return;
				int weapon = GetPlayerWeaponSlot(client, options[0]);
				if (IsValidEdict(weapon))
					AcceptEntityInput(weapon, "Kill");
			}
			
			GivePlayerItem(client, info);
			
			g_WeaponMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
}