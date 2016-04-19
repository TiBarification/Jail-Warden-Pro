#include <sourcemod>
#include <cstrike>
#undef REQUIRE_PLUGIN
#tryinclude <csgo_colors>
#tryinclude <morecolors>
#include <updater>

// Force new syntax
#pragma newdecls required

#define PLUGIN_VERSION "0.0.9"

#define UPDATE_URL "http://updater.tibari.ru/jwp/updatefile.txt"

int g_iWarden, g_iZamWarden;
bool g_bHasFreeday[MAXPLAYERS+1];
bool g_bIsolated[MAXPLAYERS+1];

bool is_started;
bool g_bRoundEnd;
bool g_bIsCSGO;

bool g_bWasWarden[MAXPLAYERS+1];
ArrayList g_aSortedMenu;
ArrayList g_aFlags;

ConVar	g_CvarChooseMode,
		g_CvarRandomWait,
		g_CvarVoteTime,
		g_CvarDisableAntiFlood,
		g_CvarAutoUpdate;

Handle g_hChooseTimer;

#include "jwp/kv_reader.sp"
#include "jwp/dev.sp"
#include "jwp/jwpm_menu.sp"
#include "jwp/forwards.sp"
#include "jwp/natives.sp"
#include "jwp/voting.sp"

public Plugin myinfo = 
{
	name = "[JWP] Core",
	description = "Jail Warden Pro Core",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://tibari.ru http://hlmod.ru"
};

public void OnPluginStart()
{
	CreateConVar("jwp_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarChooseMode = CreateConVar("jwp_choose_mode", "2", "How to choose warden 1:random 2:command 3:voting", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	g_CvarRandomWait = CreateConVar("jwp_random_wait", "5", "Time before warden randomly picked if choose mode = 1", FCVAR_PLUGIN, true, 1.0, true, 30.0);
	g_CvarVoteTime = CreateConVar("jwp_vote_time", "30", "Time for voting if choose mode = 3", FCVAR_PLUGIN, true, 10.0, true, 60.0);
	g_CvarDisableAntiFlood = CreateConVar("jwp_disable_antiflood", "1", "Protect menu from random selecting", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_CvarAutoUpdate = CreateConVar("jwp_autoupdate", "0", "Enable (1) or disable (0) auto update. Need Updater!", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_com", Command_BecomeWarden, "Warden menu");
	RegConsoleCmd("sm_w", Command_BecomeWarden, "Warden menu");
	RegConsoleCmd("sm_warden", Command_BecomeWarden, "Warden menu");
	RegConsoleCmd("sm_control", Command_BecomeWarden, "Warden menu");
	RegConsoleCmd("sm_c", Command_BecomeWarden, "Warden menu");
	
	RegServerCmd("jwp_menu_reload", Command_JwpMenuReload, "Reload menu list");
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", Event_OnRoundFreezeEnd, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	
	g_aSortedMenu = new ArrayList(66);
	g_aFlags = new ArrayList(1);
	Load_SortingWardenMenu();
	
	AutoExecConfig(true, "jwp", "jwp");
	
	g_bIsCSGO = (GetEngineVersion() == Engine_CSGO) ? true : false;
	
	LoadTranslations("jwp.phrases");
	LoadTranslations("common.phrases");
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

public void OnAllPluginsLoaded()
{
	if (g_CvarAutoUpdate.BoolValue && LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
}

public void OnLibraryAdded(const char[] name)
{
	if (g_CvarAutoUpdate.BoolValue && strcmp(name, "updater", true) == 0)
		Updater_AddPlugin(UPDATE_URL);
}

public Action Updater_OnPluginChecking()
{
	if (g_CvarAutoUpdate.BoolValue) return Plugin_Continue;
	return Plugin_Handled;
}

public int Updater_OnPluginUpdated()
{
	LogMessage("Plugin updated. Old version was %s. Now reloading.", PLUGIN_VERSION);
	ReloadPlugin();
}

public int Native_IsStarted(Handle plugin, int params)
{
	return IsStarted();
}

public void OnConfigsExecuted()
{
	OnReadyToStart();
}

public void OnClientDisconnect_Post(int client)
{
	if (IsWarden(client))
		RemoveCmd(false);
	else if (g_bIsDeveloper[client]) g_bIsDeveloper[client] = false;
	g_iVoteResult[client] = 0;
	
	// Modules client reset
	g_bHasFreeday[client] = false;
	g_bIsolated[client] = false;
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		// Modules client reset
		g_bHasFreeday[i] = false;
		g_bIsolated[i] = false;
	}
	Forward_OnWardenResigned(g_iWarden, false);
	EmptyPanel(g_iWarden);
	delete g_mMainMenu;
	g_iWarden = 0;
	g_iZamWarden = 0;
	g_bVoteFinished = false;
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (CheckClient(client))
	{
		if (IsWarden(client))
		{
			if (g_bIsCSGO)
				CGOPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_death", LANG_SERVER, client);
			else
				CPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_death", LANG_SERVER, client);
			RemoveCmd(false);
		}
		else if (IsZamWarden(client)) g_iZamWarden = 0;
		
		// Module client reset
		g_bHasFreeday[client] = false;
		g_bIsolated[client] = false;
	}
}

public void Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsWarden(client))
		RemoveCmd(false);
	else if (IsZamWarden(client)) g_iZamWarden = 0;
	
	// Module client reset
	g_bHasFreeday[client] = false;
	g_bIsolated[client] = false;
}

public void Event_OnRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
		g_bWasWarden[i] = false;
	g_bRoundEnd = false;
	if (!Forward_OnWardenChoosing())
		return;
	else if (g_CvarChooseMode.IntValue == 1)
	{
		int client = JWP_GetRandomTeamClient(CS_TEAM_CT, true, false);
		if (client) BecomeCmd(client);
	}
	else if (g_CvarChooseMode.IntValue == 2)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i))
			{
				if (g_bIsCSGO)
					CGOPrintToChat(i, "%T %T", "Core_Prefix", LANG_SERVER, "use_warden_cmd", LANG_SERVER);
				else
					CPrintToChat(i, "%T %T", "Core_Prefix", LANG_SERVER, "use_warden_cmd", LANG_SERVER);
			}
		}
	}
	else if (g_CvarChooseMode.IntValue == 3)
		JWP_StartVote();
}

