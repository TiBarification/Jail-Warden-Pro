#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>
#include <emitsoundany>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "isolator"

int g_iIsolatorIndex[MAXPLAYERS+1], g_iIsolatorBeamIndex[MAXPLAYERS+1];

ConVar	g_CvarIsolatorWall, g_CvarIsolatorWall_Dist,
		g_CvarIsolatorRoof, g_CvarIsolatorRoof_Dist,
		g_CvarIsolator_Sound;

char g_cIsolatorWall[PLATFORM_MAX_PATH], g_cIsolatorRoof[PLATFORM_MAX_PATH], g_cIsolatorSound[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "[JWP] Isolator",
	description = "Warden can push terrorists to isolator",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarIsolatorWall = CreateConVar("jwp_isolator_wall", "models/props/de_train/chainlinkgate.mdl", "Модель стен карцера", FCVAR_PLUGIN);
	g_CvarIsolatorWall_Dist = CreateConVar("jwp_isolator_wall_dist", "80", "Расстояние от центра карцера до его боковых стен", FCVAR_PLUGIN, true, 15.0, true, 200.0);
	g_CvarIsolatorRoof = CreateConVar("jwp_isolator_roof", "", "Модель крыши карцера", FCVAR_PLUGIN);
	g_CvarIsolatorRoof_Dist = CreateConVar("jwp_isolator_roof_dist", "125", "Расстояние от пола карцера до его крыши", FCVAR_PLUGIN, true, 50.0, true, 500.0);
	g_CvarIsolator_Sound = CreateConVar("jwp_isolator_sound", "ambient/machines/power_transformer_loop_1.wav", "Звук в карцере. Оставьте пустым, чтобы отключить.", FCVAR_PLUGIN);
	
	g_CvarIsolatorWall.AddChangeHook(OnCvarChange);
	g_CvarIsolatorWall_Dist.AddChangeHook(OnCvarChange);
	g_CvarIsolatorRoof.AddChangeHook(OnCvarChange);
	g_CvarIsolatorRoof_Dist.AddChangeHook(OnCvarChange);
	g_CvarIsolator_Sound.AddChangeHook(OnCvarChange);
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	
	if (JWP_IsStarted()) JWC_Started();
	AutoExecConfig(true, ITEM, "jwp");
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	g_CvarIsolatorWall.GetString(buffer, sizeof(buffer));
	if (buffer[0] == 'm')
		PrecacheModel(buffer, true);
	g_CvarIsolatorRoof.GetString(buffer, sizeof(buffer));
	if (buffer[0] == 'm')
		PrecacheModel(buffer, true);
	g_CvarIsolator_Sound.GetString(buffer, sizeof(buffer));
	if (buffer[0] == 's')
		PrecacheSoundAny(buffer);
}

public int JWC_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnConfigsExecuted()
{
	g_CvarIsolatorWall.GetString(g_cIsolatorWall, sizeof(g_cIsolatorWall));
	g_CvarIsolatorRoof.GetString(g_cIsolatorRoof, sizeof(g_cIsolatorRoof));
	g_CvarIsolator_Sound.GetString(g_cIsolatorSound, sizeof(g_cIsolatorSound));
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarIsolatorWall)
	{
		g_CvarIsolatorWall.SetString(newValue);
		strcopy(g_cIsolatorWall, sizeof(g_cIsolatorWall), newValue);
	}
	else if (cvar == g_CvarIsolatorWall_Dist) g_CvarIsolatorWall_Dist.SetInt(StringToInt(newValue));
	else if (cvar == g_CvarIsolatorRoof)
	{
		g_CvarIsolatorRoof.SetString(newValue);
		strcopy(g_cIsolatorRoof, sizeof(g_cIsolatorRoof), newValue);
	}
	else if (cvar == g_CvarIsolatorRoof_Dist) g_CvarIsolatorRoof_Dist.SetInt(StringToInt(newValue));
	else if (cvar == g_CvarIsolator_Sound)
	{
		g_CvarIsolator_Sound.SetString(newValue);
		strcopy(g_cIsolatorSound, sizeof(g_cIsolatorSound), newValue);
	}
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
		JWP_PrisonerIsolated(i, false);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	JWP_PrisonerIsolated(client, false);
	TryKillIsolator(client);
}

