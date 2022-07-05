#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <jwp>
#include <csgo_colors>
#include <emitsoundany>
#undef REQUIRE_PLUGIN
#include <hosties>
#include <lastrequest>

#define ITEM "handcuffs"
#define PLUGIN_VERSION "1.6"

int g_iClipOffset, g_iActiveWeaponOffset;
bool g_bArrested[MAXPLAYERS+1];
char g_cOverlayPath[] = "overlays/MyJailbreak/cuffs";

public Plugin myinfo =
{
	name = "[JWP] Handcuffs",
	description = "Ability to arrest players",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru http://steamcommunity.com/id/doctor_white"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO) SetFailState("Plugin works only in CS:GO");
	
	g_iClipOffset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iActiveWeaponOffset = FindSendPropInfo("CCSPlayer", "m_hActiveWeapon");
	if (JWP_IsStarted()) JWP_Started();
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("weapon_fire", Event_OnWeaponFire);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
	LoadTranslations("jwp_modules.phrases");
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	Format(buffer, sizeof(buffer), "materials/%s.vtf", g_cOverlayPath);
	AddFileToDownloadsTable(buffer);
	Format(buffer, sizeof(buffer), "materials/%s.vmt", g_cOverlayPath);
	AddFileToDownloadsTable(buffer);
	PrecacheModel(buffer);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	UnArrestAll();
}

public Action Event_OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		char cWeapon[32];
		event.GetString("weapon", cWeapon, sizeof(cWeapon));
		if (StrEqual(cWeapon, "weapon_taser", false))
		{
			int weapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
			SetEntData(weapon, g_iClipOffset, 2, 4, true); // 2 ammo
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client && IsClientInGame(client))
	{
		g_bArrested[client] = false;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		ShowOverlayCuffs(client, true);
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (g_bArrested[client])
		g_bArrested[client] = false;
}

public void OnAvailableLR(int announced)
{
	UnArrestAll();
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
			GivePlayerItem(i, "weapon_knife");
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
	Format(buffer, maxlength, "%T", "Handcuffs_Menu", LANG_SERVER);
	return true;
}

public bool OnItemSelect(int client)
{
	UnArrestAll();
	JWP_ShowMainMenu(client);
	return true;
}

