#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.6"
#define ITEM "laserbeam"

#define DEFAULT_RED_COLOR 255
#define DEFAULT_GREEN_COLOR 0
#define DEFAULT_BLUE_COLOR 0
#define DEFAULT_ALPHA_COLOR 255
#define DEFAULT_BEAM_WIDTH 2.0
#define DEFAULT_BEAM_LIFE 25.0

enum Target
{
	bool:lightActive, // Is light active for client (global)
	bool:paintActive, // Is paint active for client (on press +E)
	r_color, // Color for client (global)
	g_color,
	b_color,
	alpha,
	Float:laser_life, // Life of laser beam
	Float:laser_width, // Width of laser beam
	Float:lastAimPos[3], // last aim position of client beam
	Float:lastLaserPos[3], // last laser position of client beam
	lastButtons // last buttons that client pressed
}

bool g_bTCanUse;
int g_iClientData[MAXPLAYERS+1][Target];
int g_iGlowEnt, g_iHaloSprite;
Menu g_mMainMenu, g_mColorMenu;
ConVar g_CvarTFeature;

public Plugin myinfo = 
{
	name = "[JWP] Laser Beam",
	description = "Following beam",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarTFeature = CreateConVar("jwp_laserbeam_t_feature", "1", "Warden can give this feature to terrorists", _, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_lpaints", Command_LPaints, "Ability to paint via laserbeam like warden");
	
	if (JWP_IsStarted()) JWP_Started();
	AutoExecConfig(true, ITEM, "jwp");
	
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	
	LoadTranslations("jwp_modules.phrases");
	LoadTranslations("jwp.phrases");
	
	LoadMenus();
}

public void OnMapStart()
{
	g_iGlowEnt = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt", true);
	
	CreateTimer(0.1, PrintLaser, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client) && g_iClientData[client][lightActive])
		DisableAllForClient(client);
}

public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
			DisableAllForClient(i);
	}
	
	g_bTCanUse = false;
}

public Action Command_LPaints(int client, int args)
{
	if (!args)
	{
		if (client && IsClientInGame(client) && (GetClientTeam(client) == CS_TEAM_T || JWP_IsWarden(client)))
		{
			if (IsPlayerAlive(client))
			{
				if (g_iClientData[client][lightActive])
					g_mColorMenu.Display(client, MENU_TIME_FOREVER);
				else
					PrintToChat(client, "\x01\x03%T", "LaserBeam_WardenMustGiveAccess", LANG_SERVER);
			}
			else
				PrintToChat(client, "\x01\x03%T", "warden_must_be_alive", LANG_SERVER);
		}
		else
			PrintToChat(client, "\x01\x03%T", "LaserBeam_AccessForT", LANG_SERVER);
	}
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public void JWP_OnWardenChosen(int client)
{
	g_iClientData[client][lightActive] = false;
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	g_iClientData[client][paintActive] = false;
	g_iClientData[client][lightActive] = false;
	g_iClientData[client][lastButtons] = 0;
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "LaserBeam_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		g_mMainMenu.Display(client, MENU_TIME_FOREVER);
		return true;
	}
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && g_iClientData[client][lightActive])
	{
		if (buttons & IN_USE) // Runs many times per sec
		{
			float fOrigin[3], fImpact[3];
			GetClientEyePosition(client, fOrigin);
			TraceEye(client, fImpact);
			
			// Draw from eyes to aim
			Laser(client, fOrigin, fImpact, true);
		}
		
		// Runs once it pressed, not many times
		for (int i = 0; i < 25; i++)
		{
			int button = (1 << i);
			
			if ((buttons & button))
			{
				if (!(g_iClientData[client][lastButtons] & button))
				{
					OnButtonPress(client, button);
				}
			}
			else if ((g_iClientData[client][lastButtons] & button))
			{
				OnButtonRelease(client, button);
			}
		}
		g_iClientData[client][lastButtons] = buttons;
	}
	return Plugin_Continue;
}

void TraceEye(int client, float pos[3])
{
	float vOrigin[3], vAngles[3];
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vOrigin);
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, client);
	if (TR_DidHit()) TR_GetEndPosition(pos);
}

void Laser(int client, float start[3], float end[3], bool mode)
{
	int color[4]; 
	color[0] = g_iClientData[client][r_color];
	color[1] = g_iClientData[client][g_color];
	color[2] = g_iClientData[client][b_color];
	color[3] = g_iClientData[client][alpha];
	
	// Make it RAINBOOM aka Rainbow
	if (color[0] == 0 && color[1] == 0 && color[2] == 0 && color[3] == 0)
	{
		color[0] = RoundToFloor(Sine(0.3*GetRandomInt(0, 255))*100);
		color[1] = RoundToFloor(Sine(0.2*GetRandomInt(0, 255))*100);
		color[2] = RoundToFloor(Sine(0.6*GetRandomInt(0, 255))*100);
		color[3] = 255;
	}
	
	if (mode)
	{
		if (JWP_IsWarden(client))
		{
			TE_SetupGlowSprite(end, g_iHaloSprite, 0.1, 0.25, 255);
			TE_SendToAll();
		}
		TE_SetupBeamPoints(start, end, g_iGlowEnt, 0, 0, 0, 0.1, 0.12, 0.0, 1, 0.0, color, 0);
	}
	else
		TE_SetupBeamPoints(start, end, g_iGlowEnt, 0, 0, 0, g_iClientData[client][laser_life], g_iClientData[client][laser_width], g_iClientData[client][laser_width], 10, 0.0, color, 0);
	TE_SendToAll();
}

