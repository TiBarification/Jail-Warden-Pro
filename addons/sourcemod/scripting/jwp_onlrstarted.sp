#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <emitsoundany>
#include <hosties>
#include <lastrequest>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.4"

bool g_bEnabled = true;

public Plugin myinfo = 
{
	name = "[JWP] On LR Started",
	description = "Remove cmd & zam if LR started",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	/* Recommended to set this here, because warden search is begining on round_start event */
	g_bEnabled = true;
}

public void OnAvailableLR(int announce)
{
	// Disable searching for a new warden
	g_bEnabled = false;
	// announce just notify that LR is available and can be disabled
	// At first we remove zam and after warden
	JWP_SetZamWarden(0);
	JWP_SetWarden(0);
	// Then we remove all freeday players
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && JWP_PrisonerHasFreeday(i))
			JWP_PrisonerSetFreeday(i, false);
	}
}

public bool JWP_OnWardenChoosing()
{
	return g_bEnabled;
}
