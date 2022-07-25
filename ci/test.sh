#!/bin/bash
set -ev

echo "Compilation of JWP Plugins"
for file in addons/sourcemod/scripting/jwp_*.sp
do
  echo "Compile $file"
  filename=$(basename "$file")
  sourcemod/addons/sourcemod/scripting/spcomp -E -o'addons/sourcemod/plugins/'$filename -i'addons/sourcemod/scripting/include' -v0 $file
done