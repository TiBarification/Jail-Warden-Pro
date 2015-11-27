void Native_Initialization()
{
	CreateNative("JWP_IsWarden", Native_IsWarden);
	CreateNative("JWP_IsZamWarden", Native_IsZamWarden);
	CreateNative("JWP_GetWarden", Native_GetWarden);
	CreateNative("JWP_SetWarden", Native_SetWarden);
	CreateNative("JWP_GetZamWarden", Native_GetZamWarden);
	CreateNative("JWP_SetZamWarden", Native_SetZamWarden);
	CreateNative("JWP_ConvertToColor", Native_ConvertToColor);
	CreateNative("JWP_ActionMsgAll", Native_ActionMsgAll);
	CreateNative("JWP_ActionMsg", Native_ActionMsg);
	CreateNative("JWP_GetRandomTeamClient", Native_GetRandomTeamClient);
	CreateNative("JWP_IsFlood", Native_IsFlood);
}

public int Native_IsWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsWarden(client);
}

public int Native_IsZamWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsZamWarden(client);
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

public int Native_GetZamWarden(Handle plugin, int numParams)
{
	return g_iZamWarden;
}

public int Native_SetZamWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!client)
	{
		RemoveZam();
		return true;
	}
	else if (CheckClient(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		RemoveZam();
		SetZam(client);
		return true;
	}
	return false;
}

public int Native_ConvertToColor(Handle plugin, int numParams)
{
	int rgba_len; char buffer[4][12];
	
	GetNativeStringLength(1, rgba_len);
	
	if (rgba_len <= 0) return ThrowNativeError(SP_ERROR_NATIVE, "Length of your string incorrect: %d", rgba_len);
	
	char[] rgba = new char[rgba_len+1];
	GetNativeString(1, rgba, rgba_len+1);
	
	int color[4];
	GetNativeArray(2, color, sizeof(color));
	
	TrimString(rgba);
	if (strlen(rgba) < 7) return 0;
	if (ExplodeString(rgba, " ", buffer, sizeof(buffer), sizeof(buffer[]), false) < 4) return 0;
	
	for (int i = 0; i < 4; i++)
		color[i] = StringToInt(buffer[i], 10);
	return 1
}

public int Native_ActionMsgAll(Handle plugin, int numParams)
{
	char buffer[192];
	
	FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	PrintToChatAll("%s %s", PREFIX, buffer);
}

public int Native_ActionMsg(Handle plugin, int numParams)
{
	char buffer[192];
	int client = GetNativeCell(1);
	FormatNativeString(0, 2, 3, sizeof(buffer), _, buffer);
	PrintToChat(client, "%s %s", PREFIX, buffer);
}

public int Native_GetRandomTeamClient(Handle plugin, int numParams)
{
	int team = GetNativeCell(1);
	bool alive = GetNativeCell(2);
	return JWP_GetRandomTeamClient(team, alive, true);
}

public int Native_IsFlood(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int delay = GetNativeCell(2);
	return Flood(client, delay);
}