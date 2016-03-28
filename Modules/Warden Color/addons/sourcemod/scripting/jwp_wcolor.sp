#include <sourcemod>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar	g_CvarWardenColor,
		g_CvarWardenZamColor;
int g_iWardenColor[4], g_iWardenZamColor[4];
bool g_bWardenColor, g_bWardenZamColor;

public Plugin myinfo = 
{
	name = "[JWP] Warden color",
	description = "Color for warden and him zam",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarWardenColor = CreateConVar("jwp_warden_rgba", "255 255 0 255", "Цвет скина который получит командир (rgba)", FCVAR_PLUGIN);
	g_CvarWardenZamColor = CreateConVar("jwp_warden_zam_rgba", "0 255 255 255", "Цвет скина который получит зам командира (rgba)", FCVAR_PLUGIN);
	
	g_CvarWardenColor.AddChangeHook(OnCvarChange);
	g_CvarWardenZamColor.AddChangeHook(OnCvarChange);
	
	ReadCfg();
	
	AutoExecConfig(true, "wcolor", "jwp");
}

public void OnConfigsExecuted()
{
	ReadCfg();
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarWardenColor)
	{
		char buffer[48];
		g_CvarWardenColor.SetString(newValue);
		strcopy(buffer, sizeof(buffer), newValue);
		g_bWardenColor = JWP_ConvertToColor(buffer, g_iWardenColor);
	}
	else if (cvar == g_CvarWardenZamColor)
	{
		char buffer[48];
		g_CvarWardenZamColor.SetString(newValue);
		strcopy(buffer, sizeof(buffer), newValue);
		g_bWardenZamColor = JWP_ConvertToColor(buffer, g_iWardenZamColor);
	}
}

public int JWP_OnWardenChosen(int client)
{
	if (!g_bWardenColor) return;
	else if (client && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, g_iWardenColor[0], g_iWardenColor[1], g_iWardenColor[2], g_iWardenColor[3]);
	}
}

public int JWP_OnWardenZamChosen(int client)
{
	if (!g_bWardenZamColor) return;
	else if (client && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, g_iWardenZamColor[0], g_iWardenZamColor[1], g_iWardenZamColor[2], g_iWardenZamColor[3]);
	}
}

public int JWP_OnWardenResigned(int client, bool self)
{
	if (!g_bWardenColor) return;
	else if (client && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

void ReadCfg()
{
	char buffer[48];
	g_CvarWardenColor.GetString(buffer, sizeof(buffer));
	g_bWardenColor = JWP_ConvertToColor(buffer, g_iWardenColor);
	g_CvarWardenZamColor.GetString(buffer, sizeof(buffer));
	g_bWardenZamColor = JWP_ConvertToColor(buffer, g_iWardenZamColor);
}