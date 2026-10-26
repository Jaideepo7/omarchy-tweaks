#!/bin/bash
# Re-apply personal tweaks after an update/resync. Safe to run repeatedly.
set -e
D="$(cd "$(dirname "$0")" && pwd)"

# Hyprland config: symlink so edits land in this repo
for f in "$D"/hypr/*.lua; do ln -sfn "$f" ~/.config/hypr/"$(basename "$f")"; done
mkdir -p ~/.local/bin
ln -sfn "$D/bin/omarchy-proportional-grow" ~/.local/bin/omarchy-proportional-grow

# Calendar plugin: fix time column overlapping the dot (skipped if already applied)
P=~/.config/omarchy/plugins/tmn73.calendar
if patch -p1 -d "$P" --dry-run -s < "$D/patches/calendar-timedrow.patch" >/dev/null 2>&1; then
  patch -p1 -d "$P" -s < "$D/patches/calendar-timedrow.patch" && echo "calendar patch applied"
else
  echo "calendar patch already applied (or plugin changed upstream)"
fi

omarchy-restart-shell 2>/dev/null || true
hyprctl reload >/dev/null 2>&1 || true
