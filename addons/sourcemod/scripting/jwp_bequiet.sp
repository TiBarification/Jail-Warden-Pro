#if SOURCEMOD_V_MINOR == 10
#include <voiceannounce_ex> // Need DHooks: https://goo.gl/ZansZH and VoiceAnnounceEx: https://goo.gl/uYomu2
#endif
#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <jwp>
#include <basecomm>

public Plugin:myinfo = {
	name = "[JWP] Be quiet",
	author = "Fastmancz & White Wolf",
	description = "Be quiet, please!",
	version = "1.3",
	url = "http://scriptplugs.info http://hlmod.ru"
};

public void OnPluginStart()
{
	LoadTranslations("jwp_modules.phrases");
}

//When Warden speaks or muted client wants to speak
#if SOURCEMOD_V_MINOR == 10
public void OnClientSpeakingEx(client)
#else
public void OnClientSpeaking(client)
#endif
{
	if (client && IsClientInGame(client) && (JWP_IsWarden(client) || JWP_IsZamWarden(client)))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					PrintCenterText(i, "%T", "BeQuiet_Listen", LANG_SERVER);
					if (GetUserAdmin(i) != INVALID_ADMIN_ID)
						SetClientListeningFlags(i, VOICE_NORMAL);
					else
						SetClientListeningFlags(i, VOICE_MUTED);
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
