#include <sourcemod>
// #include <sdktools>
#include <cstrike>
#include <jwp>

#define PLUGIN_VERSION "1.0"
#define VOTE_PERCENT 70

bool g_bVotes[MAXPLAYERS+1];
bool g_bAllowedVote;

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
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bAllowedVote = true;
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
			if (!g_bAllowedVote)
				PrintToChat(client, "\x01[\x03JWP\x01] \x04Голосование за изгнание командира доступно лишь раз за раунд");
			else if (!VoteForPlayer(client))
				PrintToChat(client, "\x01[\x03JWP\x01] \x04Командира нет");
		}
		else
			PrintToChat(client, "\x01[\x03JWP\x01] \x04Только Т могут голосовать");
	}
	
	return Plugin_Handled;
}

stock int GetTerroristCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T)
			count++;
	}
	
	return count;
}

stock int GetVotesCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && g_bVotes[i])
			count++;
	}
	
	return count;
}

stock int NeedVotes()
{
	return (VOTE_PERCENT * GetTerroristCount()) / 100;
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
		PrintToChat(client, "\x01[\x03JWP\x01] \x04Вы уже голосовали за увольнение командира %N. Проголосовало %d/%d человек", victim, current_votes, needed_votes);
		return true;
	}
	else
		g_bVotes[client] = true;
	current_votes = GetVotesCount();
	
	PrintToChatAll("\x01[\x03JWP\x01] \x04%N проголосовал за увольнение командира %N (%d/%d голосов)", client, victim, current_votes, needed_votes);
	
	if (current_votes >= needed_votes)
		ForceResign(victim);
	return true;
}

void ResetVotes()
{
	for (int i = 1; i <= MaxClients; i++)
		g_bVotes[i] = false;
}

stock bool CheckClient(int client)
{
	return (client > 0 && IsClientInGame(client) && !IsFakeClient(client));
}

stock void ForceResign(int client)
{
	if (!CheckClient(client) || !JWP_IsWarden(client)) return;
	
	JWP_SetWarden(0);
	g_bAllowedVote = false;
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	ResetVotes();
}