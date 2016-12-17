#include <sourcemod>
#include <sdktools>
#include <jwp>
#include <emitsoundany>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.1"
#define ITEM "wtimer"

ConVar g_CvarMinTime, g_CvarMaxTime;

int g_iSec;
bool g_bChat;

Handle g_hTimer;
char g_cSound[] = "ui/beep22.wav";

public Plugin myinfo =
{
	name = "[JWP] Warden Timer",
	description = "Warden can start timer for some action",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru https://tibari.ru"
};

public void OnPluginStart()
{
	g_CvarMinTime = CreateConVar("jwp_wtimer_min", "5", "Minimum allowed time for timer", _, true, 5.0, true, 10.0);
	g_CvarMaxTime = CreateConVar("jwp_wtimer_max", "600", "Maximum allowed time for timer", _, true, 10.0, true, 600.0);
	
	if (JWP_IsStarted()) JWP_Started();
	AutoExecConfig(true, "wtimer", "jwp");
	LoadTranslations("jwp_modules.phrases");
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	FormatEx(buffer, sizeof(buffer), "sound/%s", g_cSound);
	AddFileToDownloadsTable(buffer);
	
	PrecacheSoundAny(g_cSound);
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	if (g_hTimer != null)
	{
		KillTimer(g_hTimer);
		g_hTimer = null;
		
		JWP_ActionMsgAll("%T", "WTimer_TimerStopped", LANG_SERVER);
	}
	
	g_bChat = false;
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnItemDisplay, OnItemSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && !IsFakeClient(client) && IsClientInGame(client) && JWP_IsWarden(client) && g_bChat)
	{
		g_bChat = false;
		
		if (sArgs[0] == '\0')
		{
			JWP_ActionMsg(client, "x03%T", "WTimer_InputCancelled", LANG_SERVER);
			JWP_RefreshMenuItem(ITEM, _, ITEMDRAW_DEFAULT);
		}
		else
		{
			g_iSec = StringToInt(sArgs);
			if (g_iSec <= 0) g_iSec = g_CvarMinTime.IntValue;
			else if (g_iSec > g_CvarMaxTime.IntValue) g_iSec = g_CvarMaxTime.IntValue;
			
			char lang[48];
			FormatEx(lang, sizeof(lang), "%T", "WTimer_TimerStop", LANG_SERVER);
			g_hTimer = CreateTimer(1.0, WTimer_Callback, client, TIMER_REPEAT);
			JWP_RefreshMenuItem(ITEM, lang, ITEMDRAW_DEFAULT);
		}
		JWP_ShowMainMenu(client);
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public bool OnItemDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "WTimer_Menu", LANG_SERVER);
	return true;
}

public bool OnItemSelect(int client)
{
	if (!JWP_IsWarden(client)) return false;
	if (g_hTimer == null)
	{
		JWP_ActionMsg(client, "\x03%T", "WTimer_HelpMessage", LANG_SERVER);
		g_bChat = true;
		JWP_RefreshMenuItem(ITEM, _, ITEMDRAW_DISABLED);
	}
	else
	{
		KillTimer(g_hTimer);
		g_hTimer = null;
		PrintHintTextToAll("%T", "WTimer_WardenStoppedHint", LANG_SERVER);
		char lang[48];
		FormatEx(lang, sizeof(lang), "%T", "WTimer_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, lang);
	}
	
	JWP_ShowMainMenu(client);
	return true;
}

public Action WTimer_Callback(Handle timer, any client)
{
	if (g_iSec-- > 0)
	{
		PrintHintTextToAll("%T", "WTimer_TimerHint", LANG_SERVER, g_iSec);
		return Plugin_Continue;
	}
	
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	EmitAmbientSoundAny(g_cSound, pos);
	PrintHintTextToAll("%T", "WTimer_Finished", LANG_SERVER);
	char lang[48];
	FormatEx(lang, sizeof(lang), "%T", "WTimer_Menu", LANG_SERVER);
	JWP_RefreshMenuItem(ITEM, lang);
	if (JWP_IsWarden(client))
		JWP_ShowMainMenu(client);
	
	g_hTimer = null;
	return Plugin_Stop;
}