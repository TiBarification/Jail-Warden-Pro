## Description
>Warden can toggle noblock

## Configuration
>This module has no configuration

### CS:GO Issues

!!!Note
	Some plugins may lock changing of cvar mp_solid_teammates in game

Solution for this is disable collision changes in plugins, that may do it.
For example in SM Hosties it can blocked by this cvar:

```cfg
// Enable or disable integrated removing of player vs player collisions (noblock): 0 - disable, 1 - enable
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
sm_hosties_noblock_enable "1"
```


## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"noblock"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_noblock.sp` — source file
- `addons/sourcemod/plugins/jwp_noblock.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file