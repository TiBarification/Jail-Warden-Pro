#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

ConVar g_CvarIconPath;
int g_iIcon = -1;
char g_cPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "[JWP] Icon",
	description = "Icon above warden",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/doctor_white"
};

public void OnPluginStart()
{
	g_CvarIconPath = CreateConVar("jwp_icon_path", "decals/MyJailbreak/warden", "Path to the warden icon DONT TYPE .vmt or .vft");
	if (JWP_IsStarted()) JWP_Started();
	
	AutoExecConfig(true, "icon", "jwp");
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	RemoveIcon();
}

public void JWP_OnWardenChosen(int client)
{
	CreateIcon(client);
}

public void OnMapStart()
{
	char path[PLATFORM_MAX_PATH];
	if (path[0])
	{
		PrecacheModel(path);
		FormatEx(path, sizeof(path), "materials/%s.vmt", g_cPath);
		AddFileToDownloadsTable(path);
		FormatEx(path, sizeof(path), "materials/%s.vtf", g_cPath);
		AddFileToDownloadsTable(path);
	}
}

public void JWP_Started()
{
	g_CvarIconPath.GetString(g_cPath, sizeof(g_cPath));
}

void RemoveIcon()
{
	if (g_iIcon != -1 && IsValidEntity(g_iIcon))
		AcceptEntityInput(g_iIcon, "Kill");
	
	g_iIcon = -1;
}

void CreateIcon(int client)
{
	RemoveIcon();
	
	g_iIcon = CreateEntityByName("env_sprite_oriented");
	
	if (g_iIcon != -1)
	{
		DispatchKeyValue(g_iIcon, "classname", "env_sprite_oriented");
		DispatchKeyValue(g_iIcon, "spawnflags", "1");
		char cIcon[PLATFORM_MAX_PATH];
		FormatEx(cIcon, sizeof(cIcon), "materials/%s.vmt", g_cPath);
		
		DispatchKeyValue(g_iIcon, "model", cIcon);
		DispatchKeyValue(g_iIcon, "scale", "0.3");
		DispatchKeyValue(g_iIcon, "rendermode", "1");
		DispatchKeyValue(g_iIcon, "rendercolor", "255 255 255");
		if (DispatchSpawn(g_iIcon))
		{
			float fPos[3];
			GetClientAbsOrigin(client, fPos);
			fPos[2] += 90.0;
			TeleportEntity(g_iIcon, fPos, NULL_VECTOR, NULL_VECTOR);
			
			SetVariantString("!activator");
			AcceptEntityInput(g_iIcon, "SetParent", client);
			
			SDKHook(g_iIcon, SDKHook_SetTransmit, Should_TransmitW);
		}
	}
}

public Action Should_TransmitW(int entity, int client)
{
	char cModelName[PLATFORM_MAX_PATH], cIcon[PLATFORM_MAX_PATH];
	
	FormatEx(cIcon, sizeof(cIcon), "materials/%s.vmt", g_cPath);
	GetEntPropString(entity, Prop_Data, "m_ModelName", cModelName, sizeof(cModelName));
	if (StrEqual(cIcon, cModelName))
		return Plugin_Continue;
	return Plugin_Handled;
}