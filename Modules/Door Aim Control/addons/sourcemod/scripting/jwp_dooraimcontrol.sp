#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define DROPEN "door_aim_open"
#define DRCLOSE "door_aim_close"

public Plugin myinfo = 
{
	name = "[JWP] Door Aim Control",
	description = "Give warden access to open certain doors",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWC_Started();
}

public int JWC_Started()
{
	JWP_AddToMainMenu(DROPEN, OnFuncDrOpenDisplay, OnFuncDrOpenSelect);
	JWP_AddToMainMenu(DRCLOSE, OnFuncDrCloseDisplay, OnFuncDrCloseSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(DROPEN, OnFuncDrOpenDisplay, OnFuncDrOpenSelect);
	JWP_RemoveFromMainMenu(DRCLOSE, OnFuncDrCloseDisplay, OnFuncDrCloseSelect);
}

public bool OnFuncDrOpenDisplay(int client, char[] buffer, int maxlength, int style)
{
	strcopy(buffer, maxlength, "Открыть камеру (прицел)");
	return true;
}

public bool OnFuncDrOpenSelect(int client)
{
	if (!JWP_IsFlood(client, 3))
		DoorManip(client, true);
	JWP_ShowMainMenu(client);
	return true;
}

public bool OnFuncDrCloseDisplay(int client, char[] buffer, int maxlength, int style)
{
	strcopy(buffer, maxlength, "Закрыть камеру (прицел)");
	return true;
}

public bool OnFuncDrCloseSelect(int client)
{
	if (!JWP_IsFlood(client, 3))
		DoorManip(client, false);
	JWP_ShowMainMenu(client);
	return true;
}

void DoorManip(int client, bool open)
{
	int ent = TiB_GetAimInfo(client);
	char class[28];
	if (IsValidEdict(ent) && ent > MaxClients && GetEntityClassname(ent, class, sizeof(class)) && TiB_IsDoor(class))
	{
		AcceptEntityInput(ent, "Unlock");
		if (open)
		{
			AcceptEntityInput(ent, "Open");
			JWP_ActionMsg(client, "\x03Вы успешно открыли дверь");
		}
		else
		{
			AcceptEntityInput(ent, "Close");
			JWP_ActionMsg(client, "\x02Вы успешно закрыли дверь");
		}
	}
	else
		PrintCenterText(client, "Наведите прицел на дверь");
}

int TiB_GetAimInfo(int client)
{
	float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, client);
	if (!TR_DidHit()) return -1;
	return TR_GetEntityIndex();
}

public bool TraceFilter_Callback(int ent, int mask, int client)
{
	return (client != ent);
}

bool TiB_IsDoor(const char[] classname)
{
	return (StrContains(classname, "movelinear", false) || StrContains(classname, "door", false));
}