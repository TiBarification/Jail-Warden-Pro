#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_CvarWardenSkin, g_CvarWardenZamSkin, g_CvarTRandomSkins, g_CvarCTRandomSkins;
char g_cWardenSkin[PLATFORM_MAX_PATH], g_cWardenZamSkin[PLATFORM_MAX_PATH];

ArrayList tModels_Array, ctModels_Array;

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
	g_CvarTRandomSkins = CreateConVar("jwp_random_t_skins", "1", "Включить автоматическую установку скинов для Т. Требуется файл t_models.txt", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_CvarCTRandomSkins = CreateConVar("jwp_random_ct_skins", "1", "Включить автоматическую установку скинов для CТ. Требуется файл ct_models.txt", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_CvarWardenSkin.AddChangeHook(OnCvarChange);
	g_CvarWardenZamSkin.AddChangeHook(OnCvarChange);
	g_CvarTRandomSkins.AddChangeHook(OnCvarChange);
	g_CvarCTRandomSkins.AddChangeHook(OnCvarChange);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	AutoExecConfig(true, "skin", "jwp");
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (CheckClient(client))
	{
		int team = GetClientTeam(client);
		if (!TiB_SetSkin(client, team))
			return Plugin_Continue;
	}
	
	return Plugin_Continue;
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
	else if (cvar == g_CvarTRandomSkins) g_CvarTRandomSkins.SetInt(StringToInt(newValue));
	else if (cvar == g_CvarCTRandomSkins) g_CvarCTRandomSkins.SetInt(StringToInt(newValue));
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
	if (g_CvarTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/t_models.txt", tModels_Array);
	if (g_CvarCTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/ct_models.txt", ctModels_Array);
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

public int JWP_OnWardenResigned(int client, bool himself)
{
	if (CheckClient(client))
	{
		int team = GetClientTeam(client);
		
		if (!TiB_SetSkin(client, team))
			SetEntityModel(client, "models/player/ct_sas.mdl");
	}
}

void LoadSkinsFromFile(char[] path, ArrayList myArray)
{
	if (myArray != null)
	{
		myArray.Clear();
		myArray = null;
	}
	myArray = new ArrayList(PLATFORM_MAX_PATH, 0);
	Handle hFile = OpenFile(path, "r");
	if (hFile != null)
	{
		char model[PLATFORM_MAX_PATH];
		while (!IsEndOfFile(hFile) && ReadFileLine(hFile, model, sizeof(model)))
		{
			if (TrimString(model) > 7 && StrContains(model, "models", true) && StrContains(model, ".mdl", true))
			{
				if (FileExists(model, false))
				{
					PrecacheModel(model, true);
					myArray.PushString(model);
				}
				else
					LogError("[JWP|Skins] Model path %s does not exists.", model);
			}
		}
	}
	else
		LogError("[JWP|Skins] Unable to load config file %s", path);
	delete hFile;
	return;
}

bool TiB_SetSkin(int client, int team)
{
	if (team == CS_TEAM_T && g_CvarTRandomSkins.BoolValue)
		return GetRandomSkin(client, tModels_Array);
	else if (team == CS_TEAM_CT && g_CvarCTRandomSkins.BoolValue)
		return GetRandomSkin(client, ctModels_Array);
	return false;
}

bool GetRandomSkin(int client, ArrayList myArray)
{
	if (!myArray.Length || myArray == null)
		return false;
	char model[PLATFORM_MAX_PATH];
	int randomid = GetRandomInt(0, myArray.Length-1);
	if (myArray.GetString(randomid, model, sizeof(model)) && model[0] == 'm')
	{
		SetEntityModel(client, model);
		return true;
	}
	return false;
}

bool CheckClient(int client)
{
	return (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client));
}