## Description
>Warden can toggle speed

## Configuration
Config file is located by this path:
[`cfg/jwp/speed.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/speed.cfg)
```
// Warden speed
// -
// Default: "1.5"
// Minimum: "1.0"
// Maximum: "3.0"
jwp_warden_speed "1.5"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"speed"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_speed.sp` — source file
- `addons/sourcemod/plugins/jwp_speed.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file