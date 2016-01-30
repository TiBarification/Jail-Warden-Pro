#include <sourcemod>
#include <sdktools>
#include <jwp>
#undef REQUIRE_PLUGIN
#tryinclude <smartjaildoors> // https://forums.alliedmods.net/showthread.php?p=2306018

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM_DOOR_OPEN "door_open"
#define ITEM_DOOR_CLOSE "door_close"

bool g_bSmartDoors;

ArrayList g_aDoors;

public Plugin myinfo = 
{
	name = "[JWP] Door Control",
	description = "Open doors if they closed",
	author = "White Wolf (HLModders LLC) & Kailo97 (dev of doors plugin)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWC_Started();
	LoadTranslations("jwp_modules.phrases");
}

public void OnMapStart()
{
	CreateDoorList();
}

public void OnAllPluginsLoaded()
{
	g_bSmartDoors = LibraryExists("smartjaildoors");
}

public void OnLibraryAdded(const char[] name)
{
	g_bSmartDoors = StrEqual(name, "smartjaildoors");
}

public void OnLibraryRemoved(const char[] name)
{
	g_bSmartDoors = !(StrEqual(name, "smartjaildoors"));
}

public int JWC_Started()
{
	JWP_AddToMainMenu(ITEM_DOOR_OPEN, OnFuncDoorOpen_Display, OnFuncDoorOpen_Select);
	JWP_AddToMainMenu(ITEM_DOOR_CLOSE, OnFuncDoorClose_Display, OnFuncDoorClose_Select);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM_DOOR_OPEN, OnFuncDoorOpen_Display, OnFuncDoorOpen_Select);
	JWP_RemoveFromMainMenu(ITEM_DOOR_CLOSE, OnFuncDoorClose_Display, OnFuncDoorClose_Select);
}

public bool OnFuncDoorOpen_Display(int client, char[] buffer, int maxlength, int style)
{
	Format(buffer, maxlength, "%T", "DoorControl_Menu_Open", LANG_SERVER);
	return true;
}

public bool OnFuncDoorOpen_Select(int client)
{
	if (JWP_IsFlood(client)) return false;
	JWP_ActionMsgAll("%T", "DoorControl_ActionMessage_Opened", LANG_SERVER, client);
	if (g_bSmartDoors)
		SJD_OpenDoors();
	else
		ClassicDoorsManip(client, true);
	JWP_ShowMainMenu(client);
	return true;
}

public bool OnFuncDoorClose_Display(int client, char[] buffer, int maxlength, int style)
{
	Format(buffer, maxlength, "%T", "DoorControl_Menu_Close", LANG_SERVER);
	return true;
}

public bool OnFuncDoorClose_Select(int client)
{
	if (JWP_IsFlood(client)) return false;
	JWP_ActionMsgAll("%T", "DoorControl_ActionMessage_Closed", LANG_SERVER, client);
	if (g_bSmartDoors)
		SJD_CloseDoors();
	else
		ClassicDoorsManip(client, false);
	JWP_ShowMainMenu(client);
	return true;
}

void CreateDoorList()
{
	if (g_aDoors == null)
		g_aDoors = new ArrayList(1);
	else
		g_aDoors.Clear();
	
	int ent = GetMaxEntities();
	char class[28];
	while (ent > MaxClients)
	{
		ent--;
		if (IsValidEntity(ent) && GetEntityClassname(ent, class, sizeof(class)) && TiB_IsDoor(class))
			g_aDoors.Push(ent);
	}
}

void ClassicDoorsManip(int client, bool open)
{
	if (!g_aDoors.Length)
	{
		PrintCenterText(client, "%T", "DoorControl_NoDoors", LANG_SERVER);
		JWP_ShowMainMenu(client);
	}
	
	int ent;
	char class[28];
	for (int i = 0; i < g_aDoors.Length; ++i)
	{
		ent = g_aDoors.Get(i);
		if (IsValidEntity(ent) && GetEntityClassname(ent, class, sizeof(class)) && TiB_IsDoor(class))
		{
			AcceptEntityInput(ent, "Unlock");
			if (open)
				AcceptEntityInput(ent, "Open");
			else
				AcceptEntityInput(ent, "Close");
		}
	}
}

bool TiB_IsDoor(const char[] classname)
{
	return (StrContains(classname, "movelinear", false) || StrContains(classname, "door", false));
}