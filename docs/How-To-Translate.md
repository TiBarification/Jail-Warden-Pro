## Plugin / Modules translations

If you want, you can change translations for your own proposes.

For example, translations from modules can be found in `Jail-Warden-Pro/addons/sourcemod/translations/jwp_modules.phrases.txt`
And if you need to translate Core, you need to edit this file `Jail-Warden-Pro/addons/sourcemod/translations/jwp.phrases.txt`

On different games, there are some issues with **colors**. All you need is to represent colors tags in a format that requires.
For example if you see in chat un-colored text tags, like:
`{green} sometext...`
So you need to replace `{green}` to `{GREEN}` in csgo game. Before doing this, you need to inspect what color tags your game supports.

---
Currently plugin supports `<morecolors>` , `<csgo_colors>` libraries.