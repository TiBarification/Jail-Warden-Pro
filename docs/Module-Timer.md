## Description
>Warden can start/stop timer

## Configuration
Config file is located by this path:
[`cfg/jwp/wtimer.cfg`](../blob/master/cfg/jwp/wtimer.cfg)
```
// Maximum allowed time for timer
// -
// Default: "600"
// Minimum: "10.000000"
// Maximum: "600.000000"
jwp_wtimer_max "600"

// Minimum allowed time for timer
// -
// Default: "5"
// Minimum: "5.000000"
// Maximum: "10.000000"
jwp_wtimer_min "5"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"wtimer"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/wtimer.cfg` — config file
- `addons/sourcemod/scripting/jwp_wtimer.sp` — source file
- `addons/sourcemod/plugins/jwp_wtimer.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file