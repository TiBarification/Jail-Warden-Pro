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
	
	LoadTranslations("jwp_modules.phrases");
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Cvar_FF.RestoreDefault(false, false);
	g_bTurnOn = Cvar_FF.BoolValue;
}

public int JWP_OnWardenResigned(int client, bool himself)
{
	Cvar_FF.RestoreDefault(false, false);
	g_bTurnOn = Cvar_FF.BoolValue;
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
	FormatEx(buffer, maxlength, "[%s]%T", (g_bTurnOn) ? '-' : '+', "FF_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	g_bTurnOn = !g_bTurnOn;
	Cvar_FF.SetBool(g_bTurnOn, false, false);
	JWP_ActionMsgAll("%T\x02%T", "FF_ActionMessage_FriendlyFire", LANG_SERVER, (g_bTurnOn) ? "FF_State_On":"FF_State_Off");
	char menuitem[48];
	if (g_bTurnOn)
	{
		FormatEx(menuitem, sizeof(menuitem), "[-]%T", "FF_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	else
	{
		FormatEx(menuitem, sizeof(menuitem), "[+]%T", "FF_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	JWP_ShowMainMenu(client);
	return true;
}