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
bool g_bNoblock;

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
		Cvar_Noblock = FindConVar("mp_solid_teammates");
	else
	{
		g_CollisionGroupOffset = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
		if (g_CollisionGroupOffset == -1)
			LogError("CBaseEntity::m_CollisionGroup offset not found");
		HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	}
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	if (JWP_IsStarted()) JWC_Started();
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (engine == Engine_CSGO)
		Cvar_Noblock.RestoreDefault(false, false);
	g_bNoblock = false;
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (engine == Engine_CSS)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		NoblockEntity(client);
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

public bool OnFuncDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "[%s]ÕÓ·ÎÓÍ", (g_bNoblock) ? "-" : "+");
	return true;
}

public bool OnFuncSelect(int client)
{
	g_bNoblock = !g_bNoblock;
	if (engine == Engine_CSGO)
		Cvar_Noblock.SetBool(g_bNoblock, false, false);
	else
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
				NoblockEntity(i, g_bNoblock);
		}
	}
	JWP_ActionMsgAll("ÕŒ¡ÀŒ : \x02%s", (g_bNoblock) ? "¬ Àﬁ◊≈Õ":"¬€ Àﬁ◊≈Õ");
	JWP_ShowMainMenu(client);
	return true;
}

void NoblockEntity(int client, bool state = true)
{
	SetEntData(client, g_CollisionGroupOffset, (state) ? 2 : 5, 4, true);
}