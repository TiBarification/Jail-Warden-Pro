#include <voiceannounce_ex> // Need DHooks: https://goo.gl/ZansZH and VoiceAnnounceEx: https://goo.gl/uYomu2
#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <jwp>
#include <basecomm>

#define ITEM "bequiet"

ConVar Cvar_AdminFlagMute, Cvar_AutoBequiet, Cvar_WardenMuteAlive, Cvar_WardenMuteT;
bool g_bBequiet;
char g_sAdminFlagMute[64];

public Plugin:myinfo = {
	name = "[JWP] Be quiet",
	author = "Fastmancz & White Wolf",
	description = "Be quiet, please!",
	version = "1.3",
	url = "http://scriptplugs.info http://hlmod.ru"
};

public void OnPluginStart()
{
	Cvar_AutoBequiet = CreateConVar("jwp_warden_autobequiet", "1", "Enable bequiet of warden by default", _, true, 0.0, true, 1.0);
	Cvar_AdminFlagMute = CreateConVar("jwp_admin_mute_immuntiy", "z", "Set flag for admin Mute immunity. No flag immunity for all. so don't leave blank!");
	Cvar_WardenMuteAlive = CreateConVar("jwp_warden_mute_alive", "1", "Enable warden mute only alive", _, true, 0.0, true, 1.0);
	Cvar_WardenMuteT = CreateConVar("jwp_warden_mute_onlyt", "1", "Enable warden mute only T command", _, true, 0.0, true, 1.0);

	// Hooks
	HookConVarChange(Cvar_AdminFlagMute, Mute_OnSettingChanged);

	if (JWP_IsStarted()) JWP_Started();

	// FindConVar
	Cvar_AdminFlagMute.GetString(g_sAdminFlagMute, sizeof(g_sAdminFlagMute));

	LoadTranslations("jwp_modules.phrases");
	AutoExecConfig(true, ITEM, "jwp");
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
	if (Cvar_AutoBequiet.IntValue)
		g_bBequiet = true;
	else
		g_bBequiet = false;
}

public void Mute_OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == Cvar_AdminFlagMute)
	{
		strcopy(g_sAdminFlagMute, sizeof(g_sAdminFlagMute), newValue);
	}
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "[%c]%T", (g_bBequiet) ? '-' : '+', "BeQuiet_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	char langbuffer[24];
	if (g_bBequiet)
	{
		FormatEx(langbuffer, sizeof(langbuffer), "[-]%T", "BeQuiet_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, langbuffer);
	}
	else
	{
		FormatEx(langbuffer, sizeof(langbuffer), "[+]%T", "BeQuiet_Menu", LANG_SERVER);
		JWP_RefreshMenuItem(ITEM, langbuffer);
	}
	JWP_ShowMainMenu(client);
	return true;
}

//When Warden speaks or muted client wants to speak
public void OnClientSpeakingEx(client)
{
	if (client && IsClientInGame(client) && (JWP_IsWarden(client) || JWP_IsZamWarden(client)))
	{
		if(g_bBequiet)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					if(!Cvar_WardenMuteT)
					{
						if(Cvar_WardenMuteAlive)
						{
							if(IsPlayerAlive(i))
							{
								PrintCenterText(i, "%T", "BeQuiet_Listen", LANG_SERVER);
								if (!CheckVipFlag(i, g_sAdminFlagMute))
									SetClientListeningFlags(i, VOICE_NORMAL);
								else
									SetClientListeningFlags(i, VOICE_MUTED);
							}
						}
						else
						{
							PrintCenterText(i, "%T", "BeQuiet_Listen", LANG_SERVER);
							if (!CheckVipFlag(i, g_sAdminFlagMute))
								SetClientListeningFlags(i, VOICE_NORMAL);
							else
								SetClientListeningFlags(i, VOICE_MUTED);
						}
					}
					else if (GetClientTeam(i) == CS_TEAM_T)
					{
						if(Cvar_WardenMuteAlive)
						{
							if(IsPlayerAlive(i))
							{
								PrintCenterText(i, "%T", "BeQuiet_Listen", LANG_SERVER);
								if (!CheckVipFlag(i, g_sAdminFlagMute))
									SetClientListeningFlags(i, VOICE_NORMAL);
								else
									SetClientListeningFlags(i, VOICE_MUTED);
							}
						}
						else
						{
							PrintCenterText(i, "%T", "BeQuiet_Listen", LANG_SERVER);
							if (!CheckVipFlag(i, g_sAdminFlagMute))
								SetClientListeningFlags(i, VOICE_NORMAL);
							else
								SetClientListeningFlags(i, VOICE_MUTED);
						}
					}
				}
			}
		}
	}
}

// When client stops talk
public void OnClientSpeakingEnd(client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (!BaseComm_IsClientMuted(i))
			{
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
	}
}

// Get a player for a certain admin flag
bool CheckVipFlag(int client, char [] flagsNeed)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;

	Format(sflagFormat, sizeof(sflagFormat), flagsNeed);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));

	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}

	return bEntitled;
}