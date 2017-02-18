### How to install Jail Warden Pro
1. Download [Jail Warden Pro release package](../releases)
  * It contains 2 types of release version:
    * `Pre-Release` - last features, but unstable
    * `Release` - stable version
  * Package contains all modules and core
2. Extract package somewhere
  * Not on the game server yet
3. Delete unwanted modules
  * In `addons/sourcemod/plugins`
  * And configs for them in `cfg/jwp`
4. Set ConVars in `cfg/jwp`
  * Sort positions of items in menu from `warden_menu.txt`
5. Setup downloads if needed
  * Some modules like `JWP Skins` don't have their own download manager, so you need to install some plugin to download `materials`, `models`, `sound`.
  * Recommended [SM File/Folder Downloader & Precacher](https://forums.alliedmods.net/showthread.php?p=602270)
6. Upload Jail Warden Pro on game server
  * `addons/` and `cfg/` directories
  * `materials/`, `models/`, `sound/` if needed
7. Change map to load Jail Warden Pro and all modules at once
8. Profit! :smiley:

### Translation issues
* If you have your native languge, send me your translations via PM's or [Pull Request](../pulls)