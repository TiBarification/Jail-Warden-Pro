/*
	Library of the [JWP]
	Author: White Wolf
	www.hlmod.ru
*/

#if defined _jwp_included
 #endinput
#endif
#define _jwp_included

/**
 *	Called when the jail warden pro is ready
 *	-
 *	@noparams
 *	-
 *	@noreturn
*/
forward int JWC_Started();

// Alive ct became warden.
forward int JWP_OnWardenChosen(int client);

// Alive ct became zam of warden.
forward int JWP_OnWardenZamChosen(int client);

/**
 * Warden Resigned
 * If bool:himself true, then resigned by himself.
 * Else if he changed own team or disconnected.
**/
forward int JWP_OnWardenResigned(int client, bool himself);

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
 *	-
 *	@noreturn
*/
typedef CmdItemDisplay = function bool (int client, char[] buffer, int maxlength);

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
 *	@param unique name				Set the unique name to remove.
 *	@param callback_display			Callback to remove
 *	@param callback_select			Callback to remove
 *	-
 *	@return true on success, false otherwise
*/
native bool JWP_RemoveFromMainMenu(const char[] name, CmdItemDisplay callback_display, CmdItemSelect callback_select);

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
 *	Convert (r g b a) string to int array
 *	-
 *	@param str				String which convert
 *	@param array			Array of converted items 
 *	-
 *	@return true if success, otherwise false
*/
native bool JWP_ConvertToColor(char[] str, int[] array);

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
 *	@param team				Number of team (0 - unassigned, 1 - spec, 2 - terr, 3 - counter-terr)
 *	@param alive			Changing it to true can exclude dead players (with specs) from random system
 *	-
 *	@return random client index
*/
native int JWP_GetRandomTeamClient(int team, bool alive = false);

/**
 *	Function for anti-flood in menu
 *	-
 *	@param client			Client index
 *	@param delay			Delay for flood protect in seconds. Recommended 1 or 2.
 *	-
 *	@return true if flooding, false otherwise
*/
native bool JWP_IsFlood(int client, int delay = 1);

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

/**
 * Function to rehash menu (simple update menu items)
 * -
 * @noparams
 * -
 * @noreturn
*/
native void JWP_RehashMenu();

/**
 * Function to get menu item count
 * -
 * @noparams
 * -
 * @return item count of menu
*/
native int JWP_GetMenuItemCount();