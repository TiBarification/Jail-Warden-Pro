#include <sourcemod>
#include <cstrike>
#include <basecomm>
#include <sdktools>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define MGIVE "mute_give"
#define MTAKE "mute_take"

bool g_bMuted[MAXPLAYERS+1] = {false, ...};
ConVar g_CvarMuteOnTime;

Handle TempMute_Timer;

public Plugin myinfo =
{
	name = "[JWP] Mute",
	description = "Give/Take mute",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarMuteOnTime = CreateConVar("jwp_mute_on_time", "0", "Мут всех террористов на время. 0 - чтобы отключить", _, true, 0.0, true, 600.0);
	
	if (JWP_IsStarted()) JWP_Started();
	
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);
	AutoExecConfig(true, "mute", "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && BaseComm_IsClientMuted(i) && g_bMuted[i])
		{
			g_bMuted[i] = false;
			BaseComm_SetClientMute(i, false);
		}
	}
}

public void JWP_Started()
{
	JWP_AddToMainMenu(MGIVE, OnFuncMGiveDisplay, OnFuncMGiveSelect);
	JWP_AddToMainMenu(MTAKE, OnFuncMTakeDisplay, OnFuncMTakeSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncMGiveDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Mute_Menu_GiveMute", LANG_SERVER);
	return true;
}

public bool OnFuncMGiveSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		ShowPlayerListMenu(client, false);
		return true;
	}
	return false;
}

public bool OnFuncMTakeDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Mute_Menu_TakeMute", LANG_SERVER);
	return true;
}

public bool OnFuncMTakeSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		ShowPlayerListMenu(client, true);
		return true;
	}
	return false;
}

void ShowPlayerListMenu(int client, bool muted_pl)
{
	char id[4], name[MAX_NAME_LENGTH], langbuffer[48];
	Menu PList = new Menu(PList_Callback);
	if (muted_pl)
	{
		Format(langbuffer, sizeof(langbuffer), "%T:", "Mute_Menu_TakeMute", LANG_SERVER);
		PList.SetTitle(langbuffer);
	}
	else
	{
		Format(langbuffer, sizeof(langbuffer), "%T:", "Mute_Menu_GiveMute", LANG_SERVER);
		PList.SetTitle(langbuffer);
	}
	
	// Mute on time
	if (g_CvarMuteOnTime.FloatValue)
	{
		if (muted_pl)
		{
			Format(langbuffer, sizeof(langbuffer), "%T", "Mute_UnMuteAll", LANG_SERVER);
			PList.AddItem("unmuteall", langbuffer, (TempMute_Timer == null) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
		else
		{
			Format(langbuffer, sizeof(langbuffer), "%T", "Mute_MuteAll", LANG_SERVER, g_CvarMuteOnTime.FloatValue);
			PList.AddItem("muteall", langbuffer, (TempMute_Timer != null) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
	}
	
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
	{
		Format(langbuffer, sizeof(langbuffer), "%T", "General_No_Prisoners", LANG_SERVER);
		PList.AddItem("", langbuffer, ITEMDRAW_DISABLED);
	}
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
			if (slot == MenuCancel_ExitBack && JWP_IsWarden(client))
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			if (JWP_IsWarden(client))
			{
				if (g_CvarMuteOnTime.FloatValue && !slot)
				{
					for (int i = 1; i <= MaxClients; ++i)
					{
						if (CheckClient(i))
						{
							if (BaseComm_IsClientMuted(i))
							{
								if (g_bMuted[i]) // Если мут есть и поставлен не админом, тогда снимаем
								{
									g_bMuted[i] = !g_bMuted[i];
									BaseComm_SetClientMute(i, g_bMuted[i]);
									SetClientListeningFlags(i, VOICE_NORMAL);
								}
								else
									JWP_ActionMsg(client, "%T", "Mute_Dont_Have_Permission", LANG_SERVER, i);
							}
							else if (!g_bMuted[i]) // Если мута нет, тогда ставим
							{
								g_bMuted[i] = !g_bMuted[i];
								BaseComm_SetClientMute(i, g_bMuted[i]);
								SetClientListeningFlags(i, VOICE_MUTED);
							}
						}
					}
					
					if (TempMute_Timer != null)
					{
						KillTimer(TempMute_Timer);
						JWP_ActionMsgAll("%T", "Mute_ActionMessage_UnMuted_All", LANG_SERVER, client);
						TempMute_Timer = null;
					}
					else
					{
						TempMute_Timer = CreateTimer(g_CvarMuteOnTime.FloatValue, TempMute_Timer_Callback);
						JWP_ActionMsgAll("%T", "Mute_ActionMessage_Muted_All", LANG_SERVER, client, g_CvarMuteOnTime.FloatValue);
					}
					ShowPlayerListMenu(client, (TempMute_Timer == null) ? true : false);
				}
				else
				{
					char info[4];
					menu.GetItem(slot, info, sizeof(info));
					int target = StringToInt(info);
					if (target && CheckClient(target))
					{
						if (BaseComm_IsClientMuted(target))
						{
							if (g_bMuted[target])
							{
								g_bMuted[target] = !g_bMuted[target];
								BaseComm_SetClientMute(target, g_bMuted[target]);
								SetClientListeningFlags(target, VOICE_NORMAL);
							}
							else
							{
								JWP_ActionMsg(client, "%T", "Mute_Dont_Have_Permission", LANG_SERVER, target);
								return;
							}
						}
						else if (!g_bMuted[target])
						{
							g_bMuted[target] = !g_bMuted[target];
							BaseComm_SetClientMute(target, g_bMuted[target]);
							SetClientListeningFlags(target, VOICE_MUTED);
						}
						
						JWP_ActionMsgAll("%T", (g_bMuted[target]) ? "Mute_ActionMessage_Muted" : "Mute_ActionMessage_UnMuted", LANG_SERVER, client, target);
						ShowPlayerListMenu(client, !g_bMuted[target]);
					}
				}
			}
		}
	}
}

public Action TempMute_Timer_Callback(Handle timer)
{
	if (TempMute_Timer != null)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i) && g_bMuted[i] && BaseComm_IsClientMuted(i))
			{
				g_bMuted[i] = false;
				BaseComm_SetClientMute(i, false);
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
		JWP_ActionMsgAll("%T", "Mute_ActionMessage_MicroAvailable", LANG_SERVER);
	}
	TempMute_Timer = null;
}

bool CheckClient(int client)
{
	AdminId admin_id;
	if (IsClientConnected(client))
		 admin_id = GetUserAdmin(client);
	return (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client) && (admin_id == INVALID_ADMIN_ID));
}