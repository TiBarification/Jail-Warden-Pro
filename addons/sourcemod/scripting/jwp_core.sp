#include <sourcemod>
#include <cstrike>
#include <SteamWorks>
#undef REQUIRE_PLUGIN
#tryinclude <csgo_colors>
#tryinclude <morecolors>
#include <updater>

// Force new syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.4.2"

#define UPDATE_URL "http://updater.tibari.dev/jwp/updatefile.txt"
#define LOG_PATH "addons/sourcemod/logs/JWP_Log.log"

stock const char API_KEY[] = "0f0f2821d03a230f3e79f7227711005d";

//#define DEBUG

int g_iWarden, g_iZamWarden;

bool is_started;
bool g_bRoundEnd;
bool g_bIsCSGO;

ArrayList g_aSortedMenu;
ArrayList g_aFlags;

enum struct APITarget
{
	bool has_freeday;
	bool is_isolated;
	bool is_rebel;
	bool was_warden;
	
	void Reset() {
		this.has_freeday = false;
		this.is_isolated = false;
		this.is_rebel = false;
		this.was_warden = false;
	}
}

APITarget g_ClientAPIInfo[MAXPLAYERS+1];

ConVar	g_CvarChooseMode,
		g_CvarRandomWait,
		g_CvarVoteTime,
		g_CvarDisableAntiFlood,
		g_CvarAutoUpdate,
		g_CvarMenuAutoOpen;

Handle g_hChooseTimer;

#include "jwp/kv_reader.sp"
#include "jwp/jwpm_menu.sp"
#include "jwp/forwards.sp"
#include "jwp/natives.sp"
#include "jwp/voting.sp"
#include "jwp/utils.sp"

public Plugin myinfo = 
{
	name = "[JWP] Core",
	description = "Jail Warden Pro Core",
	author = "White Wolf (TiBarification)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru http://steamcommunity.com/id/doctor_white"
};

public void OnPluginStart()
{
	CreateConVar("jwp_version", PLUGIN_VERSION, _, FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarChooseMode = CreateConVar("jwp_choose_mode", "2", "How to choose warden 1:random 2:command 3:voting", FCVAR_SPONLY, true, 1.0, true, 3.0);
	g_CvarRandomWait = CreateConVar("jwp_random_wait", "5", "Time before warden randomly picked if choose mode = 1", FCVAR_SPONLY, true, 1.0, true, 30.0);
	g_CvarVoteTime = CreateConVar("jwp_vote_time", "30", "Time for voting if choose mode = 3", FCVAR_SPONLY, true, 10.0, true, 60.0);
	g_CvarDisableAntiFlood = CreateConVar("jwp_disable_antiflood", "0", "Disable menu protection from spam-clicking", FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_CvarAutoUpdate = CreateConVar("jwp_autoupdate", "1", "Enable (1) or disable (0) auto update. Need Updater!", FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_CvarMenuAutoOpen = CreateConVar("jwp_menuautoopen", "1", "Enable (1) or disable (0) warden menu auto open after warden chosen!", FCVAR_SPONLY, true, 0.0, true, 1.0);
	
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
	LoadTranslations("core.phrases");
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
	if (g_CvarAutoUpdate.BoolValue && LibraryExists("updater") && GetFeatureStatus(FeatureType_Native, "Updater_AddPlugin") == FeatureStatus_Available)
		Updater_AddPlugin(UPDATE_URL);
}

public void OnLibraryAdded(const char[] name)
{
	if (g_CvarAutoUpdate.BoolValue && !strcmp(name, "updater", true) && GetFeatureStatus(FeatureType_Native, "Updater_AddPlugin") == FeatureStatus_Available)
		Updater_AddPlugin(UPDATE_URL);
}

public Action Updater_OnPluginChecking()
{
	if (g_CvarAutoUpdate.BoolValue) return Plugin_Continue;
	return Plugin_Handled;
}

public void Updater_OnPluginUpdated()
{
	LogToFile(LOG_PATH, "Plugin updated. You need to change map.");
}

public int Native_IsStarted(Handle plugin, int params)
{
	return IsStarted();
}

public void OnConfigsExecuted()
{
	OnReadyToStart();
}

public void OnClientPostAdminCheck(int client)
{
	g_ClientAPIInfo[client].Reset();
}

public void OnClientDisconnect_Post(int client)
{
	if (IsWarden(client))
		RemoveCmd(false);
	else if (IsZamWarden(client))
		RemoveZam();
	g_iVoteResult[client] = 0;
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		// Modules client reset
		g_ClientAPIInfo[i].has_freeday = false;
		g_ClientAPIInfo[i].is_isolated = false;
	}
	bool bAllowResign = true;
	if (g_iWarden > 0)
		bAllowResign = Forward_OnWardenResign(g_iWarden);
	
	if (bAllowResign)
	{
		EmptyPanel();
		delete g_mMainMenu;
		int iOldWarden = g_iWarden;
		g_iWarden = 0;
		if (iOldWarden > 0)
		Forward_OnWardenResigned(iOldWarden, false);
	}
	
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
		else if (IsZamWarden(client)) RemoveZam();
		
		// Module client reset
		g_ClientAPIInfo[client].has_freeday = false;
		g_ClientAPIInfo[client].is_isolated = false;
		g_ClientAPIInfo[client].is_rebel = false;
	}
}

public void Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsWarden(client))
		RemoveCmd(false);
	else if (IsZamWarden(client)) RemoveZam();
	
	// Module client reset
	g_ClientAPIInfo[client].has_freeday = false;
	g_ClientAPIInfo[client].is_isolated = false;
	g_ClientAPIInfo[client].is_rebel = false;
}

