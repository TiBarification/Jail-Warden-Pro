#include <sourcemod>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "otkaz"

public Plugin myinfo =
{
	name = "[JWP] Otkaz Module",
	description = "JWP otkaz module for using from warden menu",
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
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "Рассмотреть отказы");
	return true;
}

public bool OnFuncSelect(int client)
{
	FakeClientCommandEx(client, "sm_wotkaz");
	return true;
}
