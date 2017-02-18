## Convars for Core ##
The convars below are related only for **Core**
> cfg/jwp/jwp.cfg

	// How to choose warden 1:random 2:command 3:voting
	// -
	// Default: "2"
	// Minimum: "1.000000"
	// Maximum: "3.000000"
	jwp_choose_mode "2"
	
	// Protect menu from random selecting
	// -
	// Default: "1"
	// Minimum: "0.000000"
	// Maximum: "1.000000"
	jwp_disable_antiflood "1"
	
	// Time before warden randomly picked if choose mode = 1
	// -
	// Default: "5"
	// Minimum: "1.000000"
	// Maximum: "30.000000"
	jwp_random_wait "5"
	
	// Time for voting if choose mode = 3
	// -
	// Default: "30"
	// Minimum: "10.000000"
	// Maximum: "60.000000"
	jwp_vote_time "30"
	
	// Enable (1) or disable (0) auto update. Need Updater!
	// -
	// Default: "0"
	// Minimum: "0.000000"
	// Maximum: "1.000000"
	jwp_autoupdate "0"
## Core Commands ##
This commands only for warden applying or to show warden menu (console commands) alias with `!` or `/` symbols
* sm_com
* sm_w
* sm_warden
* sm_control
* sm_c

Next command to reload warden menu. (Simple rehash menu items). Only server can execute.
* jwp_menu_reload
Next command to refresh developer or banned status on player. Only server can execute.
* jwp_apidata_reload

***
Next step is configure **warden_menu.txt** to create an order of menu and admin flags needed to show item in menu.