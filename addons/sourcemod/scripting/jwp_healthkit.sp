#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <jwp>
#include <emitsoundany>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.2"
#define ITEM "healthkit"

ConVar g_CvarHK_Limit, g_CvarHK_Wait, g_CvarHK_Life, g_CvarHK_Team, g_CvarHK_Hp, g_CvarHK_LimitHp, g_CvarHK_Model;

int g_iHKits[MAXPLAYERS+1];
char g_cHKModel[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "[JWP] Health Kit",
	description = "Warden can drop health kit",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarHK_Limit = CreateConVar("jwp_healthkit_limit", "3", "Сколько аптечек может создать командир. 0 - без ограничений", _, true, 0.0);
	g_CvarHK_Wait = CreateConVar("jwp_healthkit_wait", "3", "Аптечку можно создавать 1 раз в 'x' сек", _, true, 0.0);
	g_CvarHK_Life = CreateConVar("jwp_healthkit_life", "9", "Если аптечку не подняли, удалить ее через 'x' сек (0 = не удалять)", _, true, 0.0);
	g_CvarHK_Team = CreateConVar("jwp_healthkit_team", "1", "Кому аптечка добавляет HP: 1 = Всем; 2 = T; 3 = CT", _, true, 1.0, true, 3.0);
	g_CvarHK_LimitHp = CreateConVar("jwp_healthkit_limit_hp", "100", "Лимит HP (аптечка). 0 = без лимита.", _, true, 0.0);
	g_CvarHK_Hp = CreateConVar("jwp_healthkit_hp", "50", "Сколько HP добавляет аптечка", _, true, 1.0);
	g_CvarHK_Model = CreateConVar("jwp_healthkit_model", "models/gibs/hgibs.mdl", "Модель аптечки", _);
	
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	if (JWP_IsStarted()) JWP_Started();
	
	AutoExecConfig(true, ITEM, "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void OnMapStart()
{
	g_CvarHK_Model.GetString(g_cHKModel, sizeof(g_cHKModel));
	PrecacheModel(g_cHKModel, true);
	PrecacheSoundAny("sound/ambient/machines/zap2.wav");
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
		g_iHKits[i] = 0;
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	if (g_CvarHK_Limit.IntValue)
	{
		Format(buffer, maxlength, "%T (%d/%d)", "HealthKit_Menu", LANG_SERVER, g_iHKits[client], g_CvarHK_Limit.IntValue);	
		if (g_iHKits[client] < g_CvarHK_Limit.IntValue) style = ITEMDRAW_DEFAULT;
		else style = ITEMDRAW_DISABLED;
	}
	else
		Format(buffer, maxlength, "%T", "HealthKit_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (TrySpawnHealthKit(client))
	{
		if (g_CvarHK_Limit.IntValue)
		{
			char buffer[64];
			Format(buffer, sizeof(buffer), "%T (%d/%d)", "HealthKit_Menu", LANG_SERVER, g_iHKits[client], g_CvarHK_Limit.IntValue);
			JWP_RefreshMenuItem(ITEM, buffer, (g_iHKits[client] < g_CvarHK_Limit.IntValue) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
	}
	else
		JWP_ActionMsg(client, "%T", "HealthKit_FailedToMedkit", LANG_SERVER);
	JWP_ShowMainMenu(client);
	return true;
}

bool TrySpawnHealthKit(int client)
{
	if (g_CvarHK_Wait.IntValue > 0 && JWP_IsFlood(client, g_CvarHK_Wait.IntValue))
	{
		JWP_ActionMsg(client, "%T", "HealthKit_StopFlood", LANG_SERVER);
		return false;
	}
	
	float origin[3];
	int entity = GetAimInfo(client, origin);
	if (!IsValidEntity(entity) || (0 < entity <= MaxClients))
	{
		PrintCenterText(client, "%T", "HealthKit_RemoveAim", LANG_SERVER);
		return false;
	}
	
	int kit_ent = CreateEntityByName("prop_dynamic_override");
	if (!IsValidEdict(kit_ent))
	{
		LogError("Could not create entity 'prop_dynamic_override'");
		return false;
	}
	
	DispatchKeyValue(kit_ent, "physdamagescale", "0.0");
	DispatchKeyValue(kit_ent, "solid", "6");
	origin[2] += 5.0;
	
	DispatchKeyValueVector(kit_ent, "origin", origin);
	char kitname[36];
	Format(kitname, sizeof(kitname), "kit_%d", kit_ent);
	DispatchKeyValue(kit_ent, "targetname", kitname);
	SetEntityModel(kit_ent, g_cHKModel);
	DispatchSpawn(kit_ent);
	SetEntityMoveType(kit_ent, MOVETYPE_VPHYSICS);
	SDKHook(kit_ent, SDKHook_StartTouchPost, OnKitTouch);
	
	if (g_CvarHK_Life.IntValue && IsValidEdict(kit_ent))
	{
		char info[24];
		Format(info, sizeof(info), "OnUser1 !self:kill::%f:1", g_CvarHK_Life.FloatValue);
		SetVariantString(info);
		AcceptEntityInput(kit_ent, "AddOutput");
		AcceptEntityInput(kit_ent, "FireUser1"); 
	}
	
	int ent = CreateEntityByName("env_sprite");
	if (IsValidEdict(ent))
	{
		DispatchKeyValueVector(ent, "origin", origin);
		DispatchKeyValue(ent, "model", "sprites/glow01.spr");
		DispatchKeyValue(ent, "rendermode", "5");
		DispatchKeyValue(ent, "renderfx", "16");
		DispatchKeyValue(ent, "scale", "1");
		DispatchKeyValue(ent, "renderamt", "255");
		DispatchKeyValue(ent, "rendercolor", "0 255 0");
		DispatchSpawn(ent);
		SetVariantString(kitname);
		AcceptEntityInput(ent, "SetParent");
		AcceptEntityInput(ent, "ShowSprite");
	}
	
	TE_SetupSparks(origin, origin, 2, 1);
	TE_SendToAll();
	EmitAmbientSound("ambient/machines/zap2.wav", origin);
	
	g_iHKits[client]++;
	return true;
}

public void OnKitTouch(int entity, int other)
{
	if (other < 1 || other > MaxClients || !IsClientInGame(other) || !IsPlayerAlive(other))
		return;
	// Check client team
	if (g_CvarHK_Team.IntValue != 1 && g_CvarHK_Team.IntValue != GetClientTeam(other)) return;
	// Check max health
	int hp = GetClientHealth(other);
	if (g_CvarHK_LimitHp.IntValue && hp >= g_CvarHK_LimitHp.IntValue) return;
	AcceptEntityInput(entity, "Kill");
	
	// Set new health
	hp += g_CvarHK_Hp.IntValue;
	if (g_CvarHK_LimitHp.IntValue && hp > g_CvarHK_LimitHp.IntValue)
		hp = g_CvarHK_LimitHp.IntValue;
	SetEntityHealth(other, hp);
}

int GetAimInfo(int client, float end_origin[3])
{
	float origin[3], angles[3];
	
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	
	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, client);
	if (TR_DidHit())
	{
		TR_GetEndPosition(end_origin);
		return TR_GetEntityIndex();
	}
	return -1;
}

public bool TraceFilter_Callback(int ent, int mask, any something)
{
	return something != ent;
}