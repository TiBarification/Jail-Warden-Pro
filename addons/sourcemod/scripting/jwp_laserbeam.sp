#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define ITEM "laserbeam"

bool g_bLightActive;
int g_iGlowEnt, g_iColor[4] = {255, 0, 0, 255};
float LastPos[3], LastLaser[3] = {0.0, 0.0, 0.0};

ConVar	g_CvarColor_r,
		g_CvarColor_g,
		g_CvarColor_b,
		g_CvarColor_a,
		g_CvarLife,
		g_CvarSize;

public Plugin myinfo = 
{
	name = "[JWP] Laser Beam",
	description = "Following beam",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarColor_r = CreateConVar("jwp_laser_beam_color_r", "255", "Красный оттенок луча (rgba)", _, true, 0.0, true, 255.0);
	g_CvarColor_g = CreateConVar("jwp_laser_beam_color_g", "0", "Зеленый оттенок луча (rgba)", _, true, 0.0, true, 255.0);
	g_CvarColor_b = CreateConVar("jwp_laser_beam_color_b", "0", "Синий оттенок луча (rgba)", _, true, 0.0, true, 255.0);
	g_CvarColor_a = CreateConVar("jwp_laser_beam_color_a", "255", "Прозрачность луча (rgba)", _, true, 0.0, true, 255.0);
	g_CvarLife = CreateConVar("jwp_laser_beam_life", "25.0", "Время жизни луча", _, true, 1.0, true, 120.0);
	g_CvarSize = CreateConVar("jwp_laser_beam_size", "2.0", "Ширина луча", _, true, 0.1, true, 25.0);
	
	g_CvarColor_r.AddChangeHook(OnCvarChange);
	g_CvarColor_g.AddChangeHook(OnCvarChange);
	g_CvarColor_b.AddChangeHook(OnCvarChange);
	g_CvarColor_a.AddChangeHook(OnCvarChange);
	
	if (JWP_IsStarted()) JWP_Started();
	AutoExecConfig(true, ITEM, "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void OnMapStart()
{
	g_iGlowEnt = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void OnConfigsExecuted()
{
	g_iColor[0] = g_CvarColor_r.IntValue;
	g_iColor[1] = g_CvarColor_g.IntValue;
	g_iColor[2] = g_CvarColor_b.IntValue;
	g_iColor[3] = g_CvarColor_a.IntValue;
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarColor_r)
		g_iColor[0] = StringToInt(newValue);
	else if (cvar == g_CvarColor_g)
		g_iColor[1] = StringToInt(newValue);
	else if (cvar == g_CvarColor_b)
		g_iColor[2] = StringToInt(newValue);
	else if (cvar == g_CvarColor_a)
		g_iColor[3] = StringToInt(newValue);
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public void JWP_OnWardenChosen(int client)
{
	g_bLightActive = false;
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "[%s]%T", (g_bLightActive) ? '-' : '+', "LaserBeam_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	g_bLightActive = !g_bLightActive;
	
	char menuitem[48];
	if (g_bLightActive)
	{
		FormatEx(menuitem, sizeof(menuitem), "[-]%T", "LaserBeam_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	else
	{
		FormatEx(menuitem, sizeof(menuitem), "[+]%T", "LaserBeam_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, menuitem);
	}
	JWP_ShowMainMenu(client);
	return true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && JWP_IsWarden(client) && g_bLightActive && buttons & IN_USE)
	{
		TraceEye(client, LastLaser);
		TraceEye(client, LastPos);
		LastPos[2] += 2.0;
		
		Laser(LastLaser, LastPos);
		LastLaser[0] = LastPos[0];
		LastLaser[1] = LastPos[1];
		LastLaser[2] = LastPos[2];
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