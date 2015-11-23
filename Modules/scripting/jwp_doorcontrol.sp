#include <sourcemod>
#include <sdktools>
#include <jwp>
#include <smartjaildoors>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "doorcontrol"

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
}

public int JWC_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "Открыть клетки джайлов");
	return true;
}

public bool OnFuncSelect(int client)
{
	SJD_ToggleDoors();
	JWP_ShowMainMenu(client);
	return true;
}