public void Event_OnRoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
		g_ClientAPIInfo[i].was_warden = false;
	g_bRoundEnd = false;
	if (Forward_OnWardenChoosing() == false)
		return;
	else if (g_CvarChooseMode.IntValue == 1)
		JWP_FindNewWarden();
	else if (g_CvarChooseMode.IntValue == 2)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i) && GetClientTeam(i) == CS_TEAM_CT)
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
	EmptyPanel();
	delete g_mMainMenu;
	g_iWarden = 0;
	Forward_OnWardenResigned(g_iWarden, false);
	
	RemoveZam();
	
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
	
	if (g_VoteTimer != null)
	{
		KillTimer(g_VoteTimer);
		g_VoteTimer = null;
	}
	
	return Plugin_Continue;
}

public Action Command_JwpMenuReload(int args)
{
	RehashMenu(true);
	PrintToServer("[JWP] %T", "menu_success_reloaded", LANG_SERVER);
	return Plugin_Handled;
}

public Action Command_BecomeWarden(int client, int args)
{
	if (CheckClient(client))
	{
		if (Forward_OnWardenChoosing() == false)
		{
			if (g_bIsCSGO)
				CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_blocked", LANG_SERVER);
			else
				CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_blocked", LANG_SERVER);
		}
		else if (g_bRoundEnd)
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
			if (g_CvarChooseMode.IntValue == 1)
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
				BecomeCmd(client);
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
		
		Function func = GetFunctionByName(plugin, "JWP_Started");
		
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
	#if defined DEBUG
	return (client > 0 && IsClientConnected(client) && IsClientInGame(client));
	#else
	return (client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client));
	#endif
}

