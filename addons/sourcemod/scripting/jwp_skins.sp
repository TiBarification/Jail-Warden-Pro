#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>
#undef REQUIRE_PLUGIN
#tryinclude <n_arms_fix>
#tryinclude <vip_core>
#tryinclude <shop>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define PLUGIN_VERSION "1.7.3"

ConVar g_CvarWardenSkin, g_CvarWardenArms, g_CvarWardenZamSkin, g_CvarWardenZamArms, g_CvarTRandomSkins, g_CvarCTRandomSkins, g_CvarTimerSetSkin;
char g_cWardenSkin[2][PLATFORM_MAX_PATH], g_cWardenZamSkin[2][PLATFORM_MAX_PATH];
char g_cSkin[MAXPLAYERS+1][PLATFORM_MAX_PATH], g_cArms[MAXPLAYERS+1][PLATFORM_MAX_PATH];
int g_iSkinId[MAXPLAYERS+1];

ArrayList tModels_Array, ctModels_Array;
KeyValues g_KvT, g_KvCT;

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
	g_CvarTimerSetSkin = CreateConVar("jwp_timer_setskin", "0.5", "The timer time to install the skins", _, true, 0.5, true, 5.0);
	g_CvarWardenSkin = CreateConVar("jwp_warden_skin", "", "Set warden player model, leave empty to disable");
	g_CvarWardenArms = CreateConVar("jwp_warden_arms", "", "Set warden arms model (ONLY in CS:GO), leave empty to disable");
	g_CvarWardenZamSkin = CreateConVar("jwp_warden_zam_skin", "", "Set deputy player model (zam of warden), leave empty to disable");
	g_CvarWardenZamArms = CreateConVar("jwp_warden_zam_arms", "", "Set deputy arms model (ONLY in CS:GO), leave empty to disable");
	g_CvarTRandomSkins = CreateConVar("jwp_random_t_skins", "1", "Enable auto player model set for T team. Needed file t_models.txt", _, true, 0.0, true, 1.0);
	g_CvarCTRandomSkins = CreateConVar("jwp_random_ct_skins", "1", "Enable auto player model set for CT team. Needed file ct_models.txt", _, true, 0.0, true, 1.0);
	
	RegServerCmd("sm_jwp_skin_reload", Command_SkinReload, "Reload skins on server");
	
	g_bIsCSGO = (GetEngineVersion() == Engine_CSGO);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	AutoExecConfig(true, "skin", "jwp");
}

public void OnAllPluginsLoaded()
{
	g_bVIPExists = LibraryExists("vip_core");
	g_bShopExists = LibraryExists("shop");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("ArmsFix_SetDefaults");
	MarkNativeAsOptional("ArmsFix_HasDefaultArms");
	MarkNativeAsOptional("ArmsFix_SetDefaultArms");
	MarkNativeAsOptional("ArmsFix_RefreshView");
	MarkNativeAsOptional("VIP_IsValidFeature");
	MarkNativeAsOptional("VIP_GetClientFeatureStatus");
	MarkNativeAsOptional("Shop_GetItemCategoryId");
	MarkNativeAsOptional("Shop_CreateArrayOfItems");
	MarkNativeAsOptional("Shop_GetCategoryId");
	MarkNativeAsOptional("Shop_GetArrayItem");
	MarkNativeAsOptional("Shop_IsClientItemToggled");

	if (g_bIsCSGO && !LibraryExists("n_arms_fix"))
		SetFailState("Failed to run plugin, due to requirements. Check if n_arms_fix lib is installed");
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (CheckClient(client))
	{
		TiB_SetSkin(client);
		if (g_bIsCSGO)
		{
			ArmsFix_SetDefaults(client);
			SetArms(client, false);
		}
		CreateTimer(g_CvarTimerSetSkin.FloatValue, SetModel, client);
	}
	
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	g_cSkin[client][0] = NULL_STRING[0];
	g_cArms[client][0] = NULL_STRING[0];
	g_iSkinId[client] = 0;
}

