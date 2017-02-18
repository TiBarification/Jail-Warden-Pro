## Description
>Warden can extend round

## Configuration
Config file is located by this path:
[`cfg/jwp/round_extender.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/round_extender.cfg)
```
// How many minutes to extend the round
// -
// Default: "5"
// Minimum: "1.000000"
jwp_re_extend "5"

// How many times warden can extend round per round
// -
// Default: "1"
// Minimum: "0.000000"
jwp_re_limit "1"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"rextend"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/round_extender.cfg` — config file
- `addons/sourcemod/scripting/jwp_rextend.sp` — source file
- `addons/sourcemod/plugins/jwp_rextend.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file