#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "laserbeam"

Handle g_BeamTimer;
bool g_bLightActive;
int g_iGlowEnt;
float LastLaser[3] = {0.0, 0.0, 0.0};
/* char GlowLightPath[PLATFORM_MAX_PATH] = "sprites/animglow01.vmt",
	GlowLightColorPick[] = "0 255 0",
	GlowLightSizePick[] = "0.6"; */

public Plugin myinfo = 
{
	name = "[JWP] Laser Beam",
	description = "Following beam",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	// Add cvars jwp_glow_dir_life and jwp_glow_dir_size
	if (JWP_IsStarted()) JWC_Started();
}

public void OnMapStart()
{
	LastLaser[0] = 0.0;
	LastLaser[1] = 0.0;
	LastLaser[2] = 0.0;
	// PrecacheModel(GlowLightPath);
	g_iGlowEnt = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public int JWC_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	KillBeamTimer();
	JWP_RemoveFromMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "[+/-] Направляющий свет");
	return true;
}

public bool OnFuncSelect(int client)
{
	g_bLightActive = !g_bLightActive;
	if (g_bLightActive)
		CreateGlowLight(client);
	JWP_ShowMainMenu(client);
	return true;
}

void CreateGlowLight(int client)
{
	KillBeamTimer();
	g_BeamTimer = CreateTimer(0.2, g_BeamTimer_Callback, client, TIMER_REPEAT);
}

public Action g_BeamTimer_Callback(Handle timer, any client)
{
	if (!JWP_IsWarden(client) || !IsClientInGame(client) || !g_bLightActive)
	{
		g_BeamTimer = null;
		return Plugin_Stop;
	}
	
	float pos[3];
	TraceEye(client, pos);
	pos[2] += 5.0;
	if (GetVectorDistance(pos, LastLaser) > 6.0)
	{
		Laser(LastLaser, pos);
		LastLaser[0] = pos[0];
		LastLaser[1] = pos[1];
		LastLaser[2] = pos[2];
	}
	
	return Plugin_Continue;
}

void TraceEye(int client, float pos[3])
{
	float vOrigin[3], vAngles[3];
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vOrigin);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, client);
	if (TR_DidHit()) TR_GetEndPosition(pos);
}

void Laser(float start[3], float end[3])
{
	TE_SetupBeamPoints(start, end, g_iGlowEnt, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, {255, 0, 0, 255}, 0);
	TE_SendToAll();
}

public bool TraceFilter_Callback(int ent, int mask) 
{ 
	return (ent > GetMaxClients() || !ent);
}

void KillBeamTimer()
{
	if (g_BeamTimer != null)
	{
		KillTimer(g_BeamTimer);
		g_BeamTimer = null;
	}
}