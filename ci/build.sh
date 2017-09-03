#!/bin/bash
set -ev

echo "Compilation of JWP Plugins"
for file in addons/sourcemod/scripting/jwp_*.sp
do
  echo "Compile $file"
  filename="$(basename $file .sp)"
  pluginpath="addons/sourcemod/plugins/${filename}.smx"
  addons/sourcemod/scripting/spcomp -E -o"${pluginpath}" -v0 $file
done
