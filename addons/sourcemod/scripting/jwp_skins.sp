#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>
#undef REQUIRE_PLUGIN
#tryinclude <vip_core>
#tryinclude <shop>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define PLUGIN_VERSION "1.7.5"

ConVar g_CvarEnable, g_CvarWardenSkin, g_CvarWardenZamSkin, g_CvarTRandomSkins, g_CvarCTRandomSkins, g_CvarTimerSetSkin;
char g_cWardenSkin[PLATFORM_MAX_PATH], g_cWardenZamSkin[PLATFORM_MAX_PATH];
char g_cSkin[MAXPLAYERS+1][PLATFORM_MAX_PATH];
int g_iSkinId[MAXPLAYERS+1];

ArrayList g_hArrayModels[2];
KeyValues g_hKvModels[2];

bool g_bIsCSGO, g_bVIPExists, g_bShopExists;
char g_cVIPFeatureName[] = "Skins";

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
	g_CvarEnable = CreateConVar("jwp_skins_enable", "1", "Enable or disable plugin work", _, true, 0.0, true, 1.0);
	g_CvarTimerSetSkin = CreateConVar("jwp_timer_setskin", "0.5", "The timer time to install the skins", _, true, 0.5, true, 5.0);
	g_CvarWardenSkin = CreateConVar("jwp_warden_skin", "", "Set warden player model, leave empty to disable");
	g_CvarWardenZamSkin = CreateConVar("jwp_warden_zam_skin", "", "Set deputy player model (zam of warden), leave empty to disable");
	g_CvarTRandomSkins = CreateConVar("jwp_random_t_skins", "0", "Enable auto player model set for T team. Needed file t_models.txt", _, true, 0.0, true, 1.0);
	g_CvarCTRandomSkins = CreateConVar("jwp_random_ct_skins", "0", "Enable auto player model set for CT team. Needed file ct_models.txt", _, true, 0.0, true, 1.0);
	
	RegServerCmd("sm_jwp_skin_reload", Command_SkinReload, "Reload skins on server");
	
	g_bIsCSGO = (GetEngineVersion() == Engine_CSGO);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	AutoExecConfig(true, "skin", "jwp");
}

public void OnAllPluginsLoaded()
{
	g_bVIPExists = (GetFeatureStatus(FeatureType_Native, "VIP_IsVIPLoaded") == FeatureStatus_Available);
	g_bShopExists = (GetFeatureStatus(FeatureType_Native, "Shop_IsStarted") == FeatureStatus_Available);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("VIP_IsValidFeature");
	MarkNativeAsOptional("VIP_GetClientFeatureStatus");
	MarkNativeAsOptional("Shop_GetItemCategoryId");
	MarkNativeAsOptional("Shop_CreateArrayOfItems");
	MarkNativeAsOptional("Shop_GetCategoryId");
	MarkNativeAsOptional("Shop_GetArrayItem");
	MarkNativeAsOptional("Shop_IsClientItemToggled");
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_CvarEnable.BoolValue)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (CheckClient(client))
		{
			TiB_SetSkin(client);
			CreateTimer(g_CvarTimerSetSkin.FloatValue, SetModel, client);
		}
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	g_cSkin[client][0] = NULL_STRING[0];
	g_iSkinId[client] = 0;
}

public void OnConfigsExecuted()
{
	g_CvarWardenSkin.GetString(g_cWardenSkin, PLATFORM_MAX_PATH);
	g_CvarWardenZamSkin.GetString(g_cWardenZamSkin, PLATFORM_MAX_PATH);
}

