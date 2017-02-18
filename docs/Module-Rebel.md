## Description
>Writes in chat chat who rebels

## Configuration
Config file is located by this path:
[`cfg/jwp/rebel.cfg`](../blob/master/cfg/jwp/rebel.cfg)
```
// Alpha value of rebel in RGBA
// -
// Default: "255"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_rebel_color_a "255"

// Blue value of rebel in RGBA
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_rebel_color_b "0"

// Green value of rebel in RGBA
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_rebel_color_g "0"

// Red value of rebel in RGBA
// -
// Default: "120"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_rebel_color_r "120"

// Necessary amount of damage, that need to become rebel
// -
// Default: "35"
// Minimum: "1.000000"
jwp_rebel_damage "35"

// If T hurt CT, how many seconds T will be rebel? (0 = disable)
// -
// Default: "5"
// Minimum: "0.000000"
jwp_rebel_sec "5"
```

## How to add to menu
>This module has no menu interface

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_rebel.sp` — source file
- `addons/sourcemod/plugins/jwp_rebel.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file

### For developers
Natives that associated with this module
```sourcepawn
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
```