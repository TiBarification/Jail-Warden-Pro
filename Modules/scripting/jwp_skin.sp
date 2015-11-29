#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_CvarWardenSkin, g_CvarWardenZamSkin;
char g_cWardenSkin[PLATFORM_MAX_PATH], g_cWardenZamSkin[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "[JWP] Skin",
	description = "Sets skin for warden and zam",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarWardenSkin = CreateConVar("jwp_warden_skin", "", "Устанавливает скин командиру, оставьте пустым чтобы не использовать", FCVAR_PLUGIN);
	g_CvarWardenZamSkin = CreateConVar("jwp_warden_zam_skin", "", "Устанавливает скин заместителю командира, оставьте пустым чтобы не использовать", FCVAR_PLUGIN);
	
	g_CvarWardenSkin.AddChangeHook(OnCvarChange);
	g_CvarWardenZamSkin.AddChangeHook(OnCvarChange);
	AutoExecConfig(true, ITEM, "jwp");
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarWardenSkin)
	{
		g_CvarWardenSkin.SetString(newValue);
		strcopy(g_cWardenSkin, sizeof(g_cWardenSkin), newValue);
	}
	else if (cvar == g_CvarWardenZamSkin)
	{
		g_CvarWardenZamSkin.SetString(newValue);
		strcopy(g_cWardenZamSkin, sizeof(g_cWardenZamSkin), newValue);
	}
}

public void OnConfigsExecuted()
{
	g_CvarWardenSkin.GetString(g_cWardenSkin, sizeof(g_cWardenSkin));
	g_CvarWardenZamSkin.GetString(g_cWardenZamSkin, sizeof(g_cWardenZamSkin));
}

public void OnMapStart()
{
	// Standart model for default
	PrecacheModel("models/player/ct_sas.mdl", true);
	// Other models
	if (g_cWardenSkin[0] == 'm')
		PrecacheModel(g_cWardenSkin, true);
	if (g_cWardenZamSkin[0] == 'm')
		PrecacheModel(g_cWardenZamSkin, true);
}

public int JWP_OnWardenChosen(int client)
{
	if (g_cWardenSkin[0] == 'm')
		SetEntityModel(client, g_cWardenSkin);
}

public int JWP_OnWardenZamChosen(int client)
{
	if (g_cWardenZamSkin[0] == 'm')
		SetEntityModel(client, g_cWardenZamSkin);
}

