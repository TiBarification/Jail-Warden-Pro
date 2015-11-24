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
 *	@return true if warden, false otherwise
*/
native bool JWP_IsWarden(int client);

/**
 *	Is player zam warden ?
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
 *	@return true if success, otherwise false
*/
native bool JWP_SetWarden(int client);

/**
 *	Index of warden zam, if 0 then no zam
 *	-
 *	@return index of warden
*/
native int JWP_GetZamWarden();

/**
 *	Set client as zam of warden or 0 to remove exist zam
 *	-
 *	@return true if success, otherwise false
*/
native bool JWP_SetZamWarden(int client);

/**
 *	Convert (r g b a) string to int array
 *	-
 *	@return true if success, otherwise false
*/
native bool JWP_ConvertToColor(char[] str, int[] array)