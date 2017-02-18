## Description
>This module sets models(skins) on warden/zam/ct/t

## Configuration
Config file is located by this path:
[`cfg/jwp/skin.cfg`](../blob/master/cfg/jwp/skin.cfg)
```
// Set model on warden, leave empty for default model
// -
// Default: ""
jwp_warden_skin ""

// Set model on deputy(zam), leave empty for default model
// -
// Default: ""
jwp_warden_zam_skin ""

// Enable auto-set model on T team. Needed file t_models.txt
// -
// Default: "0"
jwp_random_t_skins "0"

// Enable auto-set model on CT team. Needed file ct_models.txt
// -
// Default: "0"
jwp_random_ct_skins "0"
```

File with models on T/CT teams, you can add your own
[`cfg/jwp/skin/t_models.txt`](../blob/master/cfg/jwp/skin/t_models.txt)
[`cfg/jwp/skin/ct_models.txt`](../blob/master/cfg/jwp/skin/ct_models.txt)

## How to add to menu
>This module has no menu interface

### Files that corresponding to this module
- `cfg/jwp/skin.cfg` — config file
- `cfg/jwp/skin/t_models.txt` — t models
- `cfg/jwp/skin/ct_models.txt` — ct models
- `addons/sourcemod/scripting/jwp_skin.sp` — source file
- `addons/sourcemod/plugins/jwp_skin.smx` — binary file