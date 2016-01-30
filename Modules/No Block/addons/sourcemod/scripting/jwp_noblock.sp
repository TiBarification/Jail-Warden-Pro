#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "noblock"

EngineVersion engine;
int g_CollisionGroupOffset;
ConVar Cvar_Noblock;
bool g_bNoblock, g_bOldValue;

public Plugin myinfo = 
{
	name = "[JWP] Noblock",
	description = "Warden can toggle noblock",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	engine = GetEngineVersion();
	
	if (engine == Engine_CSGO)
	{
		Cvar_Noblock = FindConVar("mp_solid_teammates");
		g_bOldValue = !Cvar_Noblock.BoolValue;
	}
	else
	{
		g_CollisionGroupOffset = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
		if (g_CollisionGroupOffset == -1)
			LogError("CBaseEntity::m_CollisionGroup offset not found");
		HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
		g_bOldValue = false;
	}
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	if (JWP_IsStarted()) JWC_Started();
	
	LoadTranslations("jwp_modules.phrases");
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (engine == Engine_CSGO)
	{
		Cvar_Noblock.SetBool(!g_bOldValue, false, false);
		g_bNoblock = g_bOldValue;
	}
	else
	{
		for (int i = 1; i <= MaxClients; ++i)
			NoblockEntity(i, false);
		g_bNoblock = g_bOldValue;
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (engine == Engine_CSS)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		NoblockEntity(client, g_bNoblock);
	}
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
	FormatEx(buffer, maxlength, "[%s]%T", (g_bNoblock) ? '-' : '+', "Noblock_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	char menuitem[48];
	g_bNoblock = !g_bNoblock;
	if (engine == Engine_CSGO)
		Cvar_Noblock.SetBool(!g_bNoblock, false, false);
	else
	{
		for (int i = 1; i <= MaxClients; ++i)
			NoblockEntity(i, g_bNoblock);
	}
	if (g_bNoblock)
	{
		FormatEx(menuitem, sizeof(menuitem), "[-]%T", "Noblock_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	else
	{
		FormatEx(menuitem, sizeof(menuitem), "[+]%T", "Noblock_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	JWP_ActionMsgAll("%T \x02%T", "Noblock_ActionMessage_Title", LANG_SERVER, (g_bNoblock) ? "Noblock_ActionMessage_On":"Noblock_ActionMessage_Off", LANG_SERVER);
	JWP_ShowMainMenu(client);
	return true;
}

void NoblockEntity(int client, bool state = true)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
		SetEntData(client, g_CollisionGroupOffset, (state) ? 2 : 5, 4, true);
}