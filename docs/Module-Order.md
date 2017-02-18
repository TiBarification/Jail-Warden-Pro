## Description
>Warden can make orders

## Configuration
Config file is located by this path:
[`cfg/jwp/order.cfg`](../blob/master/cfg/jwp/order.cfg)
```
// If 1, each message of warden is an order
// -
// Default: "1"
jwp_order_always "1"

// Message of order
// -
// Default: "{default}({green}{prefix}{default}) {red}{nick}: {default}{text}"
jwp_order_msg "{DEFAULT}({GREEN}{prefix}{DEFAULT}) {RED}{nick}: {DEFAULT}{text}"

// How many seconds panel active
// -
// Default: "20"
// Minimum: "1"
// Maximum: "40"
jwp_order_panel_time "20"

// Enable panel order display
// -
// Default: "0"
// Minimum: "0"
// Maximum: "1"
jwp_order_panel "0"

// Sound if recieved order
// -
// Default: "buttons/blip2.wav"
jwp_order_sound "buttons/blip2.wav"
```

## How to add to menu
Add this section in `warden_menu.txt`. Field `flag` supports admin flags.
```
"order"
{
	"flag"	""
}
```

### Files that corresponding to this module
- `cfg/jwp/order.cfg` — config file
- `addons/sourcemod/scripting/jwp_order.sp` — source file
- `addons/sourcemod/plugins/jwp_order.smx` — binary file
- `addons/sourcemod/translations/jwp_modules.phrases.txt` — translations file