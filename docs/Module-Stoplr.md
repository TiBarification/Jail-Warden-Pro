## Description
>Warden can stop last request

## Configuration
Config file is located by this path:
[`cfg/jwp/stoplr.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/stoplr.cfg)
```
// How many times warden can stop Last Request
// -
// Default: "2"
jwp_stoplr_max "2"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"stoplr"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/stoplr.cfg` — config file
- `addons/sourcemod/scripting/jwp_stoplr.sp` — source file
- `addons/sourcemod/plugins/jwp_stoplr.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file