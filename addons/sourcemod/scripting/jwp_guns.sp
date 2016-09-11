#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define ITEM "guns"
#define MAX_WEAPON_STRING 32

char cPath[18] = "cfg/jwp/guns.txt";

Menu g_WeaponMenu;
ArrayList g_aWeaponNames;
StringMap g_sOptions;
bool g_bIsCSGO;

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
	g_sOptions = new StringMap();
	g_aWeaponNames = new ArrayList(MAX_WEAPON_STRING);
	LoadTranslations("jwp_modules.phrases");
	if (JWP_IsStarted()) JWP_Started();
	g_bIsCSGO = (GetEngineVersion() == Engine_CSGO);
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
	int options[5], idx;
	g_WeaponMenu = new Menu(g_WeaponMenu_Callback);
	
	Format(text, sizeof(text), "%T:", "Guns_Menu", LANG_SERVER);
	
	g_WeaponMenu.SetTitle(text);
	do
	{
		if (kv.GetSectionName(buffer, sizeof(buffer)))
		{
			kv.GetString("text", text, sizeof(text), buffer);
			// Format(buffer, sizeof(buffer), "weapon_%s", buffer);
			g_WeaponMenu.AddItem(buffer, text);
			
			// Get slot for item
			kv.GetString("weapon", text, sizeof(text), "weapon_knife");
			idx = g_aWeaponNames.PushString(text);
			options[0] = kv.GetNum("slot", 0);
			options[1] = kv.GetNum("drop", 0);
			options[2] = kv.GetNum("clip", -1);
			options[3] = kv.GetNum("ammo", -1);
			options[4] = idx;
			g_sOptions.SetArray(buffer, options, sizeof(options), false);
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
			int options[5]; char info[32];
			menu.GetItem(slot, info, sizeof(info));
			g_sOptions.GetArray(info, options, sizeof(options));
			
			g_aWeaponNames.GetString(options[4], info, sizeof(info));
			
			if (!options[1])
			{
				if (JWP_IsFlood(client, 2)) return;
				int weapon = GetPlayerWeaponSlot(client, options[0]);
				if (IsValidEdict(weapon))
					AcceptEntityInput(weapon, "Kill");
			}
			
			int weapon = GivePlayerItem(client, info);
			if (options[2] != -1)
				SetEntProp(weapon, Prop_Data, "m_iClip1", options[2]);
			if (options[3] != -1)
			{
				if (g_bIsCSGO)
					SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", options[3]);
				else
					SetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoCount", options[3]);
			}
			
			g_WeaponMenu.Display(client, MENU_TIME_FOREVER);
		}
	}
}