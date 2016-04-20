#include <sourcemod>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.1"

ConVar	g_CvarWardenColor_r,
		g_CvarWardenColor_g,
		g_CvarWardenColor_b,
		g_CvarWardenColor_a,
		g_CvarWardenZamColor_r,
		g_CvarWardenZamColor_g,
		g_CvarWardenZamColor_b,
		g_CvarWardenZamColor_a;

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
	g_CvarWardenColor_r = CreateConVar("jwp_warden_color_r", "255", "Красный оттенок командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_CvarWardenColor_g = CreateConVar("jwp_warden_color_g", "255", "Зеленый оттенок командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_CvarWardenColor_b = CreateConVar("jwp_warden_color_b", "0", "Синий оттенок командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_CvarWardenColor_a = CreateConVar("jwp_warden_color_a", "255", "Прозрачность командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_CvarWardenZamColor_r = CreateConVar("jwp_warden_zam_color_r", "0", "Красный оттенок зама командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_CvarWardenZamColor_g = CreateConVar("jwp_warden_zam_color_g", "255", "Зеленый оттенок зама командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_CvarWardenZamColor_b = CreateConVar("jwp_warden_zam_color_b", "255", "Синий оттенок зама командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	g_CvarWardenZamColor_a = CreateConVar("jwp_warden_zam_color_a", "255", "Прозрачность зама командира (rgba)", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	
	AutoExecConfig(true, "wcolor", "jwp");
}

public int JWP_OnWardenChosen(int client)
{
	if (g_CvarWardenColor_r.IntValue == 255 && g_CvarWardenColor_g.IntValue == 255 && g_CvarWardenColor_b.IntValue == 255 && g_CvarWardenColor_a.IntValue == 255) return;
	else if (client && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, g_CvarWardenColor_r.IntValue, g_CvarWardenColor_g.IntValue, g_CvarWardenColor_b.IntValue, g_CvarWardenColor_a.IntValue);
	}
}

public int JWP_OnWardenZamChosen(int client)
{
	if (g_CvarWardenZamColor_r.IntValue == 255 && g_CvarWardenZamColor_g.IntValue == 255 && g_CvarWardenZamColor_b.IntValue == 255 && g_CvarWardenZamColor_a.IntValue == 255) return;
	else if (client && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, g_CvarWardenZamColor_r.IntValue, g_CvarWardenZamColor_g.IntValue, g_CvarWardenZamColor_b.IntValue, g_CvarWardenZamColor_a.IntValue);
	}
}

public int JWP_OnWardenResigned(int client, bool self)
{
	if (g_CvarWardenColor_r.IntValue == 255 && g_CvarWardenColor_g.IntValue == 255 && g_CvarWardenColor_b.IntValue == 255 && g_CvarWardenColor_a.IntValue == 255) return;
	else if (client && IsClientInGame(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}