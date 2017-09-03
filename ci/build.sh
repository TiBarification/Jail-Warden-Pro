#!/bin/bash
set -ev

echo "Compilation of JWP Plugins"
for file in addons/sourcemod/scripting/jwp_*.sp
do
  echo "Compile $file"
  filename = $(basename "$file" .sp) # Get file name and save it to `filename` var
  addons/sourcemod/scripting/spcomp -E -o"addons/sourcemod/plugins/$filename" -v0 $file
done