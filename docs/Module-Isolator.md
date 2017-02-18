## Description
>Warden can push terrorists to isolator

## Configuration
Config file is located by this path:
[`cfg/jwp/isolator.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/isolator.cfg)
```
// Roof model of isolator
// -
// Default: ""
jwp_isolator_roof ""

// Distance between floor and roof in units
// -
// Default: "125"
// Minimum: "50"
// Maximum: "500"
jwp_isolator_roof_dist "125"

// Sound in isolator. Make "" for no sound
// -
// Default: "ambient/machines/power_transformer_loop_1.wav"
jwp_isolator_sound "ambient/machines/power_transformer_loop_1.wav"

// Walls model of isolator
// -
// Default: "models/props/de_train/chainlinkgate.mdl"
jwp_isolator_wall "models/props/de_train/chainlinkgate.mdl"

// Distance between center and wall
// -
// Default: "80"
// Minimum: "15"
// Maximum: "200"
jwp_isolator_wall_dist "80"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"isolator"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_isolator.sp` — source file
- `addons/sourcemod/plugins/jwp_isolator.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file

### For developers
Natives that associated with this module
```h
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
```