public void Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	JWP_PrisonerIsolated(client, false);
	TryKillIsolator(client);
}

public void OnClientDisconnect_Post(int client)
{
	JWP_PrisonerIsolated(client, false);
	TryKillIsolator(client);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "Управление карцером"); // [|||] в карцере
	return true;
}

public bool OnFuncSelect(int client)
{
	Menu IsolatorMenu = new Menu(IsolatorMenu_Callback);
	IsolatorMenu.SetTitle("Управление карцером:\n[|||] - в карцере");
	char id[4], name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i)) // Change to CheckClient
		{
			IntToString(i, id, sizeof(id));
			if (JWP_IsPrisonerIsolated(i))
				Format(name, sizeof(name), "[|||]%N", i);
			else
				Format(name, sizeof(name), "%N", i);
			IsolatorMenu.AddItem(id, name);
		}
	}
	if (!IsolatorMenu.ItemCount)
		IsolatorMenu.AddItem("", "Нет живых зеков", ITEMDRAW_DISABLED);
	IsolatorMenu.ExitBackButton = true;
	IsolatorMenu.Display(client, MENU_TIME_FOREVER);
	return true;
}

public int IsolatorMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(slot, info, sizeof(info));
			
			int target = StringToInt(info, sizeof(info));
			if (target && IsClientInGame(target))
			{
				if (JWP_IsPrisonerIsolated(target))
				{
					TryKillIsolator(target);
					JWP_ActionMsgAll("%N освободил зека %N из карцера", client, target);
					JWP_PrisonerIsolated(target, false);
				}
				else if (TryPushPrisonerInIsolator(client, target))
				{
					JWP_ActionMsgAll("%N посадил зека %N в карцер", client, target);
					JWP_PrisonerIsolated(target, true);
				}
				else
					JWP_ActionMsg(client, "Не удалось посадить %N в карцер", target);
			}
			else
				JWP_ActionMsg(client, "Не удалось посадить игрока. Возможно он ливнул?");
			OnFuncSelect(client);
		}
	}
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T));
}

bool IsValidIsolator(int& ent, char[] name)
{
	if (ent <= MaxClients || !IsValidEntity(ent))
	{
		ent = 0;
		return false;
	}
	
	char cName[16];
	cName[0] = '\0';
	GetEntPropString(ent, Prop_Send, "m_iName", cName, sizeof(cName));
	if (StrContains(cName, name, true))
	{
		ent = 0;
		return false;
	}
	return true;
}


