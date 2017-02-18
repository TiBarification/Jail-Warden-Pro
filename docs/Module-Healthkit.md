## Description
>Warden can heal everyone/t/ct

## Configuration
Config file is located by this path:
[`cfg/jwp/healthkit.cfg`](../blob/master/cfg/jwp/healthkit.cfg)
```
// How many HP regenerate healthkit
// -
// Default: "50"
// Minimum: "1.000000"
jwp_healthkit_hp "50"

// If healthkit not picked, it will be dissolve in 'x' sec (0 = disable)
// -
// Default: "9"
// Minimum: "0.000000"
jwp_healthkit_life "9"

// How many healthkit warden can place. 0 - unlimited
// -
// Default: "3"
// Minimum: "0.000000"
jwp_healthkit_limit "3"

// Maximum allowed HP (healthkit). 0 = unlimited
// -
// Default: "100"
// Minimum: "0.000000"
jwp_healthkit_limit_hp "100"

// Healthkit model
// -
// Default: "models/gibs/hgibs.mdl"
jwp_healthkit_model "models/gibs/hgibs.mdl"

// Who can use healthkit: 1 = Everyone; 2 = T; 3 = CT
// -
// Default: "1"
// Minimum: "1.000000"
// Maximum: "3.000000"
jwp_healthkit_team "1"

// Protect from healthkit flooding. Healthkit available 1 per 'x' seconds
// -
// Default: "3"
// Minimum: "0.000000"
jwp_healthkit_wait "3"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"healthkit"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/healthkit.cfg` — config file
- `addons/sourcemod/scripting/jwp_healthkit.sp` — source file
- `addons/sourcemod/plugins/jwp_healthkit.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file