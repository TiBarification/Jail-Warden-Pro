#include <sourcemod>
#include <cstrike>
#include <basecomm>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define MGIVE "mute_give"
#define MTAKE "mute_take"

bool g_bMuted[MAXPLAYERS+1] = {false, ...};

public Plugin myinfo =
{
	name = "[JWP] Mute",
	description = "Give/Take mute",
	author = "White Wolf (HLModders LLC)",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWC_Started();
	
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);
}

public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (BaseComm_IsClientMuted(i) && g_bMuted[i])
		{
			g_bMuted[i] = false;
			BaseComm_SetClientMute(i, false);
		}
	}
}

public int JWC_Started()
{
	JWP_AddToMainMenu(MGIVE, OnFuncMGiveDisplay, OnFuncMGiveSelect);
	JWP_AddToMainMenu(MTAKE, OnFuncMTakeDisplay, OnFuncMTakeSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu(MGIVE, OnFuncMGiveDisplay, OnFuncMGiveSelect);
	JWP_RemoveFromMainMenu(MTAKE, OnFuncMTakeDisplay, OnFuncMTakeSelect);
}

public bool OnFuncMGiveDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "Дать мут");
	return true;
}

public bool OnFuncMGiveSelect(int client)
{
	ShowPlayerListMenu(client, false);
	return true;
}

public bool OnFuncMTakeDisplay(int client, char[] buffer, int maxlength)
{
	FormatEx(buffer, maxlength, "Снять мут");
	return true;
}

public bool OnFuncMTakeSelect(int client)
{
	ShowPlayerListMenu(client, true);
	return true;
}

void ShowPlayerListMenu(int client, bool muted_pl)
{
	char id[4], name[MAX_NAME_LENGTH];
	Menu PList = new Menu(PList_Callback);
	if (muted_pl)
		PList.SetTitle("Снять мут:");
	else
		PList.SetTitle("Дать мут:");
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i))
		{
			GetClientName(i, name, sizeof(name));
			if (muted_pl && g_bMuted[i])
			{
				IntToString(i, id, sizeof(id));
				PList.AddItem(id, name);
			}
			else if (!muted_pl && !g_bMuted[i])
			{
				IntToString(i, id, sizeof(id));
				if (BaseComm_IsClientMuted(i))
					PList.AddItem(id, name, ITEMDRAW_DISABLED);
				else
					PList.AddItem(id, name);
			}
		}
	}
	if (!PList.ItemCount)
		PList.AddItem("", "Нет доступных игроков", ITEMDRAW_DISABLED);
	PList.ExitBackButton = true;
	PList.Display(client, MENU_TIME_FOREVER);
}

public int PList_Callback(Menu menu, MenuAction action, int client, int slot)
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
			if (target && CheckClient(target))
			{
				if (BaseComm_IsClientMuted(target))
				{
					if (g_bMuted[target])
					{
						g_bMuted[target] = !g_bMuted[target];
						BaseComm_SetClientMute(target, g_bMuted[target]);
					}
					else
					{
						JWP_ActionMsg(client, "Не удалось включить микрофон игроку %N.\nВозможно мут поставлен администратором.", target);
						return;
					}
				}
				else if (!g_bMuted[target])
				{
					g_bMuted[target] = !g_bMuted[target];
					BaseComm_SetClientMute(target, g_bMuted[target]);
				}
				
				JWP_ActionMsgAll("%N %s мут для %N.", client, (g_bMuted[target]) ? "\x03дал\x01" : "\x02снял\x01", target);
				ShowPlayerListMenu(client, !g_bMuted[target]);
			}
		}
	}
}

bool CheckClient(int client)
{
	AdminId admin_id;
	if (IsClientConnected(client))
		 admin_id = GetUserAdmin(client);
	return (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client) && (admin_id == INVALID_ADMIN_ID));
}