public bool TraceFilter_Callback(int ent, int mask) 
{ 
	return (ent > MaxClients || !ent);
}

stock void OnButtonPress(int client,int button)
{
	if(button == IN_USE)
	{
		float aimpos[3];
		// Draw from g_fLastAimPos to new pos
		TraceEye(client, aimpos);
		
		g_iClientData[client][lastAimPos][0] = aimpos[0];
		g_iClientData[client][lastAimPos][1] = aimpos[1];
		g_iClientData[client][lastAimPos][2] = aimpos[2];
		g_iClientData[client][paintActive] = true;
	}
}


stock void OnButtonRelease(int client,int button)
{
	if(button == IN_USE)
	{
		g_iClientData[client][lastAimPos][0] = 0.0;
		g_iClientData[client][lastAimPos][1] = 0.0;
		g_iClientData[client][lastAimPos][2] = 0.0;
		g_iClientData[client][paintActive] = false;
	}
}

public Action PrintLaser(Handle timer)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && g_iClientData[i][paintActive])
		{
			float fLaserPos[3], fAimPos[3];
			TraceEye(i, fLaserPos);
			g_iClientData[i][lastLaserPos][0] = fLaserPos[0];
			g_iClientData[i][lastLaserPos][1] = fLaserPos[1];
			g_iClientData[i][lastLaserPos][2] = fLaserPos[2];
			fAimPos[0] = g_iClientData[i][lastAimPos][0];
			fAimPos[1] = g_iClientData[i][lastAimPos][1];
			fAimPos[2] = g_iClientData[i][lastAimPos][2];
			if (GetVectorDistance(fLaserPos, fAimPos) > 6.0)
			{
				Laser(i, fAimPos, fLaserPos, false);
				g_iClientData[i][lastAimPos][0] = g_iClientData[i][lastLaserPos][0];
				g_iClientData[i][lastAimPos][1] = g_iClientData[i][lastLaserPos][1];
				g_iClientData[i][lastAimPos][2] = g_iClientData[i][lastLaserPos][2];
			}
		}
	}
}

void DisableAllForClient(int client)
{
	g_iClientData[client][lightActive] = false;
	g_iClientData[client][paintActive] = false;
	g_iClientData[client][laser_life] = DEFAULT_BEAM_LIFE;
	g_iClientData[client][laser_width] = DEFAULT_BEAM_WIDTH;
	g_iClientData[client][r_color] = DEFAULT_RED_COLOR;
	g_iClientData[client][g_color] = DEFAULT_GREEN_COLOR;
	g_iClientData[client][b_color] = DEFAULT_BLUE_COLOR;
	g_iClientData[client][alpha] = DEFAULT_ALPHA_COLOR;
	g_iClientData[client][lastAimPos][0] = 0.0;
	g_iClientData[client][lastAimPos][1] = 0.0;
	g_iClientData[client][lastAimPos][2] = 0.0;
	g_iClientData[client][lastLaserPos][0] = 0.0;
	g_iClientData[client][lastLaserPos][1] = 0.0;
	g_iClientData[client][lastLaserPos][2] = 0.0;
	g_iClientData[client][lastButtons] = 0;
	g_mColorMenu.Cancel();
}

