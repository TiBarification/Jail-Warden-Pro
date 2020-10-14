#include <sourcemod>
#include <cstrike>
#include <jwp>
#include <multicolors>

#define PLUGIN_VERSION "1.2"
#define CHECK_IS_T(%1) (IsClientInGame(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == CS_TEAM_T)

bool g_bVotes[MAXPLAYERS+1];
int g_iUses;

ConVar g_hVotePercent, g_hVoteLimitPerRound;
int g_iVotePercent, g_iLimitPerRound;

public Plugin myinfo =
{
    name = "[JWP] Warden votekick",
    description = "Allow T to kick current warden",
    author = "White Wolf",
    version = PLUGIN_VERSION,
    url = "https://scirptplugs.info https://steamcommunity.com/id/doctor_white"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	RegConsoleCmd("sm_wvotekick", Command_WardenVoteKick, "Vote to force warden resign");
	
	g_hVotePercent = CreateConVar("sm_jwp_votewardenkick_percent", "60", "Percent of T votes need to kick warden", FCVAR_NONE, true, 1.0, true, 100.0);
	g_iLimitPerRound = g_hVotePercent.IntValue;
	g_hVotePercent.AddChangeHook(OnCvarChange);
	g_hVoteLimitPerRound = CreateConVar("sm_jwp_votewardenkick_per_round", "3", "Limit of kicks per round", FCVAR_NONE, true, 0.0, true, 100.0);
	g_iLimitPerRound = g_hVoteLimitPerRound.IntValue;
	g_hVoteLimitPerRound.AddChangeHook(OnCvarChange);
	
	LoadTranslations("jwp_modules.phrases");

	AutoExecConfig(true, "wvotekick", "jwp");
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_hVotePercent) {
		g_iVotePercent = StringToInt(newValue);
	}
	else if (cvar == g_hVoteLimitPerRound) {
		g_iLimitPerRound = StringToInt(newValue);
	}
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iUses = 0;
	ResetVotes();
}

public void OnClientDisconnect(int client)
{
	g_bVotes[client] = false;
}

public Action Command_WardenVoteKick(int client, int args)
{	
	if (!args && client && IsClientInGame(client))
	{
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			if (g_iLimitPerRound > 0 && g_iUses >= g_iLimitPerRound)
				CPrintToChat(client, "%t", "VoteWardenKick_AvailablePerRound");
			else if (!VoteForPlayer(client))
				CPrintToChat(client, "%t", "VoteWardenKick_NoWarden");
		}
		else
			CPrintToChat(client, "%t", "VoteWardenKick_OnlyT");
	}
	
	return Plugin_Handled;
}

stock int GetTerroristCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CHECK_IS_T(i))
			count++;
	}
	
	return count;
}

int GetVotesCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CHECK_IS_T(i) && g_bVotes[i])
			count++;
	}
	
	return count;
}

stock int NeedVotes()
{
	return (g_iVotePercent * GetTerroristCount()) / 100;
}

bool VoteForPlayer(int client)
{
	int victim = JWP_GetWarden();
	if (!CheckClient(client) || !CheckClient(victim) || !JWP_IsWarden(victim)) return false;
	
	int needed_votes = NeedVotes();
	int current_votes;
	
	if (g_bVotes[client])
	{
		current_votes = GetVotesCount();
		CPrintToChat(client, "%t", "VoteWardenKick_VoteReplyRepeat", victim, current_votes, needed_votes);
		return true;
	}
	else
		g_bVotes[client] = true;
	current_votes = GetVotesCount();
	
	CPrintToChatAll("%t", "VoteWardenKick_VoteReply", client, victim, current_votes, needed_votes);
	
	if (current_votes >= needed_votes)
		ForceResign(victim);
	return true;
}

void ResetVotes()
{
	for (int i = 1; i <= MaxClients; i++)
		g_bVotes[i] = false;
}

bool CheckClient(int client)
{
	return (client > 0 && IsClientInGame(client) && !IsFakeClient(client));
}

stock void ForceResign(int client)
{
	if (!CheckClient(client) || !JWP_IsWarden(client)) return;
	
	JWP_SetWarden(0);
	g_iUses++;
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	ResetVotes();
}