// Check mouse2 click
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (client && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		if (buttons & IN_ATTACK2)
		{
			char cWeapon[32];
			int currwpn = GetEntDataEnt2(client, g_iActiveWeaponOffset);
			if (IsValidEntity(currwpn))
			{
				GetEntityClassname(currwpn, cWeapon, sizeof(cWeapon));
				if (StrEqual(cWeapon, "weapon_taser", false))
				{
					int target = GetClientAimTarget(client, true);
					if (target > 0 && IsClientInGame(target) && GetClientTeam(target) == CS_TEAM_T && IsPlayerAlive(target) && g_bArrested[target])
					{
						if (!Client_IsLookingAtWall(client, Entity_GetDistance(client, target)+40.0))
						{
							float origin[3], location[3], ang[3], location2[3];
							GetClientAbsOrigin(client, origin);
							GetClientEyePosition(client, location);
							GetClientEyeAngles(client, ang);
							location2[0] = (location[0]+(100*((Cosine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
							location2[1] = (location[1]+(100*((Sine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));
							ang[0] -= (2*ang[0]);
							location2[2] = origin[2] += 5.0;
							origin[0] = 0.0;
							origin[1] = 0.0;
							origin[2] = 0.0;
							
							TeleportEntity(target, location2, ang, origin);
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	// Basic check for players
	if (victim > 0 && victim <= MaxClients && IsClientInGame(victim) && IsPlayerAlive(victim) && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && IsPlayerAlive(attacker))
	{
		// Restrict damage from attacker if he was cuffed
		if (g_bArrested[attacker])
			return Plugin_Handled;
		// Check for player teams and it was not suicide
		if (GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT && attacker != victim && IsValidEntity(weapon))
		{
			char cWeapon[32];
			GetEntityClassname(weapon, cWeapon, sizeof(cWeapon));
			// now we have weapon name in cWeapon, we gonna check it for taser
			// if not taser we skip damage
			if (!StrEqual(cWeapon, "weapon_taser", false)) return Plugin_Continue;
			
			if (g_bArrested[victim])
				FreeEm(victim, attacker);
			else
				CuffsEm(victim, attacker);
			
			// Restrict damage from taser if we handcuff or release victim
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void CuffsEm(int client, int attacker)
{
	g_bArrested[client] = true;
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 0, 190, 255);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
	ShowOverlayCuffs(client, false);
	
	CGOPrintToChatAll("%T %T", "Handcuffs_Prefix", LANG_SERVER, "Handcuffs_Arrest", LANG_SERVER, attacker, client);
}

void FreeEm(int client, int attacker)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	g_bArrested[client] = false;
	ShowOverlayCuffs(client, true);
	CGOPrintToChatAll("%T %T", "Handcuffs_Prefix", LANG_SERVER, "Handcuffs_Release", LANG_SERVER, attacker, client);
}

void UnArrestAll()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			SetEntityMoveType(i, MOVETYPE_WALK);
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			g_bArrested[i] = false;
			ShowOverlayCuffs(i, true);
		}
	}
}

void ShowOverlayCuffs(int client, bool clear)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		int iFlag = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", iFlag &~ FCVAR_CHEAT);
		if (clear)
			ClientCommand(client, "r_screenoverlay \"\"");
		else
			ClientCommand(client, "r_screenoverlay \"%s\"", g_cOverlayPath);
		SetCommandFlags("r_screenoverlay", iFlag);
	}
}

/** Original from smlib
 * Checks if the client is currently looking at the wall in front
 * of him with the given distance as max value.
 * 
 * @param client		Client Index.
 * @param distance		Max Distance as Float value.
 * @return				True if he is looking at a wall, false otherwise.
 */
stock bool Client_IsLookingAtWall(int client, float distance=40.0) {

	float posEye[3], posEyeAngles[3];
	bool isClientLookingAtWall = false;
	
	GetClientEyePosition(client, posEye);
	GetClientEyeAngles(client, posEyeAngles);
	
	posEyeAngles[0] = 0.0;

	Handle trace = TR_TraceRayFilterEx(posEye, posEyeAngles, CONTENTS_SOLID, RayType_Infinite, _smlib_TraceEntityFilter);
	
	if (TR_DidHit(trace)) {
		
		if (TR_GetEntityIndex(trace) > 0) {
			delete trace;
			return false;
		}
		
		float posEnd[3];

		TR_GetEndPosition(posEnd, trace);
		
		if (GetVectorDistance(posEye, posEnd, true) <= (distance * distance)) {
			isClientLookingAtWall = true;
		}
	}
	
	delete trace;
	
	return isClientLookingAtWall;
}

public bool _smlib_TraceEntityFilter(int entity, int contentsMask)
{
	return entity == 0;
}

/**
 * Returns the Float distance between two entities.
 * Both entities must be valid.
 *
 * @param entity		Entity Index.
 * @param target		Target Entity Index.
 * @return				Distance Float value.
 */
stock float Entity_GetDistance(int entity, int target)
{
	float targetVec[3];
	Entity_GetAbsOrigin(target, targetVec);
	
	return Entity_GetDistanceOrigin(entity, targetVec);
}

/**
 * Gets the Absolute Origin (position) of an entity.
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */
stock void Entity_GetAbsOrigin(int entity, float vec[3])
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
}

/**
 * Returns the Float distance between an entity
 * and a vector origin.
 *
 * @param entity		Entity Index.
 * @param target		Vector Origin.
 * @return				Distance Float value.
 */
stock float Entity_GetDistanceOrigin(int entity, const float vec[3])
{
	float entityVec[3];
	Entity_GetAbsOrigin(entity, entityVec);
	
	return GetVectorDistance(entityVec, vec);
}

/**
 * Converts Source Game Units to metric Meters (abstract value)
 * 
 * @param units			Float value
 * @return				Meters as Float value.
 */
stock float Math_UnitsToMeters(float units)
{
	return (units * 0.01905);
}