void Native_Initialization()
{
	CreateNative("JWP_IsWarden", Native_IsWarden);
	CreateNative("JWP_IsZamWarden", Native_IsZamWarden);
	CreateNative("JWP_GetWarden", Native_GetWarden);
	CreateNative("JWP_SetWarden", Native_SetWarden);
	CreateNative("JWP_GetZamWarden", Native_GetZamWarden);
	CreateNative("JWP_SetZamWarden", Native_SetZamWarden);
	CreateNative("JWP_ActionMsgAll", Native_ActionMsgAll);
	CreateNative("JWP_ActionMsg", Native_ActionMsg);
	CreateNative("JWP_GetRandomTeamClient", Native_GetRandomTeamClient);
	CreateNative("JWP_IsFlood", Native_IsFlood);
	CreateNative("JWP_PrisonerHasFreeday", Native_PrisonerHasFreeday);
	CreateNative("JWP_PrisonerSetFreeday", Native_PrisonerSetFreeday);
	CreateNative("JWP_IsPrisonerIsolated", Native_IsPrisonerIsolated);
	CreateNative("JWP_PrisonerIsolated", Native_PrisonerIsolated);
	CreateNative("JWP_PrisonerRebel", Native_PrisonerRebel);
	CreateNative("JWP_IsPrisonerRebel", Native_IsPrisonerRebel);
	CreateNative("JWP_RehashMenu", Native_RehashMenu);
	CreateNative("JWP_GetMenuItemCount", Native_JWPGetMenuItemCount);
	CreateNative("JWP_RefreshMenuItem", Native_JWPRefreshMenuItem);
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
	else if (CheckClient(client) && !g_ClientAPIInfo[client][is_banned] && GetClientTeam(client) == CS_TEAM_CT)
	{
		RemoveCmd(false);
		BecomeCmd(client, false, true);
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
	else if (CheckClient(client) && !g_ClientAPIInfo[client][is_banned] && GetClientTeam(client) == CS_TEAM_CT)
	{
		RemoveZam();
		SetZam(client);
		return true;
	}
	return false;
}

public int Native_ActionMsgAll(Handle plugin, int numParams)
{
	char buffer[192], prefix[52];
	
	FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	FormatEx(prefix, sizeof(prefix), "%T", "Core_Prefix", LANG_SERVER);
	if (g_bIsCSGO)
		CGOPrintToChatAll("%s %s", prefix, buffer);
	else
		CPrintToChatAll("%s %s", prefix, buffer);
}

public int Native_ActionMsg(Handle plugin, int numParams)
{
	char buffer[192], prefix[52];
	int client = GetNativeCell(1);
	FormatNativeString(0, 2, 3, sizeof(buffer), _, buffer);
	FormatEx(prefix, sizeof(prefix), "%T", "Core_Prefix", LANG_SERVER);
	if (g_bIsCSGO)
		CGOPrintToChat(client, "%s %s", prefix, buffer);
	else
		CPrintToChat(client, "%s %s", prefix, buffer);
}

public int Native_GetRandomTeamClient(Handle plugin, int numParams)
{
	int team = GetNativeCell(1);
	bool alive = view_as<bool>(GetNativeCell(2));
	return JWP_GetRandomTeamClient(team, alive, true);
}

public int Native_IsFlood(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int delay = GetNativeCell(2);
	if (g_CvarDisableAntiFlood.BoolValue)
		return view_as<int>(false);
	return Flood(client, delay);
}

public int Native_PrisonerHasFreeday(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return PrisonerHasFreeday(client);
}

public int Native_PrisonerSetFreeday(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool state = view_as<bool>(GetNativeCell(2));
	return PrisonerSetFreeday(client, state);
}

public int Native_IsPrisonerIsolated(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsPrisonerIsolated(client);
}

public int Native_PrisonerIsolated(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool state = view_as<bool>(GetNativeCell(2));
	return PrisonerIsolated(client, state);
}

public int Native_PrisonerRebel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	bool state = view_as<bool>(GetNativeCell(2));
	return PrisonerRebel(client, state);
}

public int Native_IsPrisonerRebel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsPrisonerRebel(client);
}

public int Native_RehashMenu(Handle plugin, int numParams)
{
	RehashMenu();
	return 0;
}

public int Native_JWPGetMenuItemCount(Handle plugin, int numParams)
{
	return g_aSortedMenu.Length;
}

public int Native_JWPRefreshMenuItem(Handle plugin, int numParams)
{
	char item[16], display[64];
	GetNativeString(1, item, sizeof(item));
	GetNativeString(2, display, sizeof(display));
	int style = GetNativeCell(3);
	return RefreshMenuItem(item, display, style);
}