public Action Command_SkinReload(int args)
{
	if (!args)
	{
		OnMapStart();
		PrintToServer("[JWP-Skins] Module all skin configs succesfully reloaded.");
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	// Standart model for default
	if (g_bIsCSGO)
		PrecacheModel("models/player/ctm_sas.mdl", true);
	else
		PrecacheModel("models/player/ct_sas.mdl", true);
	// Other models
	CheckMdlPath(g_cWardenSkin); // Precache warden skin
	CheckMdlPath(g_cWardenZamSkin); // Precache zam warden skin
	
	if (g_CvarTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/skin/t_models.txt", 0);
	if (g_CvarCTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/skin/ct_models.txt", 1);
}

// Runs after default arms and model has been setted
public void JWP_OnWardenChosen(int client)
{
	if (!g_CvarEnable.BoolValue) return;
	
	// Setup model
	if (g_cWardenSkin[0] != NULL_STRING[0])
		SetEntityModel(client, g_cWardenSkin);
}

public void JWP_OnWardenZamChosen(int client)
{
	if (!g_CvarEnable.BoolValue) return;
	
	// Setup model
	if (g_cWardenZamSkin[0] != NULL_STRING[0])
		SetEntityModel(client, g_cWardenZamSkin);
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	OnResign(client);
}

public void JWP_OnWardenZamResigned(int client)
{
	OnResign(client);
}

void LoadSkinsFromFile(char[] path, int index)
{
	if (g_hArrayModels[index] != null)
	{
		delete g_hArrayModels[index];
		g_hArrayModels[index] = null;
	}

	if (g_hKvModels[index] != null)
	{
		delete g_hKvModels[index];
	}

	g_hKvModels[index] = new KeyValues("Models");
	if (g_hKvModels[index].ImportFromFile(path))
	{
		char model[PLATFORM_MAX_PATH];
		g_hArrayModels[index] = new ArrayList(1);
		int sec_id;
		if (g_hKvModels[index].GotoFirstSubKey(true))
		{
			do
			{
				if (g_hKvModels[index].GetSectionSymbol(sec_id))
				{
					g_hKvModels[index].GetString("path", model, sizeof(model), "");
					if (CheckMdlPath(model))
						g_hArrayModels[index].Push(sec_id);
					else
						LogError("[JWP|Skins] Failed to find model path '%s'", model);
				}
			} while (g_hKvModels[index].GotoNextKey(true));
		}
		g_hKvModels[index].Rewind();
	}
	else
		SetFailState("[JWP|Skins] Unable to load config file %s", path);
}

bool TiB_SetSkin(int client)
{
	int team = GetClientTeam(client);
	if (team >= 2)
	{
		if (team == CS_TEAM_T && g_CvarTRandomSkins.BoolValue)
			return SetRandomSkin(client, 0);
		else if (team == CS_TEAM_CT && g_CvarCTRandomSkins.BoolValue)
			return SetRandomSkin(client, 1);
	}
	return false;
}

bool SetRandomSkin(int client, int index)
{
	if (!g_hArrayModels[index] || !g_hArrayModels[index].Length)
		return false;

	int randomid = GetRandomInt(0, g_hArrayModels[index].Length-1);
	int sec_id = g_hArrayModels[index].Get(randomid);
	g_hKvModels[index].Rewind();
	if (!g_hKvModels[index].JumpToKeySymbol(sec_id))
	{
		LogError("[JWP|Skins] Failed to find section number %d", sec_id);
		return false;
	}
	
	g_hKvModels[index].GetString("path", g_cSkin[client], PLATFORM_MAX_PATH, "");
	g_iSkinId[client] = g_hKvModels[index].GetNum("skin", 0);
	
	return true;
}

bool Shop_IsClientSkinUse(int iClient)
{
	if (IsFakeClient(iClient))
		return false;
	int iSize = 0;
	ArrayList hArray = view_as<ArrayList>(Shop_CreateArrayOfItems(iSize));
	if(iSize)
	{
		CategoryId iCatID = Shop_GetCategoryId("skins");
		ItemId item_id;
		for(int i = 0; i < iSize; ++i)
		{
			item_id = view_as<ItemId>(Shop_GetArrayItem(hArray, i));
			if(Shop_GetItemCategoryId(item_id) == iCatID && Shop_IsClientItemToggled(iClient, item_id))
			{
				delete hArray;
				return true;
			}
		}
	}

	delete hArray;
	return false;
}

bool IsVipSkinUse(int iClient)
{
	return (IsClientConnected(iClient) && VIP_IsClientVIP(iClient) && VIP_GetClientFeatureStatus(iClient, g_cVIPFeatureName) == ENABLED);
}

public Action SetModel(Handle timer, int client)
{
	// Exit if no random skins found
	if (!g_CvarEnable.BoolValue || (!g_CvarTRandomSkins.BoolValue && !g_CvarCTRandomSkins.BoolValue))
		return Plugin_Continue;
	// Skip VIP or shop player skin set
	if ((g_bVIPExists && IsVipSkinUse(client)) || (g_bShopExists && Shop_IsClientSkinUse(client)))
		return Plugin_Continue;
	// Skip warden skin set
	if ((JWP_IsWarden(client) && g_cWardenSkin[0] != NULL_STRING[0]) || (JWP_IsZamWarden(client) && g_cWardenZamSkin[0] != NULL_STRING[0]))
		return Plugin_Continue;
	
	SetActualModel(client);
	return Plugin_Continue;
}

bool SetActualModel(int client)
{
	if (g_cSkin[client][0] != NULL_STRING[0])
	{
		SetEntityModel(client, g_cSkin[client]);
		if (g_iSkinId[client] != 0)
			SetEntProp(client, Prop_Send, "m_nSkin", g_iSkinId[client]);
		return true;
	}
	else
		return false;
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

void OnResign(int client)
{
	if (!g_CvarEnable.BoolValue) return;
	if (CheckClient(client))
	{
		if (!SetActualModel(client))
		{
			if (g_bIsCSGO)
				SetEntityModel(client, "models/player/ctm_sas.mdl");
			else
				SetEntityModel(client, "models/player/ct_sas.mdl");
		}
	}
}