bool TryPushPrisonerInIsolator(int client, int prisoner)
{
	if (IsValidIsolator(g_iIsolatorIndex[prisoner], "isltr_")) return false;
	float center[3];
	int ent = TiB_GetAimInfo(client, center);
	if (ent > 0 && ent <= MaxClients)
	{
		PrintCenterText(client, "Рядом игрок, нельзя установить карцер");
		return false;
	}
	float angles[3];
	TR_GetPlaneNormal(null, angles);
	GetVectorAngles(angles, angles);
	angles[0] = 0.0;
	
	float pOrigin[3];
	float wall_dist = g_CvarIsolatorWall_Dist.FloatValue + 150;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (i != prisoner && IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, pOrigin);
			if (GetVectorDistance(pOrigin, center, false) <= wall_dist)
			{
				PrintCenterText(client, "Невозможно здесь установить карцер");
				return false;
			}
		}
	}
	wall_dist -= 150.0;
	float direction[3];
	
	int prisoner_id = GetClientUserId(prisoner);
	char IsoLatorName[28];
	
	/* First wall & test if we can teleport player not in wall */
	angles[1] = 0.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist, true);
	if (!ent)
	{
		PrintHintText(client, "Нельзя создать изолятор, выберите другое место.");
		return false;
	}
	
	Format(IsoLatorName, sizeof(IsoLatorName), "isltr_%d", prisoner_id);
	DispatchKeyValue(ent, "targetname", IsoLatorName);
	
	SetVariantString(IsoLatorName);
	AcceptEntityInput(ent, "SetParent");
	g_iIsolatorIndex[prisoner] = ent;
	
	/* Second wall */
	angles[1] = 90.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist);
	if (ent)
	{
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	/* Third wall */
	angles[1] = 180.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist);
	if (ent)
	{
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	/* Fourth wall */
	angles[1] = 270.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist);
	if (ent)
	{
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	
	/* Roof configuration */
	angles[2] += g_CvarIsolatorRoof_Dist.FloatValue;
	if ((ent = CreateProp(g_cIsolatorRoof)) > 0)
	{
		TeleportEntity(ent, center, NULL_VECTOR, NULL_VECTOR);
		SetEntityMoveType(ent, MOVETYPE_NONE);
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	
	/* Create Beam */
	/* Nothing else */
	/* End of creating beam */
	
	/* Create Sound */
	
	if (g_cIsolatorSound[0] && (ent = CreateEntityByName("ambient_generic")) > 0)
	{
		DispatchKeyValueVector(ent, "origin", center);
		DispatchKeyValue(ent, "message", g_cIsolatorSound);
		DispatchKeyValue(ent, "health", "10");
		DispatchKeyValue(ent, "radius", "2000");
		DispatchKeyValue(ent, "preset", "0");
		DispatchKeyValue(ent, "volstart", "10");
		DispatchSpawn(ent);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "PlaySound");
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	/* End of creating sound */
	
	/* Teleport prisoner if isolator succesfully builded */
	center[2] += 20.0;
	TeleportEntity(prisoner, center, NULL_VECTOR, NULL_VECTOR);
	
	return true;
}

stock int EditWallPositionAndCreateWall(float wall_pos[3], float angles[3], float newpos[3], float dist, bool firstwall = false)
{
	int ent = CreateProp(g_cIsolatorWall);
	if (IsValidEntity(ent))
	{
		if (firstwall)
		{
			wall_pos[2] += 20.0;
			TeleportEntity(ent, wall_pos, angles, NULL_VECTOR);
			if (IsEntStucked(ent)) return 0;
			wall_pos[2] -= 20.0;
		}
		float direction[3];
		GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
		newpos = wall_pos;
		newpos[0] += direction[0] * dist;
		newpos[1] += direction[1] * dist;
		newpos[2] += 6.0;
		TeleportEntity(ent, newpos, angles, NULL_VECTOR);
		SetEntityMoveType(ent, MOVETYPE_NONE);
	}
	
	return ent;
}

bool IsEntStucked(int ent)
{
	float vecMins[3], vecMaxs[3], vecOrigin[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
	GetEntPropVector(ent, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vecMaxs);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_SOLID, TREntityStuckFilter, ent);
	if (TR_GetEntityIndex() > MaxClients) return false;
	AcceptEntityInput(ent, "Kill");
	return true;
}

int CreateProp(char[] model)
{
	if (model[0] != 'm') return -1;
	int ent = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(ent))
	{
		DispatchKeyValue(ent, "model", model);
		DispatchKeyValue(ent, "Solid", "6");
		DispatchSpawn(ent);
	}
	return ent;
}

int TiB_GetAimInfo(int client, float end_origin[3])
{
	float angles[3];
	if (!GetClientEyeAngles(client, angles)) return -1;
	float origin[3];
	GetClientEyePosition(client, origin);
	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, client);
	
	if (!TR_DidHit())
		return -1;
	
	TR_GetEndPosition(end_origin);
	
	return TR_GetEntityIndex();
}

public bool TraceFilter_Callback(int ent, int mask, any entity)
{
	return entity != ent;
}

bool TryKillIsolator(int client)
{
	bool kill;
	if (IsValidIsolator(g_iIsolatorIndex[client], "isltr_"))
	{
		AcceptEntityInput(g_iIsolatorIndex[client], "KillHierarchy");
		kill = true;
	}
	if (IsValidIsolator(g_iIsolatorBeamIndex[client], "bm_"))
	{
		AcceptEntityInput(g_iIsolatorBeamIndex[client], "Kill");
		kill = true;
	}
	g_iIsolatorIndex[client] = 0;
	g_iIsolatorBeamIndex[client] = 0;
	return kill;
}

public bool TREntityStuckFilter(int ent, int mask)
{
	return (ent > MaxClients);
}