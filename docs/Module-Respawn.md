## Description
>Warden can respawn

## Configuration
Config file is located by this path:
[`cfg/jwp/respawn.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/respawn.cfg)
```
// Amount of respawns available for warden per round
// -
// Default: "2"
// Minimum: "0.000000"
jwp_respawn_max "2"

// Respawn mode: 0 - on spawn position, 1 - on aim position
// -
// Default: "1"
// Minimum: "0"
// Maximum: "1"
jwp_respawn_method "1"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"respawn"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/respawn.cfg` — config file
- `addons/sourcemod/scripting/jwp_respawn.sp` — source file
- `addons/sourcemod/plugins/jwp_respawn.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file