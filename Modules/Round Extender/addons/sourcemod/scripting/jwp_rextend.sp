#include <sourcemod>
#include <sdktools>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.2"
#define ITEM "rextend"

ConVar g_CvarRE_Limit, g_CvarRE_Extend;

int g_iExtends;

public Plugin myinfo = 
{
	name = "[JWP] Round Extender",
	description = "Warden can extend round",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarRE_Limit = CreateConVar("jwp_re_limit", "1", "Сколько раз командир может продлить раунд", FCVAR_PLUGIN, true, 0.0);
	g_CvarRE_Extend = CreateConVar("jwp_re_extend", "5", "На сколько минут продлить раунд", FCVAR_PLUGIN, true, 1.0);
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	
	AutoExecConfig(true, "round_extender", "jwp");
	
	if (JWP_IsStarted()) JWP_Started();
	
	LoadTranslations("jwp_modules.phrases");
}


public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iExtends = 0;
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnRextendDisplay, OnRextendSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnRextendDisplay, OnRextendSelect);
}

public bool OnRextendDisplay(int client, char[] buffer, int maxlength, int style)
{
	if (g_CvarRE_Limit.IntValue)
	{
		FormatEx(buffer, maxlength, "%T (%d/%d)", "RE_Menu", LANG_SERVER, g_iExtends, g_CvarRE_Limit.IntValue);
		if (g_iExtends < g_CvarRE_Limit.IntValue) style = ITEMDRAW_DEFAULT;
		else style = ITEMDRAW_DISABLED;
	}
	else
		FormatEx(buffer, maxlength, "%T", "RE_Menu", LANG_SERVER);
	
	return true;
}

public bool OnRextendSelect(int client)
{
	if (!JWP_IsFlood(client))
	{
		int extend = g_CvarRE_Extend.IntValue;
		
		// Set new time (oldtime + extend) . This property don't saved on new round
		GameRules_SetProp("m_iRoundTime", GameRules_GetProp("m_iRoundTime", 4, 0)+extend*60, 4, 0, true);
		
		g_iExtends++;
		
		if (g_CvarRE_Limit.IntValue)
		{
			char buffer[48];
			FormatEx(buffer, sizeof(buffer), "%T (%d/%d)", "RE_Menu", LANG_SERVER, g_iExtends, g_CvarRE_Limit.IntValue);
			JWP_RefreshMenuItem(ITEM, buffer, (g_iExtends < g_CvarRE_Limit.IntValue) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		JWP_ActionMsgAll("%T", "RE_ActionMessage_Extend", LANG_SERVER, client, extend);
		JWP_ShowMainMenu(client);
	}
	return true;
}