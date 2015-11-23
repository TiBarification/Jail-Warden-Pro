#include <sourcemod>
#include <shop>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "msg"

public Plugin myinfo = 
{
	name = "[JWP] Test Module",
	description = "Print to chat",
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

public bool OnFuncDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "Сообщение в чат");
}

public bool OnFuncSelect(int client)
{
	PrintToChatAll("MESSAGE SUCCESFULL!");
	JWP_ShowMainMenu(client);
	return true;
}