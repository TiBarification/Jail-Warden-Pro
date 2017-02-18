## Description
>Warden can place following beam for T. He also can grant permission to paint T on walls.
>If T has access to paint, he can type sm_lpaints to choose color of their paint.

## Configuration
Config file is located by this path:
[`cfg/jwp/laserbeam.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/laserbeam.cfg)
```
// Warden can give this feature to terrorists
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
jwp_laserbeam_t_feature "1"
```
!!! note
    File with colors, you can add your own [`cfg/jwp/laserbeam/colors.txt`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/laserbeam/colors.txt)

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"laserbeam"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `addons/sourcemod/scripting/jwp_laserbeam.sp` — source file
- `addons/sourcemod/plugins/jwp_laserbeam.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file