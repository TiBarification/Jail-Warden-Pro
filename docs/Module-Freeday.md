## Description
>Give/Take freeday to/from prisoner

## Configuration
Config file is located by this path:
[`cfg/jwp/freeday.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/freeday.cfg)
```
// Alpha value of freeday in RGBA
// -
// Default: "255"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_freeday_a "255"

// Blue value of freeday in RGBA
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_freeday_b "0"

// Green value of freeday in RGBA
// -
// Default: "255"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_freeday_g "255"

// Red value of freeday in RGBA
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "255.000000"
jwp_freeday_r "0"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
You can remove one of them if you need this.
```
"freeday_give"
{
	"flag"	""
}
"freeday_take"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/freeday.cfg` — config file
- `addons/sourcemod/scripting/jwp_freeday.sp` — source file
- `addons/sourcemod/plugins/jwp_freeday.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file

### For developers
Natives that associated with this module
```h
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
```