#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define ITEM "pris_counter"

ConVar g_CvarRadius, g_CvarIncludeFD;

public Plugin myinfo = 
{
	name = "[JWP] Prisoner Counter",
	description = "Warden can count prisoners",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarRadius = CreateConVar("jwp_pris_counter_radius", "650.0", "Радиус в котором считать Т", _, true, 1.0, true, 2750.0);
	g_CvarIncludeFD = CreateConVar("jwp_pris_counter_fd", "1", "Включать фридейщиков в поиск?", _, true, 0.0, true, 1.0);
	
	g_CvarRadius.AddChangeHook(OnCvarChange);
	g_CvarIncludeFD.AddChangeHook(OnCvarChange);
	
	if (JWP_IsStarted()) JWP_Started();
	
	AutoExecConfig(true, "pris_counter", "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarRadius) cvar.SetFloat(StringToFloat(newValue));
	else if (cvar == g_CvarIncludeFD) cvar.SetBool(view_as<bool>(StringToInt(newValue)));
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Pris_Counter_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (JWP_IsFlood(client)) return false;
	int count[3];
	// Reset count
	count[0] = 0; // Count all, except freeday players
	count[1] = 0; // Count freeday players
	count[2] = 0; // Count everyone T
	// End of reset
	float warden_origin[3];
	float pris_origin[MAXPLAYERS+1][3];
	// Save temporary distance between players
	float distance;
	
	GetClientAbsOrigin(client, warden_origin);
	ArrayList Rebels = new ArrayList(1);
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			if (!JWP_PrisonerHasFreeday(i))
			{
				GetClientAbsOrigin(i, pris_origin[i]);
				distance = GetVectorDistance(warden_origin, pris_origin[i], false);
				
				// Count distance
				if (distance <= g_CvarRadius.FloatValue)
					count[0]++;
				else
					Rebels.Push(i);
			}
			else if (g_CvarIncludeFD.BoolValue)
				count[1]++; // Increment freeday players
			count[2]++; // Increment everyone T
		}
	}
	
	JWP_ActionMsg(client, "\x04%d\x03/\x04%d \x03%T", count[0], count[2], "Pris_Counter_ActionMessage_Near", LANG_SERVER);
	if (g_CvarIncludeFD.BoolValue)
		JWP_ActionMsg(client, "\x05%T \x02%d", "Pris_Counter_ActionMessage_Freeday", LANG_SERVER, count[1]);
	
	if (Rebels.Length > 0)
	{
		int user;
		JWP_ActionMsg(client, "\x06%T", "Pris_Counter_ActionMessage_Escaped", LANG_SERVER);
		for (int i = 0; i < Rebels.Length; ++i)
		{
			user = Rebels.Get(i);
			if (user && IsClientInGame(user))
				JWP_ActionMsg(client, "%N", user);
		}
	}
	delete Rebels;
	
	JWP_ShowMainMenu(client);
	return true;
}