public void OnConfigsExecuted()
{
	g_CvarWardenSkin.GetString(g_cWardenSkin[0], PLATFORM_MAX_PATH);
	g_CvarWardenZamSkin.GetString(g_cWardenZamSkin[0], PLATFORM_MAX_PATH);
	if (g_bIsCSGO)
	{
		g_CvarWardenArms.GetString(g_cWardenSkin[1], PLATFORM_MAX_PATH);
		g_CvarWardenZamArms.GetString(g_cWardenZamSkin[1], PLATFORM_MAX_PATH);
	}
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
	{
		CheckMdlPath(g_cWardenSkin[1]); // Precache warden arms
		CheckMdlPath(g_cWardenZamSkin[1]); // Precache zam warden arms
		PrecacheModel("models/player/ctm_sas.mdl", true);
	}
	else
		PrecacheModel("models/player/ct_sas.mdl", true);
	// Other models
	CheckMdlPath(g_cWardenSkin[0]); // Precache warden skin
	CheckMdlPath(g_cWardenZamSkin[0]); // Precache zam warden skin
	
	if (g_CvarTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/skin/t_models.txt", tModels_Array, g_KvT);
	if (g_CvarCTRandomSkins.BoolValue)
		LoadSkinsFromFile("cfg/jwp/skin/ct_models.txt", ctModels_Array, g_KvCT);
}

// Runs after default arms and model has been setted
public void JWP_OnWardenChosen(int client)
{
	// First setup arms
	if (g_bIsCSGO && g_cWardenSkin[1][0] != NULL_STRING[0])
		SetEntPropString(client, Prop_Send, "m_szArmsModel", g_cWardenSkin[1]);
	
	// Then setup model
	if (g_cWardenSkin[0][0] != NULL_STRING[0])
		SetEntityModel(client, g_cWardenSkin[0]);
	
	// And then refresh view
	if (g_bIsCSGO)
		ArmsFix_RefreshView(client);
}

public void JWP_OnWardenZamChosen(int client)
{
	// First setup arms
	if (g_bIsCSGO && g_cWardenZamSkin[1][0] != NULL_STRING[0])
		SetEntPropString(client, Prop_Send, "m_szArmsModel", g_cWardenZamSkin[1]);	
	
	// Then setup model
	if (g_cWardenZamSkin[0][0] != NULL_STRING[0])
		SetEntityModel(client, g_cWardenZamSkin[0]);
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	OnResign(client);
}

public void JWP_OnWardenZamResigned(int client)
{
	OnResign(client);
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

bool TiB_SetSkin(int client)
{
	int team = GetClientTeam(client);
	if (team >= 2)
	{
		if (team == CS_TEAM_T && g_CvarTRandomSkins.BoolValue)
			return SetRandomSkin(client, tModels_Array, g_KvT);
		else if (team == CS_TEAM_CT && g_CvarCTRandomSkins.BoolValue)
			return SetRandomSkin(client, ctModels_Array, g_KvCT);
	}
	return false;
}

bool SetRandomSkin(int client, ArrayList& myArray, KeyValues& kv)
{
	if (myArray == null || !myArray.Length)
		return false;
	kv.Rewind();
	
	int randomid = GetRandomInt(0, myArray.Length-1);
	int sec_id = myArray.Get(randomid);
	if (!kv.JumpToKeySymbol(sec_id))
	{
		LogError("[JWP|Skins] Failed to find section number %d", sec_id);
		return false;
	}
	
	kv.GetString("path", g_cSkin[client], PLATFORM_MAX_PATH, "");
	kv.GetString("arms_path", g_cArms[client], PLATFORM_MAX_PATH, "");
	
	g_iSkinId[client] = kv.GetNum("skin", 0);
	
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
	if (!g_CvarTRandomSkins.BoolValue && !g_CvarCTRandomSkins.BoolValue)
		return Plugin_Continue;
	// Skip VIP or shop player skin set
	if ((g_bVIPExists && IsVipSkinUse(client)) || (g_bShopExists && Shop_IsClientSkinUse(client)))
		return Plugin_Continue;
	// Skip warden skin set
	if ((JWP_IsWarden(client) && g_cWardenSkin[0][0] != NULL_STRING[0]) || (JWP_IsZamWarden(client) && g_cWardenZamSkin[0][0] != NULL_STRING[0]))
		return Plugin_Continue;
	
	SetActualModel(client);
	
	return Plugin_Continue;
}

void SetActualModel(int client)
{
	if (g_cSkin[client][0] != NULL_STRING[0])
	{
		SetEntityModel(client, g_cSkin[client]);
		if (g_iSkinId[client] != 0)
			SetEntProp(client, Prop_Send, "m_nSkin", g_iSkinId[client]);
	}
}

bool SetArms(int client, bool forceset)
{
	if (!g_bIsCSGO) return false;
	if (!g_CvarTRandomSkins.BoolValue && !g_CvarCTRandomSkins.BoolValue) return false; // Disable it , if no random skins
	else if ((g_bShopExists && Shop_IsClientSkinUse(client) && !forceset) || (g_bVIPExists && IsVipSkinUse(client)))
		return true;
	else if (g_bIsCSGO && g_cArms[client][0] != NULL_STRING[0])
	{
		char currentmodel[PLATFORM_MAX_PATH];
		GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, sizeof(currentmodel));

		if (!StrEqual(currentmodel, g_cArms[client]))
			SetEntPropString(client, Prop_Send, "m_szArmsModel", g_cArms[client]);
		return true;
	}
	
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
	if (CheckClient(client))
	{
		if (SetArms(client, true))
		{
			SetActualModel(client);
				
			// And then refresh view
			if (g_bIsCSGO)
				ArmsFix_RefreshView(client);
		}
		else
		{
			if (g_bIsCSGO)
				ArmsFix_SetDefaults(client);
			else
				SetEntityModel(client, "models/player/ct_sas.mdl");
		}
	}
}