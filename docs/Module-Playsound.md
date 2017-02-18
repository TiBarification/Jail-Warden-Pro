## Description
>Warden can play sound

## Configuration
Config file is located by this path:
[`cfg/jwp/playsound.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/playsound.cfg)
```
// Sound path without sound dir
// -
// Default: ""
jwp_playsound_sound ""
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"playsound"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_playsound.sp` — source file
- `addons/sourcemod/plugins/jwp_playsound.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file