## Description
>Remove guns on ground by shoot on them

## Configuration
Config file is located by this path:
[`cfg/jwp/shootguns.cfg`](../blob/master/cfg/jwp/shootguns.cfg)
```
// Who can remove weapons on shoot 1 - warden / 2 - warden & deputy / 3 - every ct
// -
// Default: "2"
// Minimum: "1.000000"
// Maximum: "3.000000"
jwp_shootguns_access "2"
```

## How to add to menu
>This module has no menu interface

### Files that corresponding to this module
- `cfg/jwp/shootguns.cfg` — config file
- `addons/sourcemod/scripting/jwp_shootguns.sp` — source file
- `addons/sourcemod/plugins/jwp_shootguns.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file