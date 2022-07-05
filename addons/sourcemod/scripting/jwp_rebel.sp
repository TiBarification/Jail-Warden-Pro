#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.8"

ConVar	g_CvarRebelColor_r,
		g_CvarRebelColor_g,
		g_CvarRebelColor_b,
		g_CvarRebelColor_a,
		g_CvarRebelTime,
		g_CvarRebelDamage;

Handle g_TimerColor[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[JWP] Rebel",
	description = "Prisoners that perform damage notified as rebels",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarRebelColor_r = CreateConVar("jwp_rebel_color_r", "120", "Red value of rebel in RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelColor_g = CreateConVar("jwp_rebel_color_g", "0", "Green value of rebel in RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelColor_b = CreateConVar("jwp_rebel_color_b", "0", "Blue value of rebel in RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelColor_a = CreateConVar("jwp_rebel_color_a", "255", "Alpha value of rebel in RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelTime = CreateConVar("jwp_rebel_sec", "5", "If T hurt CT, how many seconds T will be rebel? (0 = disable)", _, true, 0.0, true, 240.0);
	g_CvarRebelDamage = CreateConVar("jwp_rebel_damage", "35", "Necessary amount of damage, that need to become rebel", _, true, 1.0);
	
	AutoExecConfig(true, "rebel", "jwp");
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
	
	LoadTranslations("jwp_modules.phrases");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	if (g_TimerColor[client] != null)
	{
		KillTimer(g_TimerColor[client]);
		g_TimerColor[client] = null;
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (attacker > 0 &&
		(attacker <= MaxClients) &&
		victim > 0 && victim <= MaxClients &&
		attacker != victim &&
		IsClientInGame(attacker) &&
		IsClientInGame(victim) &&
		GetClientTeam(attacker) == CS_TEAM_T &&
		GetClientTeam(victim) == CS_TEAM_CT)
	{
		if (!JWP_IsPrisonerRebel(attacker) && (damage >= g_CvarRebelDamage.IntValue))
		{
			if (g_CvarRebelColor_r.IntValue == 255 && g_CvarRebelColor_g.IntValue == 255 && g_CvarRebelColor_b.IntValue == 255 && g_CvarRebelColor_a.IntValue == 255)
				return Plugin_Continue;
			else
			{
				SetEntityRenderMode(attacker, RENDER_TRANSCOLOR);
				SetEntityRenderColor(attacker, g_CvarRebelColor_r.IntValue, g_CvarRebelColor_g.IntValue, g_CvarRebelColor_b.IntValue, g_CvarRebelColor_a.IntValue);
			}
			JWP_ActionMsgAll("%T", "Rebel_Message", LANG_SERVER, attacker);
			if (g_CvarRebelTime.IntValue)
				g_TimerColor[attacker] = CreateTimer(g_CvarRebelTime.FloatValue, g_TimerColor_Callback, attacker);
			JWP_PrisonerRebel(attacker, true);
		}
	}
	return Plugin_Continue;
}

public Action g_TimerColor_Callback(Handle timer, any client)
{
	if (client && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	
	JWP_PrisonerRebel(client, false);
	g_TimerColor[client] = null;

	return Plugin_Stop;
}
