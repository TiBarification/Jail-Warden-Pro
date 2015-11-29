#include <sourcemod>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "ff"

bool g_bTurnOn = false;
ConVar Cvar_FF;

public Plugin myinfo = 
{
	name = "[JWP] Friendly Fire",
	description = "Turn on/off friendly fire",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	Cvar_FF = FindConVar("mp_friendlyfire");
	g_bTurnOn = Cvar_FF.BoolValue;
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	if (JWP_IsStarted()) JWC_Started();
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Cvar_FF.RestoreDefault(false, false);
	g_bTurnOn = false;
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
	FormatEx(buffer, maxlength, "+/- Огонь по своим");
	return true;
}

public bool OnFuncSelect(int client)
{
	g_bTurnOn = !g_bTurnOn;
	Cvar_FF.SetBool(g_bTurnOn, false, false);
	JWP_ActionMsgAll("Дружественный огонь: \x02%s", (g_bTurnOn) ? "ВКЛЮЧЕН":"ВЫКЛЮЧЕН");
	JWP_RehashMenu();
	JWP_ShowMainMenu(client);
	return true;
}