bool BecomeCmd(int client, bool waswarden = true)
{
	if (CheckClient(client) == false || Forward_OnWardenChoosing() == false)
		return false;
	
	if (!IsPlayerAlive(client))
	{
		if (g_bIsCSGO)
			CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_must_be_alive", LANG_SERVER);
		else
			CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "warden_must_be_alive", LANG_SERVER);
	}
	else if (g_ClientAPIInfo[client].was_warden && waswarden)
	{
		if (g_bIsCSGO)
			CGOPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "already_was_warden", LANG_SERVER);
		else
			CPrintToChat(client, "%T %T", "Core_Prefix", LANG_SERVER, "already_was_warden", LANG_SERVER);
	}
	else if (client > 0)
	{
		g_iWarden = client;
		Forward_OnWardenChosen(g_iWarden);
		g_ClientAPIInfo[g_iWarden].was_warden = true;
		// Remove if new warden is previous zam of warden
		if (g_iZamWarden == g_iWarden)
			RemoveZam();
		// Show our warden menu
		if (g_CvarMenuAutoOpen.BoolValue)
			Cmd_ShowMenu(g_iWarden, _, true);
		if (g_bIsCSGO)
			CGOPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_become", LANG_SERVER, g_iWarden);
		else
			CPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_become", LANG_SERVER, g_iWarden);
		return true;
	}
	return false;
}

void RemoveCmd(bool themself = true)
{
	if (g_iWarden)
	{
		if (Forward_OnWardenResign(g_iWarden))
		{
			if (themself)
			{
				if (g_bIsCSGO)
					CGOPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_resign", LANG_SERVER, g_iWarden);
				else
					CPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_resign", LANG_SERVER, g_iWarden);
			}
			EmptyPanel();
			int iOldWarden = g_iWarden;
			g_iWarden = 0;
			delete g_mMainMenu;
			
			Forward_OnWardenResigned(iOldWarden, themself);
			JWP_FindNewWarden();
		}
	}
}

int RemoveZam()
{
	if (g_iZamWarden)
	{
		int iOldZam = g_iZamWarden;
		g_iZamWarden = 0;
		Forward_OnWardenZamResigned(iOldZam);
		return iOldZam;
	}
	return 0;
}

bool SetZam(int client)
{
	if (CheckClient(client) && IsPlayerAlive(client) && client != g_iWarden)
	{
		g_iZamWarden = client;
		Forward_OnWardenZamChosen(client);
		// Give user ability to be warden if no warden
		if (g_ClientAPIInfo[client].was_warden) g_ClientAPIInfo[client].was_warden = false;
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
	if (client <= MaxClients && CheckClient(client))
		return g_ClientAPIInfo[client].has_freeday;
	return false;
}

bool PrisonerSetFreeday(int client, bool state = true)
{
	if (client <= MaxClients && CheckClient(client))
	{
		g_ClientAPIInfo[client].has_freeday = state;
		return true;
	}
	return false;
}

bool IsPrisonerIsolated(int client)
{
	if (client <= MaxClients && CheckClient(client))
		return g_ClientAPIInfo[client].is_isolated;
	return false;
}

bool PrisonerIsolated(int client, bool state = true)
{
	if (client <= MaxClients && CheckClient(client))
	{
		g_ClientAPIInfo[client].is_isolated = state;
		return true;
	}
	return false;
}

bool PrisonerRebel(int client, bool state = true)
{
	if (client <= MaxClients && CheckClient(client))
	{
		g_ClientAPIInfo[client].is_rebel = state;
		return true;
	}
	return false;
}

bool IsPrisonerRebel(int client)
{
	if (client <= MaxClients && CheckClient(client))
		return g_ClientAPIInfo[client].is_rebel;
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
			if (alive && IsPlayerAlive(i))
				counter++;
			else counter++;
		}
	}
	return counter;
}

