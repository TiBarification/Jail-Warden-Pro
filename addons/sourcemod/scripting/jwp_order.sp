#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>
#undef REQUIRE_PLUGIN
#tryinclude <csgo_colors>
#tryinclude <morecolors>

#pragma newdecls required

#define PLUGIN_VERSION "1.2"
#define ITEM "order"

ConVar	g_CvarOrderSound,
		g_CvarOrderAlways,
		g_CvarOrderMsg,
		g_CvarOrderPanel,
		g_CvarPanelTime;
char g_cOrderSound[PLATFORM_MAX_PATH], g_cOrderMsg[250];

bool g_bChatListen;

public Plugin myinfo = 
{
	name = "[JWP] Order",
	description = "Ability to order",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarOrderSound = CreateConVar("jwp_order_sound", "buttons/blip2.wav", "Звук, когда командир приказывает");
	g_CvarOrderAlways = CreateConVar("jwp_order_always", "1", "Если 1, то каждое сообщение командира в чате будет приказом", _, true, 0.0, true, 1.0);
	g_CvarOrderMsg = CreateConVar("jwp_order_msg", "{default}({green}{prefix}{default}) {red}{nick}{default}: {text}", "Цвет сообщений приказа.");
	g_CvarOrderPanel = CreateConVar("jwp_order_panel", "0", "Включить отображение приказа в панели", _, true, 0.0, true, 1.0);
	g_CvarPanelTime = CreateConVar("jwp_order_panel_time", "20", "Сколько секунд показывать меню приказа.", _, true, 1.0, true, 40.0);
	
	if (JWP_IsStarted()) JWP_Started();
	AutoExecConfig(true, ITEM, "jwp");
	
	LoadTranslations("jwp_modules.phrases");
	LoadTranslations("core.phrases");
}

public void OnConfigsExecuted()
{
	g_CvarOrderSound.GetString(g_cOrderSound, sizeof(g_cOrderSound));
	g_CvarOrderMsg.GetString(g_cOrderMsg, sizeof(g_cOrderMsg));
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Order_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	PreOrderPanel(client);
	return true;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && IsClientInGame(client) && JWP_IsWarden(client) && (g_CvarOrderAlways.BoolValue || g_bChatListen))
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
	Format(text, sizeof(text), "%T", "Order_Menu_Info", LANG_SERVER);
	ReplaceString(text, sizeof(text), "\\n", "\n");
	panel.DrawText(text);
	panel.CurrentKey = 8;
	Format(text, sizeof(text), "%T", "Back", LANG_SERVER);
	panel.DrawItem(text);
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
	char text[250], orderbuf[250], name[MAX_NAME_LENGTH], langbuffer[24];
	GetClientName(client, name, sizeof(name));
	strcopy(text, sizeof(text), order);
	if (text[0] != '+')
		ReplaceString(text, sizeof(text), "+", "\n", true);
	strcopy(orderbuf, sizeof(orderbuf), text);
	
	/* Работа с чатом */
	if (GetEngineVersion() == Engine_CSS)
		CReplaceColorCodes(g_cOrderMsg, client, false, sizeof(g_CvarOrderMsg));
	else
		CGOReplaceColorSay(g_cOrderMsg, sizeof(g_cOrderMsg));
	
	ReplaceString(g_cOrderMsg, sizeof(g_cOrderMsg), "{text}", "", true);
	
	Format(text, sizeof(text), "%s%s", g_cOrderMsg, text);
	ReplaceString(text, sizeof(text), "{nick}", name, true);
	Format(langbuffer, sizeof(langbuffer), "%T", "Order_Warden_Prefix", LANG_SERVER);
	ReplaceString(text, sizeof(text), "{prefix}", langbuffer, true);
	PrintToChatAll("\x01%s", text);
	
	/* Конец работы с чатом */
	
	// И покажем террористам приказ в меню если квар позволяет
	if (g_CvarOrderPanel.BoolValue)
	{
		Format(orderbuf, sizeof(orderbuf), "(%T) %s: %s\n \n", "Order_Warden_Prefix", LANG_SERVER, name, orderbuf);
		
		Panel p1 = new Panel();
		p1.DrawText(orderbuf);
		p1.CurrentKey = 1;
		Format(langbuffer, sizeof(langbuffer), "%T", "Exit", LANG_SERVER);
		p1.DrawItem(langbuffer);
		
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && !(GetUserFlagBits(i) & ADMFLAG_GENERIC || GetUserFlagBits(i) & ADMFLAG_ROOT))
				p1.Send(i, OrderMsg_Callback, g_CvarPanelTime.IntValue);
		}
	}
}

public int OrderMsg_Callback(Menu panel, MenuAction action, int client, int slot)
{
	panel.Close();
}