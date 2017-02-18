## Description
>Warden can mute/unmute T.

## Configuration
Config file is located by this path:
[`cfg/jwp/mute.cfg`](../blob/master/cfg/jwp/mute.cfg)
```
// Mute all terrorists on time. 0 - disable
// -
// Default: "0"
// Minimum: "0"
// Maximum: "600"
jwp_mute_on_time "0"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
You can remove one of them if you need this.
```
"mute_give"
{
	"flag"	""
}
"mute_take"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_mute.sp` — source file
- `addons/sourcemod/plugins/jwp_mute.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file