void JWP_FindNewWarden()
{
	if (Forward_OnWardenChoosing() == false)
		return;
	
	if (g_iZamWarden)
	{
		int prevZam = RemoveZam();
		if (prevZam > 0)
		{
			BecomeCmd(prevZam);
		}
	}
	else if (g_CvarChooseMode.IntValue == 1 || g_CvarChooseMode.IntValue == 3)
	{
		if (g_hChooseTimer != null)
		{
			delete g_hChooseTimer;
			g_hChooseTimer = null;
		}
		if (g_CvarChooseMode.IntValue == 1)
			g_hChooseTimer = CreateTimer(g_CvarRandomWait.FloatValue, g_ChooseTimer_Callback);
		else
			g_hChooseTimer = CreateTimer(0.1, g_ChooseTimer_Callback);
	}
	else if (g_CvarChooseMode.IntValue == 2)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i) && GetClientTeam(i) == CS_TEAM_CT)
			{
				if (g_bIsCSGO)
					CGOPrintToChat(i, "%T %T", "Core_Prefix", LANG_SERVER, "use_warden_cmd", LANG_SERVER);
				else
					CPrintToChat(i, "%T %T", "Core_Prefix", LANG_SERVER, "use_warden_cmd", LANG_SERVER);
			}
		}
	}
}

public Action g_ChooseTimer_Callback(Handle timer)
{
	if (!g_iWarden && Forward_OnWardenChoosing())
	{
		int client = g_iZamWarden;
		
		if (CheckClient(client) == false)
			client = JWP_GetRandomTeamClient(CS_TEAM_CT, true, true, false);
		if (CheckClient(client))
			BecomeCmd(client, false);
		else
		{
			int t_count, ct_count;
			t_count = JWP_GetTeamClient(CS_TEAM_T, true);
			ct_count = JWP_GetTeamClient(CS_TEAM_CT, true);
			if (!t_count || !ct_count)
			{
				if (g_bIsCSGO)
					CGOPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_unable_due_to_teamcount", LANG_SERVER, t_count, ct_count);
				else
					CPrintToChatAll("%T %T", "Core_Prefix", LANG_SERVER, "warden_unable_due_to_teamcount", LANG_SERVER, t_count, ct_count);
			}
		}
	}
	g_hChooseTimer = null;

	return Plugin_Stop;
}

stock int JWP_GetRandomTeamClient(int team, bool alive, bool ignore_resign, bool allow_bot)
{
	int[] Players = new int[MaxClients + 1];
	int count = 0;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			if (allow_bot == false && IsFakeClient(i) == true) continue;
			if (alive == true && IsPlayerAlive(i) == false)
				continue;
			
			if (ignore_resign == false && g_ClientAPIInfo[i].was_warden == true) continue;
			
			if (team != -1 && GetClientTeam(i) == team)
				Players[count++] = i;
			else if (team == -1)
				Players[count++] = i;
		}
	}
	return (!count) ? -1 : Players[GetRandomInt(0, count-1)];
}

/* Stats pusher */
public void SteamWorks_SteamServersConnected()
{
	int iIp[4];
	
	// Get ip
	if (SteamWorks_GetPublicIP(iIp))
	{
		Handle plugin = GetMyHandle();
		if (GetPluginStatus(plugin) == Plugin_Running)
		{
			char cBuffer[256], cVersion[12];
			GetPluginInfo(plugin, PlInfo_Version, cVersion, sizeof(cVersion));
			FormatEx(cBuffer, sizeof(cBuffer), "http://stats.tibari.dev/api/v1/add_server");
			Handle hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, cBuffer);
			if (g_bIsCSGO)
				FormatEx(cBuffer, sizeof(cBuffer), "key=%s&ip=%d.%d.%d.%d&port=%d&version=%s&sm=%s", API_KEY, iIp[0], iIp[1], iIp[2], iIp[3], FindConVar("hostport").IntValue, cVersion, SOURCEMOD_VERSION);
			else
				FormatEx(cBuffer, sizeof(cBuffer), "key=%s&ip=%d.%d.%d.%d&port=%d&version=%s", API_KEY, iIp[0], iIp[1], iIp[2], iIp[3], FindConVar("hostport").IntValue, cVersion);
			SteamWorks_SetHTTPRequestRawPostBody(hndl, "application/x-www-form-urlencoded", cBuffer, sizeof(cBuffer));
			SteamWorks_SendHTTPRequest(hndl);
			delete hndl;
		}
	}
}
