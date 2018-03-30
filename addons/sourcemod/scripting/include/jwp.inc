/*
	Library of the [JWP]
	Author: White Wolf
	www.hlmod.ru
	
	|Version by Core: 1.1.5b+ /) 
*/

#if defined _jwp_included
 #endinput
#endif
#define _jwp_included

public SharedPlugin __pl_jwp =
{
	name = "jwp", 
	file = "jwp_core.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

/**
 *	Called when the jail warden pro is ready
 *	-
 *	@noparams
 *	-
 *	@noreturn
*/
forward void JWP_Started();

/** Called to prevent choosing a warden
 *	-
 *	@noparams
 *	-
 *	@return true to enable warden, false to disable warden searching. By default return true;
*/
forward bool JWP_OnWardenChoosing();

/** Called when alive client became warden
 *	-
 *	@param client			Client index
 *	-
 *	@noreturn
*/
forward void JWP_OnWardenChosen(int client);

/** Called when alive client became zam of warden
 *	-
 *	@param client			Client index
 *	-
 *	@noreturn
 */
forward void JWP_OnWardenZamChosen(int client);

/**
 *	Called when warden client is going to resign
 *	-
 *	@param client			Client index
 *	-
 *	@return true to allow resign, false to restrict. By default return true;
 */
forward bool JWP_OnWardenResign(int client);

/**
 *	Warden Resigned
 *	If bool:himself true, then resigned by himself.
 *	Else if he changed own team or disconnected.
 *	-
 *	@noreturn
 */
forward void JWP_OnWardenResigned(int client, bool himself);

/**
 *	Warden Deputy (zam) Resigned
 *	If he died or disconnected or removed by native.
 *	-
 *	@noreturn
 */
forward void JWP_OnWardenZamResigned(int client);

/**
 *	Checks whether the jail warden pro has been started
 *	-
 *	@noparams
 *	-
 *	@return	True if the shop is already started, false otherwise
 */
native bool JWP_IsStarted();

/**
 *	Called when an item from cmd menu is being displayed
 *	-
 *	@param client			Client index an item is being shown to
 *	@param buffer			Buffer to store display name
 *	@param maxlength		Max length of the buffer
 *	@param style			Parameter to change style of item. Has 2 values: ITEMDRAW_DEFAULT or ITEMDRAW_DISABLED. By default ITEMDRAW_DEFAULT
 *	-
 *	@return true to allow displaying and false to block
 */
typedef CmdItemDisplay = function bool (int client, char[] buffer, int maxlength, int style);

/**
 *	Called when an item from cmd menu is being selected
 *	-
 *	@param client			Client index performing selection
 *	-
 *	@return true to allow performing and false to block
 */
typedef CmdItemSelect = function bool (int client);

/**
 *	Adds an item to the cmd menu
 *	-
 *	@param unique name				Set the unique name for item. Important!
 *	@param callback_display			Callback when the item is being shown. Set display name in the callback
 *	@param callback_select			Callback when the item is being selected
 *	-
 *	@noreturn
 */
native void JWP_AddToMainMenu(const char[] name, CmdItemDisplay callback_display, CmdItemSelect callback_select);

/**
 *	Removes an item from the cmd menu
 *	-
 *  @noparams
 *	-
 *	@return true on success, false otherwise
 */
native bool JWP_RemoveFromMainMenu();

/**
 *	Shows cmd menu to a player
 *	-
 *	@param client			Client index to show to
 *	-
 *	@noreturn
 */
native void JWP_ShowMainMenu(int client);

/**
 *	Is player warden ?
 *	-
 *	@param client			Client index
 *	-
 *	@return true if warden, false otherwise
 */
native bool JWP_IsWarden(int client);

/**
 *	Is player zam warden ?
 *	-
 *	@param client			Client index
 *	-
 *	@return true if warden zam, false otherwise
 */
native bool JWP_IsZamWarden(int client);

/**
 *	Index of warden, if 0 then no warden
 *	-
 *	@return index of warden
 */
native int JWP_GetWarden();

/**
 *	Set client as warden or 0 to remove exist warden
 *	-
 *	@param client			Client index
 *	-
 *	@return true if success, otherwise false
 */
native bool JWP_SetWarden(int client);

/**
 *	Index of warden zam, if 0 then no zam
 *	-
 *	@return client index of warden zam and 0 if no zam
 */
native int JWP_GetZamWarden();

/**
 *	Set client as zam of warden or 0 to remove exist zam
 *	-
 *	@param client			Client index
 *	-
 *	@return true if success, otherwise false
 */
native bool JWP_SetZamWarden(int client);

/**
 *	Print action as warden to all
 *	-
 *	@param msg				Message can be formatted via this function like Format
 *	@param ...				Message arguments
 *	-
 *	@noreturn
 */
native void JWP_ActionMsgAll(const char[] msg, any ...);

/**
 *	Print action as warden to client
 *	-
 *	@param client			Client index
 *	@param msg				Message can be formatted via this function like Format
 *	@param ...				Message arguments
 *	-
 *	@noreturn
 */
native void JWP_ActionMsg(int client, const char[] msg, any ...);

/**
 *	Get random player from team
 *	-
 *	@param team				Number of team (-1 - any team, 0 - unassigned, 1 - spec, 2 - terr, 3 - counter-terr)
 *	@param alive			Changing it to true can exclude dead players (with specs) from random system
 *	@param allow_bot		Allows bot to be in random choosing
 *	-
 *	@return random client index
 */
native int JWP_GetRandomTeamClient(int team, bool alive = false, bool allow_bot = true);

/**
 *	Function for anti-flood in menu
 *	-
 *	@param client			Client index
 *	@param delay			Delay for flood protect in seconds. Recommended 1 or 2.
 *	-
 *	@return true if flooding, false otherwise
 */
native bool JWP_IsFlood(int client, int delay = 1);

/********************* INTEGRATION WITH FREEDAY MODULE ***********************/
/*****************************************************************************/

/**
 *	Function to check if player has freeday
 *	-
 *	@param client			Client index
 *	-
 *	@return true if player has freeday, false otherwise
 */
native bool JWP_PrisonerHasFreeday(int client);

/**
 *	Function to set player freeday
 *	-
 *	@param client			Client index
 *	@param state			True to set freeday, or false to take it
 *	-
 *	@return true if player state has been successfully changed, false otherwise
 */
native bool JWP_PrisonerSetFreeday(int client, bool state = true);
/***************** END OF INTEGRATION WITH FREEDAY MODULE ********************/
/*****************************************************************************/

/********************* INTEGRATION WITH ISOLATOR MODULE ***********************/
/******************************************************************************/

/**
 *	Function to check if player in isolator
 *	-
 *	@param client			Client index
 *	-
 *	@return true if player in isolator, false otherwise
 */
native bool JWP_IsPrisonerIsolated(int client);

/**
 *	Function to set player in isolator
 *	-
 *	@param client			Client index
 *	@param state			True to push into isolator, or false to bring him back
 *	-
 *	@return true if player state has been successfully changed, false otherwise
 */
native bool JWP_PrisonerIsolated(int client, bool state = true);

/********************* END OF INTEGRATION WITH ISOLATOR MODULE ****************/
/******************************************************************************/

/********************* INTEGRATION WITH REBEL MODULE ***********************/
/******************************************************************************/

/**
 *	Function to check if player rebelling
 *	-
 *	@param client			Client index
 *	-
 *	@return true if player is rebel, false otherwise
 */
native bool JWP_IsPrisonerRebel(int client);

/**
 *	Function to set player rebel state
 *	-
 *	@param client			Client index
 *	@param state			True to set player state as rebel, false to remove this state
 *	-
 *	@return true if player state has been successfully changed, false otherwise
 */
native bool JWP_PrisonerRebel(int client, bool state = true);

/********************* END OF INTEGRATION WITH REBEL MODULE ****************/
/******************************************************************************/

/**
 *	Function to rehash menu (simple update menu items)
 *	-
 *	@noparams
 *	-
 *	@noreturn
 */
native void JWP_RehashMenu();

/**
 *	Function to get menu item count
 *	-
 *	@noparams
 *	-
 *	@return item count of menu
 */
native int JWP_GetMenuItemCount();

/**
 *	Function to re-style menu item or reload them
 *	-
 *	@param unique name of module
 *	@param new display name, leave empty for ignore
 *	@param style flag of menu item. Can be ITEMDRAW_DEFAULT or ITEMDRAW_DISABLED
 *	-
 *	@return true if style changed, false otherwise
 */
native bool JWP_RefreshMenuItem(char[] item, char[] newdisp = "", int style = ITEMDRAW_DEFAULT);



#if !defined REQUIRE_PLUGIN
public void __pl_jwp_SetNTVOptional()
{
	MarkNativeAsOptional("JWP_IsStarted");
	MarkNativeAsOptional("JWP_AddToMainMenu");
	MarkNativeAsOptional("JWP_RemoveFromMainMenu");
	MarkNativeAsOptional("JWP_ShowMainMenu");
	
	MarkNativeAsOptional("JWP_IsWarden");
	MarkNativeAsOptional("JWP_IsZamWarden");
	
	MarkNativeAsOptional("JWP_GetWarden");
	MarkNativeAsOptional("JWP_SetWarden");
	MarkNativeAsOptional("JWP_GetZamWarden");
	MarkNativeAsOptional("JWP_SetZamWarden");
	
	MarkNativeAsOptional("JWP_ActionMsgAll");
	MarkNativeAsOptional("JWP_ActionMsg");
	
	MarkNativeAsOptional("JWP_GetRandomTeamClient");
	MarkNativeAsOptional("JWP_IsFlood");
	
	MarkNativeAsOptional("JWP_PrisonerHasFreeday");
	MarkNativeAsOptional("JWP_PrisonerSetFreeday");
	
	MarkNativeAsOptional("JWP_IsPrisonerIsolated");
	MarkNativeAsOptional("JWP_PrisonerIsolated");
	
	MarkNativeAsOptional("JWP_IsPrisonerRebel");
	MarkNativeAsOptional("JWP_PrisonerRebel");
	
	MarkNativeAsOptional("JWP_RehashMenu");
	MarkNativeAsOptional("JWP_GetMenuItemCount");
	MarkNativeAsOptional("JWP_RefreshMenuItem");
}
#endif