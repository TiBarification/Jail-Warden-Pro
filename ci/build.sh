#!/bin/bash
set -ev

echo "Compilation of JWP Plugins"
for file in addons/sourcemod/scripting/jwp_*.sp
do
  echo "Compile $file"
  addons/sourcemod/scripting/spcomp -E -v0 -o"$pwd/addons/sourcemod/plugins/$file.smx" $file
done