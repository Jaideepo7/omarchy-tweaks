#!/bin/bash
# Rebuild the patched hypr-kinetic-scroll plugin (inertial touchpad scrolling).
# Clones upstream at the commit the patch was made against, applies it, builds.
# Rerun after every Hyprland update: the .so must match the running Hyprland.
set -e
D="$(cd "$(dirname "$0")" && pwd)"
SRC=~/hypr-kinetic-scroll-patched
BASE=657a8a7

if [[ ! -d $SRC/.git ]]; then
  git clone https://github.com/savonovv/hypr-kinetic-scroll.git "$SRC"
  git -C "$SRC" checkout -q "$BASE"
fi
if git -C "$SRC" apply --check "$D/hypr-kinetic-scroll.patch" 2>/dev/null; then
  git -C "$SRC" apply "$D/hypr-kinetic-scroll.patch"
  echo "patch applied"
else
  echo "patch already applied (or source changed)"
fi
make -C "$SRC"
echo "built $SRC/hypr-kinetic-scroll.so"
