## Description
>Toggle friendly fire

## Configuration
>This module has no configuration

### CS:GO issues

!!!Important
	In some games, like Counter-Strike: Global Offensive some cvars may block damage in friendly fire.

Set this cvars on csgo to something like this for example.
```cfg
ff_damage_reduction_bullets							0.1
ff_damage_reduction_grenade							0.4
ff_damage_reduction_grenade_self					0
ff_damage_reduction_other							0.4
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"ff"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_ff.sp` — source file
- `addons/sourcemod/plugins/jwp_ff.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file