public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnd = true;
	Forward_OnWardenResigned(g_iWarden, false);
	EmptyPanel(g_iWarden);
	delete g_mMainMenu;
	g_iWarden = 0;
	g_iZamWarden = 0;
	
	if (g_hChooseTimer != null)
	{
		KillTimer(g_hChooseTimer);
		g_hChooseTimer = null;
	}
	if (g_VoteMenu != null)
	{
		g_VoteMenu.Close();
		g_VoteMenu = null;
	}
	
	return Plugin_Continue;
}

public Action Command_JwpMenuReload(int args)
{
	RehashMenu();
	PrintToServer("[JWP] %T", "menu_success_reloaded", LANG_SERVER);
	return Plugin_Handled;
}

public Action Command_BecomeWarden(int client, int args)
{
	if (CheckClient(client))
	{
		if (g_bRoundEnd)
		{
			if (g_bIsCSGO)
				CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "wait_for_new_round", LANG_SERVER);
			else
				CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "wait_for_new_round", LANG_SERVER);
		}
		else if (g_iWarden > 0)
		{
			if (IsWarden(client))
				Cmd_ShowMenu(client);
			else if (g_bIsCSGO)
				CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_exists", LANG_SERVER, g_iWarden);
			else
				CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_exists", LANG_SERVER, g_iWarden);
		}
		else
		{
			if (!Forward_OnWardenChoosing())
				return Plugin_Handled;
			else if (g_CvarChooseMode.IntValue == 1)
			{
				if (g_bIsCSGO)
					CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_choose_random", LANG_SERVER);
				else
					CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_choose_random", LANG_SERVER);
			}
			else if (g_CvarChooseMode.IntValue == 3)
			{
				if (!g_bVoteFinished)
				{
					if (g_bIsCSGO)
						CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "cmd_not_available", LANG_SERVER);
					else
						CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "cmd_not_available", LANG_SERVER);
				}
				else
				{
					if (g_bIsCSGO)
						CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_choose_vote", LANG_SERVER);
					else
						CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_choose_vote", LANG_SERVER);
				}
			}
			else if (g_CvarChooseMode.IntValue == 2 && GetClientTeam(client) == CS_TEAM_CT)
			{
				if (BecomeCmd(client)) Cmd_ShowMenu(client);
			}
			else
			{
				if (g_bIsCSGO)
					CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_only_ct", LANG_SERVER);
				else
					CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_only_ct", LANG_SERVER);
			}
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

