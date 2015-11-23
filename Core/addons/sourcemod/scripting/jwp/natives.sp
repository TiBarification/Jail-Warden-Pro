void Native_Initialization()
{
	CreateNative("JWP_IsWarden", Native_IsWarden);
	CreateNative("JWP_GetWarden", Native_GetWarden);
	CreateNative("JWP_SetWarden", Native_SetWarden);
}

public int Native_IsWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsWarden(client);
}

public int Native_GetWarden(Handle plugin, int numParams)
{
	return g_iWarden;
}

public int Native_SetWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!client)
	{
		RemoveCmd(false);
		return true;
	}
	else if (CheckClient(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		RemoveCmd(false);
		BecomeCmd(client);
		return true;
	}
	return false;
}