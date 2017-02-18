## Description
>Warden can count prisoners in his Field Of View

## Configuration
Config file is located by this path:
[`cfg/jwp/pris_counter.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/pris_counter.cfg)
```
// Include freeday players to search?
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
jwp_pris_counter_fd "1"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"pris_counter"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_pris_counter.sp` — source file
- `addons/sourcemod/plugins/jwp_pris_counter.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file