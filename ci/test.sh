#!/bin/bash

set -ev

echo "Compilation of JWP Plugins"
for file in addons/sourcemod/scripting/jwp_*.sp
do
  addons/sourcemod/scripting/spcomp -E -v0 $file
done