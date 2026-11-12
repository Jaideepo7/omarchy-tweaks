#!/bin/bash
# Re-apply personal tweaks after an update/resync. Safe to run repeatedly.
set -e
D="$(cd "$(dirname "$0")" && pwd)"

# Hyprland config: symlink so edits land in this repo
for f in "$D"/hypr/*.lua; do ln -sfn "$f" ~/.config/hypr/"$(basename "$f")"; done
mkdir -p ~/.local/bin
ln -sfn "$D/bin/omarchy-proportional-grow" ~/.local/bin/omarchy-proportional-grow
ln -sfn "$D/bin/omarchy-plugin-sync" ~/.local/bin/omarchy-plugin-sync
ln -sfn "$D/bin/nvidia-gate" ~/.local/bin/nvidia-gate

# NVIDIA gate: new apps may use the dGPU only on a >=65W charger
mkdir -p ~/.config/systemd/user
ln -sfn "$D/systemd/nvidia-gate.service" ~/.config/systemd/user/nvidia-gate.service
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now nvidia-gate.service 2>/dev/null || true

# Battery: stop charging at 80% (system unit, reapplied at boot and after sleep).
# Copied, not symlinked: system units shouldn't live in a user-writable repo.
if ! cmp -s "$D/systemd-system/battery-charge-limit.service" /etc/systemd/system/battery-charge-limit.service; then
  sudo install -m 644 "$D/systemd-system/battery-charge-limit.service" /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now battery-charge-limit.service
fi

# WirePlumber: Bluetooth software volume + A2DP auto-connect, KEF USB no-suspend
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
for f in "$D"/wireplumber/*.conf; do ln -sfn "$f" ~/.config/wireplumber/wireplumber.conf.d/"$(basename "$f")"; done

# Whole plugins I wrote myself (copied in, not symlinked: the shell only scans
# real directories under ~/.config/omarchy/plugins)
for p in "$D"/plugins/*/; do
  name=$(basename "$p")
  mkdir -p ~/.config/omarchy/plugins/"$name"
  cp -r "$p". ~/.config/omarchy/plugins/"$name"/
done

# My clones of built-in plugins (jaideep.*) are git repos (stock/main branches)
# kept in step with Omarchy by omarchy-plugin-sync, which also runs from the
# post-update/post-boot hooks. The calendar fix lives as a local commit in its repo.
command -v omarchy-plugin-sync >/dev/null && omarchy-plugin-sync || true

omarchy-restart-shell 2>/dev/null || true
hyprctl reload >/dev/null 2>&1 || true
systemctl --user restart wireplumber 2>/dev/null || true
