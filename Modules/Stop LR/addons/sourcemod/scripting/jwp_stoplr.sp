#include <sourcemod>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "stoplr"

ConVar g_CvarMaxStops;
int g_iStops;

public Plugin myinfo = 
{
	name = "[JWP] Stop LR",
	description = "Warden has access to stop lr",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarMaxStops = CreateConVar("jwp_stoplr_max", "2", "Сколько раз командир может останавливать lr за раунд");
	g_CvarMaxStops.AddChangeHook(OnCvarChange);
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	if (JWP_IsStarted()) JWC_Started();
	AutoExecConfig(true, "stoplr", "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarMaxStops) g_CvarMaxStops.SetInt(StringToInt(newValue));
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iStops = 0;
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
	if (!g_CvarMaxStops.IntValue)
		FormatEx(buffer, maxlength, "%T", "StopLR_Menu", LANG_SERVER);
	else
		FormatEx(buffer, maxlength, "%T %T", "StopLR_Menu", LANG_SERVER, "StopLR_StopLeft", LANG_SERVER, g_CvarMaxStops.IntValue - g_iStops);
	return true;
}

public bool OnFuncSelect(int client)
{
	char langbuffer[48];
	if (!g_CvarMaxStops.IntValue)
	{
		JWP_ActionMsgAll("%T", "StopLR_ActionMessage_Stopped", LANG_SERVER, client);
		ServerCommand("sm_stoplr"); // Останавливает лр от имени сервера.
	}
	else if (g_CvarMaxStops.IntValue && g_iStops < g_CvarMaxStops.IntValue)
	{
		JWP_ActionMsgAll("%T", "StopLR_ActionMessage_Stopped", LANG_SERVER, client);
		ServerCommand("sm_stoplr"); // Останавливает лр от имени сервера.
		g_iStops++;
		int result = g_CvarMaxStops.IntValue - g_iStops;
		FormatEx(langbuffer, sizeof(langbuffer), "%T %T", "StopLR_Menu", LANG_SERVER, "StopLR_StopLeft", LANG_SERVER, result);
		JWP_RefreshMenuItem(ITEM, langbuffer, (!result) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	else
		JWP_ActionMsg(client, "%T", "StopLR_ActionMessage_ReachedMaximum", LANG_SERVER);
	
	JWP_ShowMainMenu(client);
		
	return true;
}