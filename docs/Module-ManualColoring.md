## Description
>Warden can set the color of T.

## Configuration
Config file is located by this path:
File with colors, you can add your own
[`cfg/jwp/colors/mcolors.txt`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/colors/mcolors.txt)

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"mcoloring"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_mcoloring.sp` — source file
- `addons/sourcemod/plugins/jwp_mcoloring.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file