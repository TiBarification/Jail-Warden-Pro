#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"

ConVar g_CvarWardenSkin, g_CvarWardenZamSkin, g_CvarTRandomSkins, g_CvarCTRandomSkins;
char g_cWardenSkin[PLATFORM_MAX_PATH], g_cWardenZamSkin[PLATFORM_MAX_PATH];

ArrayList tModels_Array, ctModels_Array;
KeyValues g_KvT, g_KvCT;

public Plugin myinfo = 
{
	name = "[JWP] Skin",
	description = "Sets skin for warden and zam",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarWardenSkin = CreateConVar("jwp_warden_skin", "", "Устанавливает скин командиру, оставьте пустым чтобы не использовать");
	g_CvarWardenZamSkin = CreateConVar("jwp_warden_zam_skin", "", "Устанавливает скин заместителю командира, оставьте пустым чтобы не использовать");
	g_CvarTRandomSkins = CreateConVar("jwp_random_t_skins", "1", "Включить автоматическую установку скинов для Т. Требуется файл t_models.txt", _, true, 0.0, true, 1.0);
	g_CvarCTRandomSkins = CreateConVar("jwp_random_ct_skins", "1", "Включить автоматическую установку скинов для CТ. Требуется файл ct_models.txt", _, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	AutoExecConfig(true, "skin", "jwp");
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (CheckClient(client))
	{
		int team = GetClientTeam(client);
		TiB_SetSkin(client, team)
	}
	
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	g_CvarWardenSkin.GetString(g_cWardenSkin, sizeof(g_cWardenSkin));
	g_CvarWardenZamSkin.GetString(g_cWardenZamSkin, sizeof(g_cWardenZamSkin));
}

public void OnMapStart()
{
	// Standart model for default
	if (GetEngineVersion() == Engine_CSGO)
		PrecacheModel("models/player/ctm_sas.mdl", true);
	else
		PrecacheModel("models/player/ct_sas.mdl", true);
	// Other models
	CheckMdlPath(g_cWardenSkin); // Precache warden skin
	CheckMdlPath(g_cWardenZamSkin); // Precache zam warden skin
	if (g_CvarTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/skin/t_models.txt", tModels_Array, g_KvT);
	if (g_CvarCTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/skin/ct_models.txt", ctModels_Array, g_KvCT);
}

public void JWP_OnWardenChosen(int client)
{
	if (g_cWardenSkin[0] == 'm')
		SetEntityModel(client, g_cWardenSkin);
}

public void JWP_OnWardenZamChosen(int client)
{
	if (g_cWardenZamSkin[0] == 'm')
		SetEntityModel(client, g_cWardenZamSkin);
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	if (CheckClient(client))
	{
		int team = GetClientTeam(client);
		
		if (!TiB_SetSkin(client, team))
		{
			if (GetEngineVersion() == Engine_CSGO)
				SetEntityModel(client, "models/player/ctm_sas.mdl");
			else
				SetEntityModel(client, "models/player/ct_sas.mdl");
		}
	}
}

void LoadSkinsFromFile(char[] path, ArrayList& myArray, KeyValues& kv)
{
	if (kv != null) delete kv;
	kv = new KeyValues("Models");
	if (kv.ImportFromFile(path))
	{
		if (myArray != null)
		{
			myArray.Clear();
			myArray = null;
		}
		char model[PLATFORM_MAX_PATH];
		myArray = new ArrayList(1);
		int sec_id;
		
		if (kv.GotoFirstSubKey(true))
		{
			do
			{
				if (kv.GetSectionSymbol(sec_id))
				{
					kv.GetString("path", model, sizeof(model), "");
					if (CheckMdlPath(model))
					{
						myArray.Push(sec_id);
						kv.GetString("arms_path", model, sizeof(model), "");
						CheckMdlPath(model);
					}
					else
						LogError("[JWP|Skins] Failed to find model path '%s'", model);
				}
			} while (kv.GotoNextKey(true));
		}
		kv.Rewind();
	}
	else
		SetFailState("[JWP|Skins] Unable to load config file %s", path);
}

bool TiB_SetSkin(int client, int team)
{
	if (team == CS_TEAM_T && g_CvarTRandomSkins.BoolValue)
		return SetRandomSkin(client, tModels_Array, g_KvT);
	else if (team == CS_TEAM_CT && g_CvarCTRandomSkins.BoolValue)
		return SetRandomSkin(client, ctModels_Array, g_KvCT);
	return false;
}

bool SetRandomSkin(int client, ArrayList& myArray, KeyValues& kv)
{
	if (myArray == null || !myArray.Length)
		return false;
	kv.Rewind();
	
	char model[PLATFORM_MAX_PATH];
	int randomid = GetRandomInt(0, myArray.Length-1);
	int sec_id = myArray.Get(randomid);
	if (!kv.JumpToKeySymbol(sec_id))
	{
		LogError("[JWP|Skins] Failed to find section number %d", sec_id);
		return false;
	}
	kv.GetString("path", model, sizeof(model), "");
	SetEntityModel(client, model);
	// PrintToChat(client, "Your new player skin: %s", model);
	
	kv.GetString("arms_path", model, sizeof(model), "");
	if (model[0] == 'm')
		SetEntPropString(client, Prop_Send, "m_szArmsModel", model);
	
	int skin_id = kv.GetNum("skin", 0);
	if (skin_id != 0)
		SetEntProp(client, Prop_Send, "m_nSkin", skin_id); 
	return true;
}

bool CheckClient(int client)
{
	return (client && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client));
}

bool CheckMdlPath(const char[] path)
{
	if (path[0] != 'm' || StrContains(path, ".mdl", false) == -1)
		return false;
	if(strlen(path) > 3 && FileExists(path) && !IsModelPrecached(path)) PrecacheModel(path, true);
	return true;
}