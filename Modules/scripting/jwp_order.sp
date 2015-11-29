#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "order"

ConVar	g_CvarOrderSound,
		g_CvarOrderAlways;
char g_cOrderSound[PLATFORM_MAX_PATH];

// Panel g_pOrderPanel;

bool g_bChatListen;

public Plugin myinfo = 
{
	name = "[JWP] Order",
	description = "Ability to order",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarOrderSound = CreateConVar("jwp_order_sound", "buttons/blip2.wav", "Звук, когда командир приказывает", FCVAR_PLUGIN);
	g_CvarOrderAlways = CreateConVar("jwp_order_always", "1", "Если 1, то каждое сообщение командира в чате будет приказом", FCVAR_PLUGIN);
	
	g_CvarOrderSound.AddChangeHook(OnCvarChange);
	g_CvarOrderAlways.AddChangeHook(OnCvarChange);
	if (JWP_IsStarted()) JWC_Started();
	AutoExecConfig(true, ITEM, "jwp");
}

public int JWC_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarOrderSound)
	{
		g_CvarOrderSound.SetString(newValue);
		strcopy(g_cOrderSound, sizeof(g_cOrderSound), newValue);
	}
	if (cvar == g_CvarOrderAlways) g_CvarOrderAlways.SetInt(StringToInt(newValue));
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "Отдать приказ");
	return true;
}

public bool OnFuncSelect(int client)
{
	PreOrderPanel(client);
	return true;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (JWP_IsWarden(client) && (g_CvarOrderAlways.BoolValue || g_bChatListen))
	{
		if (sArgs[0] != '!' && sArgs[0] != '/' && sArgs[0] != '@')
		{
			g_bChatListen = false;
			CreateOrderMsg(client, sArgs);
			if (g_cOrderSound[0]) // Характерный звук что приказ отправлен
				EmitSoundToAll(g_cOrderSound);
			if (!g_CvarOrderAlways.BoolValue)
				JWP_ShowMainMenu(client);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void PreOrderPanel(int client)
{
	g_bChatListen = true;
	Panel panel = new Panel();
	char text[140];
	Format(text, sizeof(text), "Введите в чат ваш приказ.\nСимвол '+' это переход\nна новую строку.");
	panel.DrawText(text);
	panel.CurrentKey = 8;
	panel.DrawItem("Отмена");
	panel.Send(client, PreOrderPanel_Callback, MENU_TIME_FOREVER);
}

public int PreOrderPanel_Callback(Menu panel, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: panel.Close();
		case MenuAction_Select:
		{
			g_bChatListen = false;
			if (JWP_IsWarden(client)) JWP_ShowMainMenu(client);
		}
	}
}

void CreateOrderMsg(int client, const char[] order)
{
	char text[250]; /* tag[150], name[MAX_NAME_LENGTH]; */
	strcopy(text, sizeof(text), order);
	ReplaceString(text, sizeof(text), "+", "\n", true);
	PrintToChatAll("\x01(\x03КОМАНДИР\x01) \x03%N\x01: %s", client, text);
	
	// И покажем террористам приказ в меню
	Format(text, sizeof(text), "(КОМАНДИР) %N: %s\n \n", client, text);
	
	Panel p1 = new Panel();
	p1.DrawText(text);
	p1.CurrentKey = 10;
	p1.DrawItem("Выход");
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
			p1.Send(i, OrderMsg_Callback, 20); // 20 секунд на меню думаю достаточно
	}
}

public int OrderMsg_Callback(Menu panel, MenuAction action, int client, int slot)
{
	panel.Close();
}