#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define ITEM "laserbeam"

Handle g_BeamTimer;
bool g_bLightActive;
int g_iGlowEnt;
int g_iColor[4] = {255, 0, 0, 255};
float LastLaser[3] = {0.0, 0.0, 0.0};

ConVar	g_CvarColor,
		g_CvarLife,
		g_CvarSize;

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
	g_CvarColor = CreateConVar("jwp_laser_beam_color", "255 0 0 255", "Цвет луча (rgba)", FCVAR_PLUGIN);
	g_CvarLife = CreateConVar("jwp_laser_beam_life", "25.0", "Время жизни луча", FCVAR_PLUGIN, true, 1.0, true, 30.0);
	g_CvarSize = CreateConVar("jwp_laser_beam_size", "0.6", "Ширина луча", FCVAR_PLUGIN, true, 0.1, true, 5.0);
	
	g_CvarColor.AddChangeHook(OnCvarChange);
	g_CvarLife.AddChangeHook(OnCvarChange);
	g_CvarSize.AddChangeHook(OnCvarChange);
	
	if (JWP_IsStarted()) JWC_Started();
}

public void OnMapStart()
{
	LastLaser[0] = 0.0;
	LastLaser[1] = 0.0;
	LastLaser[2] = 0.0;
	g_iGlowEnt = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void OnConfigsExecuted()
{
	char buffer[48];
	g_CvarColor.GetString(buffer, sizeof(buffer));
	JWP_ConvertToColor(buffer, g_iColor);
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarColor)
	{
		char buffer[48];
		g_CvarColor.SetString(newValue);
		strcopy(buffer, sizeof(buffer), newValue);
		JWP_ConvertToColor(buffer, g_iColor);
	}
	else if (cvar == g_CvarLife) g_CvarLife.SetFloat(StringToFloat(newValue));
	else if (cvar == g_CvarSize) g_CvarSize.SetFloat(StringToFloat(newValue));
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
	FormatEx(buffer, maxlength, "[%s]Направляющий свет", (g_bLightActive) ? "-":"+");
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
	TE_SetupBeamPoints(start, end, g_iGlowEnt, 0, 0, 0, g_CvarLife.FloatValue, g_CvarSize.FloatValue, g_CvarSize.FloatValue, 10, 0.0, g_iColor, 0);
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