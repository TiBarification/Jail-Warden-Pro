#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define ITEM "respawn"

ConVar g_CvarMaxUses, g_CvarMethod;
int g_iUses;

public Plugin myinfo = 
{
	name = "[JWP] Respawn",
	description = "Warden can respawn players",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarMaxUses = CreateConVar("jwp_respawn_max", "2", "How many respawns for warden", _, true, 0.0);
	g_CvarMethod = CreateConVar("jwp_respawn_method", "1", "Respawn mode: 0 - on spawn, 1 - on aim position", _, true, 0.0, true, 1.0);
	
	if (JWP_IsStarted()) JWP_Started();
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	
	LoadTranslations("jwp_modules.phrases");
	
	AutoExecConfig(true, "respawn", "jwp");
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iUses = 0;
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
	if (g_CvarMaxUses.IntValue)
	{
		FormatEx(buffer, maxlength, "%T (%d/%d)", "Respawn_Menu", LANG_SERVER, g_iUses, g_CvarMaxUses.IntValue);
		if (g_iUses < g_CvarMaxUses.IntValue) style = ITEMDRAW_DEFAULT;
		else style = ITEMDRAW_DISABLED;
	}
	else
		FormatEx(buffer, maxlength, "%T", "Respawn_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		char langbuffer[48];
		Menu RespawnMenu = new Menu(RespawnMenu_Callback);
		Format(langbuffer, sizeof(langbuffer), "%T:", "Respawn_Menu", LANG_SERVER);
		RespawnMenu.SetTitle(langbuffer);
		char id[4], name[MAX_NAME_LENGTH];
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i))
			{
				Format(name, sizeof(name), "%N", i);
				IntToString(i, id, sizeof(id));
				RespawnMenu.AddItem(id, name);
			}
		}
		if (!RespawnMenu.ItemCount)
		{
			Format(langbuffer, sizeof(langbuffer), "%T", "General_No_Dead_Prisoners", LANG_SERVER);
			RespawnMenu.AddItem("", langbuffer, ITEMDRAW_DISABLED);
		}
		RespawnMenu.ExitBackButton = true;
		RespawnMenu.Display(client, MENU_TIME_FOREVER);
		return true;
	}
	return false;
}

public int RespawnMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack && JWP_IsWarden(client))
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			if (JWP_IsWarden(client))
			{
				char info[4];
				menu.GetItem(slot, info, sizeof(info));
				int target = StringToInt(info);
				if (target && CheckClient(target))
				{
					g_iUses++;
			
					if (g_CvarMaxUses.IntValue)
					{
						char buffer[48];
						Format(buffer, sizeof(buffer), "%T (%d/%d)", "Respawn_Menu", LANG_SERVER, g_iUses, g_CvarMaxUses.IntValue);
						JWP_RefreshMenuItem(ITEM, buffer, (g_iUses < g_CvarMaxUses.IntValue) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
					}
					
					CS_RespawnPlayer(target);
					
					if (g_CvarMethod.BoolValue)
					{
						float endpos[3];
						if (TiB_GetAimInfo(client, endpos))
							TeleportEntity(target, endpos, NULL_VECTOR, NULL_VECTOR);
					}
					
					JWP_ActionMsgAll("%T", "Respawn_ActionMessage_Respawned", LANG_SERVER, client, target);
				}
				else
					JWP_ActionMsg(client, "%T", "Respawn_UnableToRespawn", LANG_SERVER);
				JWP_ShowMainMenu(client);
			}
		}
	}
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T) && !IsPlayerAlive(client));
}

bool TiB_GetAimInfo(int client, float end_origin[3])
{
	float angles[3];
	if (!GetClientEyeAngles(client, angles)) return false;
	float origin[3];
	GetClientEyePosition(client, origin);
	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, client);
	
	if (!TR_DidHit())
		return false;
	
	TR_GetEndPosition(end_origin);
	return true;
}

public bool TraceFilter_Callback(int ent, int mask, any entity)
{
	return entity != ent;
}