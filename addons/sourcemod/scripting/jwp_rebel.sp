#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.5"

bool g_bIsRebel[MAXPLAYERS+1];

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
	g_CvarRebelColor_r = CreateConVar("jwp_rebel_color_r", "120", "Красный оттенок бунтовщика в RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelColor_g = CreateConVar("jwp_rebel_color_g", "0", "Зеленый оттенок бунтовщика в RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelColor_b = CreateConVar("jwp_rebel_color_b", "0", "Синий оттенок бунтовщика в RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelColor_a = CreateConVar("jwp_rebel_color_a", "255", "Прозрачность бунтовщика в RGBA", _, true, 0.0, true, 255.0);
	g_CvarRebelTime = CreateConVar("jwp_rebel_sec", "5", "Если T ранил CT, сколько секунд T будет бунтующим? (0 = бунт откл)", _, true, 0.0, true, 240.0);
	g_CvarRebelDamage = CreateConVar("jwp_rebel_damage", "35", "Необходимое количество урона, чтобы посчитать за бунт", _, true, 1.0);
	
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
	if (attacker &&
		(attacker <= MaxClients) &&
		attacker != victim &&
		IsClientInGame(attacker) &&
		IsClientInGame(victim) &&
		GetClientTeam(attacker) == CS_TEAM_T &&
		GetClientTeam(victim) == CS_TEAM_CT)
	{
		if (!g_bIsRebel[attacker] && (damage >= g_CvarRebelDamage.IntValue))
		{
			if (g_CvarRebelColor_r.IntValue == 255 && g_CvarRebelColor_g.IntValue == 255 && g_CvarRebelColor_b.IntValue == 255 && g_CvarRebelColor_a.IntValue == 255)
				return Plugin_Continue;
			else
			{
				SetEntityRenderMode(attacker, RENDER_TRANSCOLOR);
				SetEntityRenderColor(attacker, g_CvarRebelColor_r.IntValue, g_CvarRebelColor_g.IntValue, g_CvarRebelColor_b.IntValue, g_CvarRebelColor_a.IntValue);
			}
			PrintToChatAll("\x01\x02%T", "Rebel_Message", LANG_SERVER, attacker);
			if (g_CvarRebelTime.IntValue)
				g_TimerColor[attacker] = CreateTimer(g_CvarRebelTime.FloatValue, g_TimerColor_Callback, attacker);
			g_bIsRebel[attacker] = true;
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
	
	g_bIsRebel[client] = false;
	g_TimerColor[client] = null;
}