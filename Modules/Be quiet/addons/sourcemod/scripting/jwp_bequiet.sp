#include <voiceannounce_ex> // Need DHooks: https://goo.gl/ZansZH and VoiceAnnounceEx: https://goo.gl/uYomu2
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
	version = "1.1",
	url = "http://tibari.ru http://hlmod.ru"
};

//When Warden speaks or muted client wants to speak
public bool OnClientSpeakingEx(client)
{
	if (client && IsClientInGame(client) && (JWP_IsWarden(client) || JWP_IsZamWarden(client)))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					PrintCenterText(i, "Слушайте приказ КМД");
					SetClientListeningFlags(i, VOICE_MUTED);
					if (GetUserAdmin(i) != INVALID_ADMIN_ID)
						SetClientListeningFlags(i, VOICE_NORMAL);
				}
			}
		}
	}
}

// When client stops talk
public OnClientSpeakingEnd(client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (GetClientTeam(i) == CS_TEAM_T && !BaseComm_IsClientMuted(i) && IsPlayerAlive(i))
			{
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
	}
}