void LoadMenus()
{
	// Load main menu
	g_mMainMenu = new Menu(MainMenu_Callback, MenuAction_DisplayItem|MenuAction_Select|MenuAction_Cancel);
	char lang[128];
	FormatEx(lang, sizeof(lang), "%T", "LaserBeam_Menu", LANG_SERVER);
	g_mMainMenu.SetTitle(lang);
	FormatEx(lang, sizeof(lang), "[+] %T", "LaserBeam_ToggleSelfStatus", LANG_SERVER);
	g_mMainMenu.AddItem("status", lang);
	FormatEx(lang, sizeof(lang), "[+] %T", "LaserBeam_AccessForT", LANG_SERVER);
	g_mMainMenu.AddItem("Taccess", lang, (g_CvarTFeature.BoolValue) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	FormatEx(lang, sizeof(lang), "%T", "LaserBeam_PickUpColor", LANG_SERVER);
	g_mMainMenu.AddItem("color", lang);
	g_mMainMenu.ExitBackButton = true;
	
	// Load colors menu
	KeyValues kv = new KeyValues("Colors");
	
	if (!kv.ImportFromFile("cfg/jwp/laserbeam/colors.txt"))
	{
		delete kv;
		SetFailState("Unable to load file cfg/jwp/laserbeam/colors.txt");
	}
	
	g_mColorMenu = new Menu(ColorMenu_Callback);
	char buffer[64], langbuffer[64];
	FormatEx(buffer, sizeof(buffer), "%T", "LaserBeam_ColorMenu", LANG_SERVER);
	g_mColorMenu.SetTitle(buffer);
	g_mColorMenu.ExitBackButton = true;
	int color[4];
	float fLife, fWidth;
	if (kv.GotoFirstSubKey(true))
	{
		do
		{
			kv.GetString("name", langbuffer, sizeof(langbuffer));
			if (StrContains(langbuffer, "COLOR_", false) != -1) // If name founded in translations file (jwp_modules.phrases.txt)
			{
				Format(langbuffer, sizeof(langbuffer), "LaserBeam_%s", langbuffer);
				Format(langbuffer, sizeof(langbuffer), "%T", langbuffer, LANG_SERVER);
			}
			kv.GetColor4("rgba", color);
			fLife = kv.GetFloat("life", DEFAULT_BEAM_LIFE);
			fWidth = kv.GetFloat("width", DEFAULT_BEAM_WIDTH);
			
			FormatEx(buffer, sizeof(buffer), "%d:%d:%d:%d:%.1f:%.1f", color[0], color[1], color[2], color[3], fLife, fWidth);
			g_mColorMenu.AddItem(buffer, langbuffer);
		} while (kv.GotoNextKey(true));
	}
	
	delete kv;
}

public int MainMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_Exit) return 0;
			if (JWP_IsWarden(param1))
				JWP_ShowMainMenu(param1);
		}
		case MenuAction_DisplayItem:
		{
			// Update item on 0 position (top)
			char lang[128];
			if (param2 == 0)
			{
				FormatEx(lang, sizeof(lang), "[%s] %T", (g_iClientData[param1][lightActive]) ? '-' : '+', "LaserBeam_ToggleSelfStatus", LANG_SERVER);
				return RedrawMenuItem(lang);
			}
			else if (g_CvarTFeature.BoolValue && param2 == 1) // Update item on 1 position
			{
				FormatEx(lang, sizeof(lang), "[%s] %T", (g_bTCanUse) ? '-' : '+', "LaserBeam_AccessForT", LANG_SERVER);
				return RedrawMenuItem(lang);
			}
		}
		case MenuAction_Select:
		{
			if (!JWP_IsWarden(param1)) return 0;
			if (param2 == 0 || param2 == 1) // param1 - client | param2 - slot position
			{
				if (param2 == 0)
				{
					if (g_iClientData[param1][lightActive])
					{
						if (g_bTCanUse)
						{
							g_bTCanUse = false;
							for (int i = 1; i <= MaxClients; ++i)
							{
								if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
									JWP_ActionMsg(i, "\x03%T", "LaserBeam_TakeAction", LANG_SERVER, param1);
								DisableAllForClient(i);
							}
						}
						else
							g_iClientData[param1][lightActive] = false;
					}
					else
						g_iClientData[param1][lightActive] = true;
				}
				else // if param2 == 1
				{
					g_bTCanUse = !g_bTCanUse;
					for (int i = 1; i <=MaxClients; ++i)
					{
						if (i != param1 && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
						{
							if (g_bTCanUse)
							{
								g_iClientData[i][paintActive] = true;
								JWP_ActionMsg(i, "\x03%T", "LaserBeam_GrantAction", LANG_SERVER, param1);
							}
							else
							{
								DisableAllForClient(i);
								JWP_ActionMsg(i, "\x03%T", "LaserBeam_TakeAction", LANG_SERVER, param1);
							}
						}
					}
				}
				g_mMainMenu.Display(param1, MENU_TIME_FOREVER);
			}
			else if (g_iClientData[param1][lightActive])
				g_mColorMenu.Display(param1, MENU_TIME_FOREVER);
			else
				g_mMainMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
	return 0;
}

public int ColorMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				if (!JWP_IsWarden(param1)) return;
				g_mMainMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Select:
		{
			if (!g_iClientData[param1][lightActive]) return;
			char info[64], name[48];
			menu.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
			char expl_str[6][18]; // 6 how many arguments to get from `info`
			ExplodeString(info, ":", expl_str, sizeof(expl_str[]), sizeof(expl_str));
			int color[4];
			float other[2];
			for (int i, j = 0; i < 6; ++i)
			{
				if (i < 4)
					color[i] = StringToInt(expl_str[i]);
				else
					other[j++] = StringToFloat(expl_str[i]);
			}
			
			g_iClientData[param1][r_color] = color[0];
			g_iClientData[param1][g_color] = color[1];
			g_iClientData[param1][b_color] = color[2];
			g_iClientData[param1][alpha] = color[3];
			g_iClientData[param1][laser_life] = other[0];
			g_iClientData[param1][laser_width] = other[1];
			
			g_mColorMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
}