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
		FormatEx(buffer, maxlength, "Остановить LR");
	else
		FormatEx(buffer, maxlength, "Остановить LR (ост: %d)", g_CvarMaxStops.IntValue - g_iStops);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (g_CvarMaxStops.IntValue && g_iStops < g_CvarMaxStops.IntValue)
	{
		JWP_ActionMsgAll("%N остановил \x02LR\x01.", client);
		ServerCommand("sm_stoplr"); // Останавливает лр от имени сервера.
		g_iStops++;
		int result = g_CvarMaxStops.IntValue - g_iStops;
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "Остановить LR (ост: %d)", result);
		JWP_RefreshMenuItem(ITEM, buffer, (!result) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		// JWP_RehashMenu();
	}
	else
		JWP_ActionMsg(client, "Вы использовали максимальное количество отмен LR.");
	
	JWP_ShowMainMenu(client);
		
	return true;
}