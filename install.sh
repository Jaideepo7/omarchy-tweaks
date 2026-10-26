#!/bin/bash
# Re-apply personal tweaks after an update/resync. Safe to run repeatedly.
set -e
D="$(cd "$(dirname "$0")" && pwd)"

# Hyprland config: symlink so edits land in this repo
for f in "$D"/hypr/*.lua; do ln -sfn "$f" ~/.config/hypr/"$(basename "$f")"; done
mkdir -p ~/.local/bin
ln -sfn "$D/bin/omarchy-proportional-grow" ~/.local/bin/omarchy-proportional-grow

# Whole plugins I wrote myself (copied in, not symlinked: the shell only scans
# real directories under ~/.config/omarchy/plugins)
for p in "$D"/plugins/*/; do
  name=$(basename "$p")
  mkdir -p ~/.config/omarchy/plugins/"$name"
  cp -r "$p". ~/.config/omarchy/plugins/"$name"/
done

# Plugin patches (each skipped if already applied or the plugin changed upstream)
apply_patch() {  # <plugin dir> <patch file>
  if patch -p1 -d "$1" --dry-run -s < "$2" >/dev/null 2>&1; then
    patch -p1 -d "$1" -s < "$2" && echo "applied $(basename "$2")"
  else
    echo "skipped $(basename "$2") (already applied or plugin changed)"
  fi
}
apply_patch ~/.config/omarchy/plugins/tmn73.calendar "$D/patches/calendar-timedrow.patch"
apply_patch ~/.config/omarchy/plugins/jaideep.bar "$D/patches/bar-hover-open.patch"

omarchy-restart-shell 2>/dev/null || true
hyprctl reload >/dev/null 2>&1 || true
