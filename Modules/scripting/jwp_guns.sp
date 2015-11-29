#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "guns"

char cPath[18] = "cfg/jwp/guns.txt";

Menu g_WeaponMenu;
StringMap g_Slot;

public Plugin myinfo = 
{
	name = "[JWP] Guns",
	description = "Warden can use guns from menu",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_Slot = new StringMap();
	if (JWP_IsStarted()) JWC_Started();
}

public int JWC_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
	LoadGunsFile();
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "Оружие");
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
		LogError("Не удалось открыть %s", cPath);
		return;
	}
	if (!kv.GotoFirstSubKey(true)) return;
	
	char buffer[32], text[48];
	g_WeaponMenu = new Menu(g_WeaponMenu_Callback);
	g_WeaponMenu.SetTitle("Оружие:");
	do
	{
		if (kv.GetSectionName(buffer, sizeof(buffer)))
		{
			kv.GetString("text", text, sizeof(text), buffer);
			Format(buffer, sizeof(buffer), "weapon_%s", buffer);
			g_WeaponMenu.AddItem(buffer, text);
			
			// Get slot for item
			int slot = kv.GetNum("slot", 0);
			g_Slot.SetValue(buffer, slot);
		}
	} while (kv.GotoNextKey(true));
	
	delete kv;
}

public int g_WeaponMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Cancel: JWP_ShowMainMenu(client);
		case MenuAction_Select:
		{
			if (JWP_IsFlood(client, 2)) return;
			int islot; char info[32];
			menu.GetItem(slot, info, sizeof(info));
			g_Slot.GetValue(info, islot);
			
			int weapon = GetPlayerWeaponSlot(client, islot);
			if (IsValidEdict(weapon))
				AcceptEntityInput(weapon, "Kill");
			
			GivePlayerItem(client, info);
			
			g_WeaponMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
}