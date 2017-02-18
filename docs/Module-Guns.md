## Description
>Warden can use guns from menu

## Configuration
Config file is located by this path:
[`cfg/jwp/guns.txt`](../blob/master/cfg/jwp/guns.txt)

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"guns"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/guns.txt` — config file
- `addons/sourcemod/scripting/jwp_guns.sp` — source file
- `addons/sourcemod/plugins/jwp_guns.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file