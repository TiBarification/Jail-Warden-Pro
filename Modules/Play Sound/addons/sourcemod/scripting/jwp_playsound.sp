#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "playsound"

ConVar g_CvarSound;
char g_cSound[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "[JWP] Play Sound",
	description = "Ability to play sound",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru https://tibari.ru"
};

public void OnPluginStart()
{
	g_CvarSound = CreateConVar("jwp_playsound_sound", "", "Sound path without sound dir");
	
	LoadTranslations("jwp_modules.phrases");
	if (JWP_IsStarted()) JWP_Started();
	
	AutoExecConfig(true, "playsound", "jwp");
}

public void OnMapStart()
{
	g_CvarSound.GetString(g_cSound, sizeof(g_cSound));
	if (g_cSound[0])
	{
		PrecacheSoundAny(g_cSound);
		Format(g_cSound, sizeof(g_cSound), "sound/%s", g_cSound);
		AddFileToDownloadsTable(g_cSound);
		g_CvarSound.GetString(g_cSound, sizeof(g_cSound));
	}
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnItemDisplay, OnItemSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnItemDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "PlaySound_Menu", LANG_SERVER);
	return true;
}

public bool OnItemSelect(int client)
{
	if (!JWP_IsFlood(client))
	{
		if (g_cSound[0])
			EmitSoundToAllAny(g_cSound);
		else return false;
	}
	return true;
}