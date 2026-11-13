#!/bin/bash
# Frosted glass for Omarchy's shell: notifications, bar panels, menus, the app
# launcher and pop-ups become rounded, see-through frosted cards that take every
# colour from the current theme. See "Frosted glass" in the README.
#
# For each patch in patches/glass/, this clones the built-in plugin if you use
# it and have no clone yet, copies in GlassCard.qml, and applies the patch.
# Running it again is safe: patches already applied are skipped.
set -uo pipefail

D=$(cd "$(dirname "$0")/.." && pwd)
P=~/.config/omarchy/plugins
U=${USER:-$(id -un)}

enabled() {
  omarchy-plugin-list --json 2>/dev/null | jq -e --arg id "$1" 'any(.[]; .id == $id and .enabled)' >/dev/null
}

for patch in "$D"/patches/glass/*.patch; do
  name=$(basename "$patch" .patch)

  if [[ $name == calendar ]]; then
    dir=$P/tmn73.calendar
    [[ -d $dir ]] || { echo "skip    calendar (tmn73.calendar not installed)"; continue; }
  else
    dir=$P/$U.$name
    if [[ ! -d $dir ]]; then
      # Only clone what you use: cloning also switches the shell to the clone.
      if ! enabled "omarchy.$name"; then echo "skip    $name (not in use)"; continue; fi
      omarchy plugin clone "omarchy.$name" >/dev/null || { echo "FAILED  $name (clone)"; continue; }
    fi
  fi

  cp "$D/glass/GlassCard.qml" "$dir/"
  if patch -p1 -R --dry-run -s -f -d "$dir" <"$patch" >/dev/null 2>&1; then
    echo "already $name"
  elif patch -p1 --dry-run -s -f -d "$dir" <"$patch" >/dev/null 2>&1; then
    patch -p1 -s -d "$dir" <"$patch" && echo "applied $name"
  else
    echo "FAILED  $name (its files have drifted from the patch; apply it by hand)"
  fi
done

# Hyprland only blurs layers it is told to. Omarchy's Glassy windows mode
# covers most shell layers but not the app launcher, so add one rule for all.
conf=~/.config/hypr/looknfeel.lua
if [[ -f $conf ]] && ! grep -q '>>> omarchy-tweaks glass >>>' "$conf"; then
  cat >>"$conf" <<'EOF'

-- >>> omarchy-tweaks glass >>>
-- Blur behind the shell's frosted glass cards (glass/apply.sh). ignore_alpha
-- 0.3 keeps fully see-through pixels sharp; the cards stay above it.
hl.layer_rule({
  match = { namespace = "^(omarchy-notifications|omarchy-keyboard-panel|omarchy-menu|omarchy-dock-apps|omarchy-clipboard|omarchy-emojis|omarchy-reminders|omarchy-polkit|omarchy-osd)$" },
  blur = true,
  ignore_alpha = 0.3,
})
-- <<< omarchy-tweaks glass <<<
EOF
  echo "added   blur rule to $conf"
  hyprctl reload >/dev/null 2>&1 || true
fi

omarchy restart shell >/dev/null 2>&1 || true
