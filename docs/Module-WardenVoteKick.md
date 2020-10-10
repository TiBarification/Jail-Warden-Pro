## Description
>Health for warden and him deputy(zam)

## Configuration
Config file is located by this path:
[`cfg/jwp/wvotekick.cfg`](https://github.com/TiBarification/Jail-Warden-Pro/blob/master/cfg/jwp/wvotekick.cfg)
```
// Percent of T votes need to kick warden
// -
// Default: "60"
// Minimum: "1.000000"
// Maximum: "100.000000"
sm_jwp_votewardenkick_percent "60"

// Limit of kicks per round
// -
// Default: "1"
// Minimum: "1.000000"
// Maximum: "100.000000"
sm_jwp_votewardenkick_per_round "1"
```

## How to add to menu
>This module has no menu interface

### Files that corresponding to this module
- `cfg/jwp/wvotekick.cfg` — config file
- `addons/sourcemod/scripting/jwp_wvotekick.sp` — source file
- `addons/sourcemod/plugins/jwp_wvotekick.smx` — binary file