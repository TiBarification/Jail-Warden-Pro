#include <sourcemod>
#include <cstrike>

// Force new syntax
#pragma newdecls required

#define PLUGIN_VERSION "0.0.2-dev"
#define PREFIX "\x01[\x03КМД\x01]"

int g_iWarden, g_iZamWarden;

bool is_started;

bool g_bWasWarden[MAXPLAYERS+1];
ArrayList g_aSortedMenu;

#include "jwp/jwpm_menu.sp"
#include "jwp/forwards.sp"
#include "jwp/natives.sp"
#include "jwp/kv_reader.sp"

public Plugin myinfo = 
{
	name = "[JWP-DEV] Core",
	description = "Jail Warden Pro Core",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://tibari.ru http://hlmod.ru"
};

public void OnPluginStart()
{
	CreateConVar("jwp_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_com", Command_BecomeWarden, "Warden menu");
	RegConsoleCmd("sm_w", Command_BecomeWarden, "Warden menu");
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	g_aSortedMenu = new ArrayList(16);
	Load_SortingWardenMenu();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Forwards
	CreateNative("JWP_IsStarted", Native_IsStarted);
	Cmd_MenuCreateNatives();
	Forward_Initialization();
	Native_Initialization();
	
	RegPluginLibrary("jwp");
	
	return APLRes_Success;
}

public int Native_IsStarted(Handle plugin, int params)
{
	return IsStarted();
}

public void OnConfigsExecuted()
{
	OnReadyToStart();
}

public void OnClientDisconnect(int client)
{
	if (IsWarden(client)) g_iWarden = 0;
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		g_bWasWarden[i] = false;
	g_iWarden = 0;
	g_iZamWarden = 0;
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsWarden(client)) g_iWarden = 0;
	else if (IsZamWarden(client)) g_iZamWarden = 0;
}

public Action Command_BecomeWarden(int client, int args)
{
	if (CheckClient(client))
	{
		if (g_iWarden > 0)
		{
			if (IsWarden(client))
				Cmd_ShowMenu(client);
			else
				PrintToChat(client, "%s Командиром является %N.", PREFIX, g_iWarden);
		}
		else
		{
			if (GetClientTeam(client) == CS_TEAM_CT)
			{
				if (BecomeCmd(client)) Cmd_ShowMenu(client);
			}
			else PrintToChat(client, "%s Командиром может быть только КТ.", PREFIX);
		}
	}
	
	return Plugin_Handled;
}

void Forward_NotifyJWPLoaded()
{
	Handle plugin;
	
	Handle myhandle = GetMyHandle();
	Handle hIter = GetPluginIterator();
	
	while (MorePlugins(hIter))
	{
		plugin = ReadPlugin(hIter);
		
		if (plugin == myhandle || GetPluginStatus(plugin) != Plugin_Running)
			continue;
		
		Function func = GetFunctionByName(plugin, "JWC_Started");
		
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_Finish();
		}
	}
	
	hIter.Close();
}

void OnReadyToStart()
{
	if (!is_started)
	{
		is_started = true;
		
		Forward_NotifyJWPLoaded();
	}
}

bool CheckClient(int client)
{
	if (client && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client)) return true;
	return false;
}

bool BecomeCmd(int client)
{
	if (g_bWasWarden[client])
	{
		PrintToChat(client, "%s Вы уже были командиром.", PREFIX);
		return false;
	}
	else if (IsPlayerAlive(client))
	{
		g_iWarden = client;
		Forward_OnWardenChosen(client);
		g_bWasWarden[client] = true;
		return true;
	}
	else
		PrintToChat(client, "%s Вы должны быть живы.", PREFIX);
	return false;
}

void RemoveCmd(bool themself = true)
{
	Forward_OnWardenResigned(g_iWarden, themself);
	if (themself) PrintToChatAll("%s %N покинул пост.", PREFIX, g_iWarden);
	if (g_iWarden) g_iWarden = 0;
}

void RemoveZam()
{
	if (g_iZamWarden) g_iZamWarden = 0;
}

bool SetZam(int client)
{
	if (CheckClient(client) && IsPlayerAlive(client) && client != g_iWarden)
	{
		g_iZamWarden = client;
		// Give user ability to be warden if no warden
		if (g_bWasWarden[client]) g_bWasWarden[client] = false;
		return true;
	}
	return false;
}

bool IsWarden(int client)
{
	return (client == g_iWarden)
}

bool IsZamWarden(int client)
{
	return (client == g_iZamWarden)
}

bool IsStarted()
{
	return is_started;
}