bool BecomeCmd(int client, bool waswarden = true, bool ignore_native = false)
{
	if (!Forward_OnWardenChoosing() && !ignore_native)
		return false;
	else if (g_bWasWarden[client] && waswarden)
	{
		if (g_bIsCSGO)
			CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "already_was_warden", LANG_SERVER);
		else
			CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "already_was_warden", LANG_SERVER);
	}
	else if (IsPlayerAlive(client))
	{
		g_iWarden = client;
		Forward_OnWardenChosen(client);
		g_bWasWarden[client] = true;
		// Show our warden menu
		Cmd_ShowMenu(client);
		if (g_bIsCSGO)
			CGOPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_become", LANG_SERVER, g_iWarden);
		else
			CPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_become", LANG_SERVER, g_iWarden);
		return true;
	}
	else
	{
		if (g_bIsCSGO)
			CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_must_be_alive", LANG_SERVER);
		else
			CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_must_be_alive", LANG_SERVER);
	}
	return false;
}

void RemoveCmd(bool themself = true)
{
	Forward_OnWardenResigned(g_iWarden, themself);
	if (themself)
	{
		if (g_bIsCSGO)
			CGOPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_resign", LANG_SERVER, g_iWarden);
		else
			CPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_resign", LANG_SERVER, g_iWarden);
	}
	EmptyPanel(g_iWarden);
	if (g_iWarden) g_iWarden = 0;
	delete g_mMainMenu;
	
	JWP_FindNewWarden();
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
		Forward_OnWardenZamChosen(client);
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

bool PrisonerHasFreeday(int client)
{
	if (client && IsClientInGame(client) && client <= MaxClients)
		return g_bHasFreeday[client];
	return false;
}

bool PrisonerSetFreeday(int client, bool state = true)
{
	if (client && IsClientInGame(client) && client <= MaxClients)
	{
		g_bHasFreeday[client] = state;
		return true;
	}
	return false;
}

bool IsPrisonerIsolated(int client)
{
	if (client && IsClientInGame(client) && client <= MaxClients)
		return g_bIsolated[client];
	return false;
}

bool PrisonerIsolated(int client, bool state = true)
{
	if (client && IsClientInGame(client) && client <= MaxClients)
	{
		g_bIsolated[client] = state;
		return true;
	}
	return false;
}

bool IsStarted()
{
	return is_started;
}

int JWP_GetTeamClient(int team, bool alive)
{
	int counter;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i) && GetClientTeam(i) == team)
		{
			if (alive)
			{
				if (IsPlayerAlive(i)) counter++;
			}
			else counter++;
		}
	}
	return counter;
}

void JWP_FindNewWarden()
{
	if (!JWP_GetTeamClient(CS_TEAM_T, true) || !JWP_GetTeamClient(CS_TEAM_CT, true))
		return;
	else if (g_iZamWarden)
	{
		BecomeCmd(g_iZamWarden);
		g_iZamWarden = 0;
	}
	else if (g_CvarChooseMode.IntValue == 1 || g_iZamWarden > 0)
	{
		if (g_hChooseTimer != null)
		{
			KillTimer(g_hChooseTimer);
			g_hChooseTimer = null;
		}
		g_hChooseTimer = CreateTimer(g_CvarRandomWait.FloatValue, g_ChooseTimer_Callback);
	}
	else if (g_CvarChooseMode.IntValue == 2)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i))
			{
				if (g_bIsCSGO)
					CGOPrintToChat(i, "%T %T", "Core_Prefix", LANG_SERVER, "use_warden_cmd", LANG_SERVER);
				else
					CPrintToChat(i, "%T %T", "Core_Prefix", LANG_SERVER, "use_warden_cmd", LANG_SERVER);
			}
		}
	}
	else if (g_CvarChooseMode.IntValue == 3)
	{
		int client = JWP_GetRandomTeamClient(CS_TEAM_CT, true, false);
		BecomeCmd(client);
	}
}

public Action g_ChooseTimer_Callback(Handle timer)
{
	if (!g_iWarden)
	{
		int client = g_iZamWarden;
		if (!client)
			client = JWP_GetRandomTeamClient(CS_TEAM_CT, true, true);
		if (client > 0)
			BecomeCmd(client);
	}
	g_hChooseTimer = null;
}

stock int JWP_GetRandomTeamClient(int team, bool alive, bool ignore_resign)
{
	int[] Players = new int[MaxClients];
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && (alive && IsPlayerAlive(i)))
		{
			if (!(ignore_resign && g_bWasWarden[i]))
				Players[count++] = i;
		}
	}
	return (!count) ? -1 : Players[GetRandomInt(0, count-1)];
}