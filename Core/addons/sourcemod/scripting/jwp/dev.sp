/* This module is unessesary. If you want delete it, so go on. */

bool g_bIsDeveloper[MAXPLAYERS+1] = {false, ...};

#define DEV_COUNT 2
char Developer_Ids[DEV_COUNT][20] = 
{
	"76561198037625178",
	"76561198078553247"
};

public void OnClientPostAdminCheck(int client)
{
	char auth[20];
	GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	for (int i = 0; i < DEV_COUNT; i++)
	{
		if (strcmp(auth, Developer_Ids[i], false) == 0)
		{
			g_bIsDeveloper[client] = true;
			PrintToServer("Plugin developer %N connected to your server. Epic moment!", client);
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (CheckClient(client) && g_bIsDeveloper[client])
	{
		if (sArgs[0] == '*')
		{
			char text[250];
			strcopy(text, sizeof(text), sArgs);
			ReplaceStringEx(text, sizeof(text), "*", "");
			PrintToChatAll("\x01[\x02DEVELOPER\x01] \x02%N: \x01%s", client, text);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}