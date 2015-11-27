#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "guns"

char cPath[18] = "cfg/jwp/guns.txt";

Menu g_WeaponMenu;

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
			if (JWP_IsFlood(client, 3)) return;
			char info[32];
			menu.GetItem(slot, info, sizeof(info));
			
			int weapon = GetPlayerWeaponSlot(client, 0);
			if (IsValidEdict(weapon))
				AcceptEntityInput(weapon, "Kill");
			GivePlayerItem(client, info);
			
			g_WeaponMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
}