#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.4"
#define ITEM "pris_counter"

ConVar g_CvarIncludeFD;

public Plugin myinfo = 
{
	name = "[JWP] Prisoner Counter",
	description = "Warden can count prisoners on eye sight",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarIncludeFD = CreateConVar("jwp_pris_counter_fd", "1", "Include freeday player to list?", _, true, 0.0, true, 1.0);
	
	if (JWP_IsStarted()) JWP_Started();
	
	AutoExecConfig(true, "pris_counter", "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Pris_Counter_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (JWP_IsFlood(client)) return false;
	int count[3];
	// Reset count
	count[0] = 0; // Count all, except freeday players
	count[1] = 0; // Count freeday players
	count[2] = 0; // Count everyone T
	// End of reset
	
	ArrayList Rebels = new ArrayList(1);
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			if (!JWP_PrisonerHasFreeday(i))
			{				
				// Count distance
				if (ClientViews(client, i))
					count[0]++;
				else
					Rebels.Push(i);
			}
			else if (g_CvarIncludeFD.BoolValue)
				count[1]++; // Increment freeday players
			count[2]++; // Increment everyone T
		}
	}
	
	JWP_ActionMsg(client, "\x04%d\x03/\x04%d \x03%T", count[0], count[2], "Pris_Counter_ActionMessage_Near", LANG_SERVER);
	if (g_CvarIncludeFD.BoolValue)
		JWP_ActionMsg(client, "\x05%T \x02%d", "Pris_Counter_ActionMessage_Freeday", LANG_SERVER, count[1]);
	
	if (Rebels.Length > 0)
	{
		int user;
		JWP_ActionMsg(client, "\x06%T", "Pris_Counter_ActionMessage_Escaped", LANG_SERVER);
		for (int i = 0; i < Rebels.Length; ++i)
		{
			user = Rebels.Get(i);
			if (user && IsClientInGame(user))
				JWP_ActionMsg(client, "%N", user);
		}
	}
	delete Rebels;
	
	JWP_ShowMainMenu(client);
	return true;
}

// Original code from: https://forums.alliedmods.net/showpost.php?p=973411&postcount=4
stock bool ClientViews(int viewer,int target, float fMaxDistance=0.0, float fThreshold=0.73)
{
	// Retrieve view and target eyes position
	float fViewPos[3];   GetClientEyePosition(viewer, fViewPos);
	float fViewAng[3];   GetClientEyeAngles(viewer, fViewAng);
	float fViewDir[3];
	float fTargetPos[3]; GetClientEyePosition(target, fTargetPos);
	float fTargetDir[3];
	float fDistance[3];
	
	// Calculate view direction
	fViewAng[0] = fViewAng[2] = 0.0;
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
	
	// Calculate distance to viewer to see if it can be seen.
	fDistance[0] = fTargetPos[0]-fViewPos[0];
	fDistance[1] = fTargetPos[1]-fViewPos[1];
	fDistance[2] = 0.0;
	if (fMaxDistance != 0.0)
	{
		if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
			return false;
	}
	
	// Check dot product. If it's negative, that means the viewer is facing
	// backwards to the target.
	NormalizeVector(fDistance, fTargetDir);
	if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
	
	// Now check if there are no obstacles in between through raycasting
	Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
	if (TR_DidHit(hTrace)) { delete hTrace; return false; }
	delete hTrace;
	
	// Done, it's visible
	return true;
}

public bool ClientViewsFilter(int Entity, int Mask, any Junk)
{
	if (Entity >= 1 && Entity <= MaxClients) return false;
	return true;
}