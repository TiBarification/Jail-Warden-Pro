#!/bin/bash
set -ev

echo "Compilation of JWP Plugins"
for file in addons/sourcemod/scripting/jwp_*.sp
do
  echo "Compile $file"
  addons/sourcemod/scripting/spcomp -E -v0 $file
done

echo ""
echo "Moving compiled plugins to `plugins` directory"
mv addons/sourcemod/scripting/jwp_*.smx addons/sourcemod/plugins