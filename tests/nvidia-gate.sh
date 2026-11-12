#!/bin/bash
# Tests for the NVIDIA charger gate: bin/nvidia-gate, systemd/nvidia-gate.service,
# the gate block in hypr/hyprland.lua and the install.sh wiring.
#
#   tests/nvidia-gate.sh        logic + config + live-install checks (no GPU wake-ups)
#   tests/nvidia-gate.sh --hw   also exercise the real Vulkan/EGL loaders and the dGPU
#                               (briefly wakes the RTX 4060)
#
# The logic tests use a fake /sys/class/power_supply tree and a temporary gate dir
# (NVIDIA_GATE_PS / NVIDIA_GATE_DIR), so they never touch the real gate.
set -u
D=$(cd "$(dirname "$0")/.." && pwd)
BIN=$D/bin/nvidia-gate
HW=0; [ "${1:-}" = --hw ] && HW=1
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
EGL_D=/usr/share/glvnd/egl_vendor.d
VK_D=/usr/share/vulkan/icd.d

pass=0 fail=0
ok()   { pass=$((pass+1)); echo "  ok    $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL  $1"; [ -n "${2:-}" ] && echo "        $2"; }
eq()   { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$2] got [$3]"; fi; }
has()  { if grep -qE -- "$2" <<<"$3"; then ok "$1"; else bad "$1" "no /$2/ in: $(tr '\n' '|' <<<"$3")"; fi; }
hasnt(){ if grep -qE -- "$2" <<<"$3"; then bad "$1" "unexpected /$2/ in: $(tr '\n' '|' <<<"$3")"; else ok "$1"; fi; }
section() { echo; echo "== $1"; }

# Stub notify-send so notifications are recorded, not shown.
STUB=$T/stub; mkdir -p "$STUB"
cat > "$STUB/notify-send" <<EOF
#!/bin/bash
shift 2  # drop "-a nvidia-gate"
echo "\$1" >> "$T/notify.log"
EOF
chmod +x "$STUB/notify-send"
export PATH="$STUB:$PATH"

# [CM=n] fake_ps NAME ACAD BAT_STATUS [UCSI_SPEC...]   UCSI_SPEC = online:microvolts:microamps
# CM sets the fake ASUS firmware charge_mode (unset = attribute missing).
fake_ps() {
  local root=$T/ps/$1 acad=$2 bat=$3 i=1 spec; shift 3
  mkdir -p "$root/ACAD" "$root/BAT1"
  echo "$acad" > "$root/ACAD/online"; echo "$bat" > "$root/BAT1/status"
  [ -n "${CM:-}" ] && echo "$CM" > "$root/charge_mode"
  for spec in "$@"; do
    local s=$root/ucsi-source-psy-USBC000:00$i; mkdir -p "$s"
    IFS=: read -r on uv ua <<<"$spec"
    echo "$on" > "$s/online"; echo "$uv" > "$s/voltage_max"; echo "$ua" > "$s/current_max"
    i=$((i+1))
  done
  echo "$root"
}
# Every call points charge_mode at the fake tree, never the real firmware.
watts() { NVIDIA_GATE_PS=$1 NVIDIA_GATE_CHARGE_MODE=$1/charge_mode NVIDIA_GATE_DIR=$T/unused "$BIN" status | sed -n 's/^charger: \([0-9]*\)W.*/\1/p'; }
gate()  { NVIDIA_GATE_PS=$1 NVIDIA_GATE_CHARGE_MODE=$1/charge_mode NVIDIA_GATE_DIR=$2 "$BIN" "${@:3}"; }
gstate(){ gate "$1" "$2" status | sed -n 's/^gate: *//p'; }

section "script basics"
bash -n "$BIN" && ok "bin/nvidia-gate parses" || bad "bin/nvidia-gate parses"
[ -x "$BIN" ] && ok "bin/nvidia-gate is executable" || bad "bin/nvidia-gate is executable"
"$BIN" bogus >/dev/null 2>&1; eq "unknown subcommand exits 2" 2 $?
"$BIN" run >/dev/null 2>&1;   eq "'run' without a command exits 2" 2 $?

section "charger detection"
eq "battery only -> 0 W"                         0   "$(watts "$(fake_ps bat 0 Discharging)")"
eq "barrel (ACAD) -> 200 W"                      200 "$(watts "$(fake_ps barrel 1 Charging)")"
eq "USB-C 20V 3.25A -> 65 W"                     65  "$(watts "$(fake_ps c65 1 Charging 1:20000000:3250000)")"
eq "USB-C 20V 3A -> 60 W"                        60  "$(watts "$(fake_ps c60 1 Charging 1:20000000:3000000)")"
eq "USB-C 15V 3A -> 45 W"                        45  "$(watts "$(fake_ps c45 1 Charging 1:15000000:3000000)")"
eq "USB-C 20V 5A -> 100 W"                       100 "$(watts "$(fake_ps c100 1 Charging 1:20000000:5000000)")"
eq "USB-C counts with ACAD off if not discharging" 65 "$(watts "$(fake_ps cnoacad 0 Charging 1:20000000:3250000)")"
eq "stale USB-C (ACAD off, discharging) ignored" 0   "$(watts "$(fake_ps stale 0 Discharging 1:20000000:5000000)")"
eq "offline USB-C port ignored"                  0   "$(watts "$(fake_ps off 0 Discharging 0:20000000:5000000)")"
eq "two USB-C ports -> highest wins"             100 "$(watts "$(fake_ps two 1 Charging 1:15000000:3000000 1:20000000:5000000)")"
eq "USB-C still negotiating (0V) + ACAD -> barrel" 200 "$(watts "$(fake_ps nego 1 Charging 1:0:0)")"
eq "missing sysfs files -> 0 W, no errors"       0   "$(watts "$T/ps/does-not-exist" 2>&1)"

section "firmware charge_mode"
eq "mode 1 (barrel) -> 200 W"                      200 "$(watts "$(CM=1 fake_ps m1 1 Charging)")"
eq "mode 1 ignores glitchy 60 W USB-C reading"     200 "$(watts "$(CM=1 fake_ps m1g 1 Charging 1:20000000:3000000)")"
eq "mode 3 (both, barrel used) -> 200 W"           200 "$(watts "$(CM=3 fake_ps m3 1 Charging 1:20000000:3000000)")"
eq "mode 2, 65 W USB-C -> 65 W"                    65  "$(watts "$(CM=2 fake_ps m2a 1 Charging 1:20000000:3250000)")"
eq "mode 2, 60 W USB-C -> 60 W"                    60  "$(watts "$(CM=2 fake_ps m2b 1 Charging 1:20000000:3000000)")"
eq "mode 2, UCSI silent -> 0 W (not mistaken for barrel)" 0 "$(watts "$(CM=2 fake_ps m2c 1 Charging)")"
eq "mode 0 + ACAD online (firmware lagging) -> sysfs fallback" 200 "$(watts "$(CM=0 fake_ps m0 1 Charging)")"
eq "mode 0 + battery -> 0 W"                       0   "$(watts "$(CM=0 fake_ps m0b 0 Discharging)")"

section "USB-C wattage memory (UCSI timeouts)"
G=$T/gate_sticky; SP=$(CM=2 fake_ps sticky 1 Charging 1:20000000:3250000)
gate "$SP" "$G" >/dev/null
eq "65 W USB-C seen: allowed" allow "$(gstate "$SP" "$G")"
echo 0 > "$SP/ucsi-source-psy-USBC000:001/online"   # UCSI times out, reading lost
gate "$SP" "$G" >/dev/null
eq "UCSI drops the reading: stays allowed" allow "$(gstate "$SP" "$G")"
eq "remembered wattage shown" 65 "$(gate "$SP" "$G" status | sed -n 's/^charger: \([0-9]*\)W.*/\1/p')"
echo 0 > "$SP/charge_mode"; echo 0 > "$SP/ACAD/online"; echo Discharging > "$SP/BAT1/status"
gate "$SP" "$G" >/dev/null
eq "unplug: blocked" block "$(gstate "$SP" "$G")"
[ -e "$G/usbc_watts" ] && bad "memory cleared on unplug" || ok "memory cleared on unplug"
echo 2 > "$SP/charge_mode"; echo 1 > "$SP/ACAD/online"; echo Charging > "$SP/BAT1/status"
gate "$SP" "$G" >/dev/null
eq "new USB-C plug with silent UCSI: not allowed from old memory" block "$(gstate "$SP" "$G")"

section "gate directory"
G=$T/gate1; BATPS=$(fake_ps g_bat 0 Discharging); ACPS=$(fake_ps g_ac 1 Charging)
C65=$(fake_ps g_c65 1 Charging 1:20000000:3250000); C60=$(fake_ps g_c60 1 Charging 1:20000000:3000000)
: > "$T/notify.log"
gate "$BATPS" "$G" >/dev/null
eq "fresh gate on battery: blocked"            "block" "$(gate "$BATPS" "$G" status | sed -n 's/^gate: *//p')"
eq "mesa EGL manifest linked"   "$EGL_D/50_mesa.json"   "$(readlink "$G/egl/50_mesa.json")"
eq "radeon Vulkan manifest linked" "$VK_D/radeon_icd.json" "$(readlink "$G/vulkan/radeon_icd.json")"
[ -e "$G/egl/10_nvidia.json" ] || [ -e "$G/vulkan/nvidia_icd.json" ] && bad "no NVIDIA manifests when blocked" || ok "no NVIDIA manifests when blocked"
eq "no notification when state unchanged" 0 "$(wc -l < "$T/notify.log")"

gate "$C65" "$G" >/dev/null
eq "65 W USB-C: allowed" "allow" "$(gate "$C65" "$G" status | sed -n 's/^gate: *//p')"
eq "NVIDIA EGL manifest linked"    "$EGL_D/10_nvidia.json" "$(readlink "$G/egl/10_nvidia.json")"
eq "NVIDIA Vulkan manifest linked" "$VK_D/nvidia_icd.json" "$(readlink "$G/vulkan/nvidia_icd.json")"
[ -e "$G/egl/10_nvidia.json" ] && [ -e "$G/vulkan/nvidia_icd.json" ] && ok "NVIDIA links resolve" || bad "NVIDIA links resolve"
eq "notified 'available'" "NVIDIA GPU available" "$(tail -1 "$T/notify.log")"

gate "$C65" "$G" >/dev/null
eq "re-apply while allowed: no extra notification" 1 "$(wc -l < "$T/notify.log")"

gate "$C60" "$G" >/dev/null
eq "60 W USB-C: blocked" "block" "$(gate "$C60" "$G" status | sed -n 's/^gate: *//p')"
[ -e "$G/egl/10_nvidia.json" ] || [ -e "$G/vulkan/nvidia_icd.json" ] && bad "NVIDIA manifests removed" || ok "NVIDIA manifests removed"
[ -e "$G/egl/50_mesa.json" ] && [ -e "$G/vulkan/radeon_icd.json" ] && ok "AMD manifests kept" || bad "AMD manifests kept"
eq "notified 'blocked'" "NVIDIA GPU blocked" "$(tail -1 "$T/notify.log")"

gate "$ACPS" "$G" >/dev/null; eq "barrel charger: allowed" "allow" "$(gate "$ACPS" "$G" status | sed -n 's/^gate: *//p')"
gate "$BATPS" "$G" >/dev/null; eq "unplug: blocked"         "block" "$(gate "$BATPS" "$G" status | sed -n 's/^gate: *//p')"
eq "threshold override (NVIDIA_GATE_MIN_W=60) allows 60 W" "allow" \
  "$(NVIDIA_GATE_MIN_W=60 gate "$C60" "$G" >/dev/null; gate "$C60" "$G" status | sed -n 's/^gate: *//p')"
gate "$BATPS" "$G" >/dev/null

section "watch mode (stubbed udev events)"
G=$T/gate2; W=$(fake_ps watch 0 Discharging); : > "$T/notify.log"
cat > "$STUB/udevadm" <<EOF
#!/bin/bash
sleep 0.6
echo 1 > "$W/ACAD/online"; echo Charging > "$W/BAT1/status"
echo "UDEV  [1.0] change   /devices/LNXSYSTM:00/ACPI0003:00/power_supply/ACAD (power_supply)"
sleep 0.6
echo 0 > "$W/ACAD/online"; echo Discharging > "$W/BAT1/status"
echo "KERNEL[2.0] change   /devices/LNXSYSTM:00/ACPI0003:00/power_supply/ACAD (power_supply)"
sleep 0.6
echo "UDEV  [2.1] change   /devices/LNXSYSTM:00/ACPI0003:00/power_supply/ACAD (power_supply)"
sleep 0.6
EOF
chmod +x "$STUB/udevadm"
watch_env() { echo NVIDIA_GATE_SETTLE=$1 NVIDIA_GATE_PS=$2 NVIDIA_GATE_CHARGE_MODE=$2/charge_mode NVIDIA_GATE_DIR=$3; }
out=$(timeout 10 env $(watch_env 0.2 "$W" "$G") "$BIN" watch); rc=$?
eq "watch exits cleanly when udev stream ends" 0 $rc
has "announces initial state" "^charger 0W -> NVIDIA blocked" "$(head -1 <<<"$out")"
eq "reacts to plug, ignores KERNEL line, reacts to unplug" \
  "NVIDIA GPU available|NVIDIA GPU blocked" "$(paste -sd'|' "$T/notify.log")"
eq "ends blocked" "block" "$(gstate "$W" "$G")"

# A plug-in burst that flaps within the settle window gives one decision.
G=$T/gate_burst; W=$(fake_ps burst 0 Discharging); : > "$T/notify.log"
{ echo '#!/bin/bash'
  echo 'sleep 0.3'
  for v in 1 0 1 0 1; do
    echo "echo $v > '$W/ACAD/online'; echo 'UDEV  [1.0] change /power_supply/ACAD (power_supply)'; sleep 0.05"
  done
  echo 'sleep 0.8'; } > "$STUB/udevadm"
chmod +x "$STUB/udevadm"
timeout 10 env $(watch_env 0.3 "$W" "$G") "$BIN" watch >/dev/null
eq "flapping burst -> exactly one notification" "NVIDIA GPU available" "$(paste -sd'|' "$T/notify.log")"
eq "burst ends allowed" allow "$(gstate "$W" "$G")"
rm "$STUB/udevadm"

section "run subcommand"
out=$(__EGL_VENDOR_LIBRARY_DIRS=x __EGL_VENDOR_LIBRARY_FILENAMES=y VK_DRIVER_FILES=z "$BIN" run env)
hasnt "clears gate env vars" "^(__EGL_VENDOR_LIBRARY_DIRS|__EGL_VENDOR_LIBRARY_FILENAMES|VK_DRIVER_FILES)=" "$out"
has   "sets PRIME offload"   "^__NV_PRIME_RENDER_OFFLOAD=1$" "$out"
has   "selects NVIDIA GLX"   "^__GLX_VENDOR_LIBRARY_NAME=nvidia$" "$out"
has   "selects NVIDIA Vulkan" "^__VK_LAYER_NV_optimus=NVIDIA_only$" "$out"
eq "passes arguments through" "a b" "$("$BIN" run echo a b)"

section "hyprland.lua gate block"
L=$D/hypr/hyprland.lua
has "keeps GLX on mesa"     'hl.env\("__GLX_VENDOR_LIBRARY_NAME", "mesa"\)' "$(cat "$L")"
has "keeps VA-API on radeonsi" 'hl.env\("LIBVA_DRIVER_NAME", "radeonsi"\)' "$(cat "$L")"
hasnt "no stale prime-run advice" 'prime-run' "$(cat "$L")"
awk '/^local nvidia_gate/{p=1} p{print} p&&/^end/{exit}' "$L" > "$T/block.lua"
[ -s "$T/block.lua" ] && ok "gate block extracted" || bad "gate block extracted"
runlua() { HOME=$1 lua -e 'hl={env=function(k,v) print(k.."="..v) end}' "$T/block.lua"; }
mkdir -p "$T/home1/.local/state/nvidia-gate/egl"; touch "$T/home1/.local/state/nvidia-gate/egl/50_mesa.json"
out=$(runlua "$T/home1")
eq "gate present: EGL dirs" "__EGL_VENDOR_LIBRARY_DIRS=$T/home1/.local/state/nvidia-gate/egl" "$(grep EGL <<<"$out")"
eq "gate present: Vulkan dir" "VK_DRIVER_FILES=$T/home1/.local/state/nvidia-gate/vulkan" "$(grep VK <<<"$out")"
out=$(runlua "$T/home2")
eq "gate missing: EGL falls back to mesa only" "__EGL_VENDOR_LIBRARY_FILENAMES=$EGL_D/50_mesa.json" "$(grep EGL <<<"$out")"
eq "gate missing: Vulkan falls back to radeon only" "VK_DRIVER_FILES=$VK_D/radeon_icd.json" "$(grep VK <<<"$out")"
if command -v hyprctl >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  eq "live Hyprland config has no errors" "" "$(hyprctl configerrors | grep -v '^$')"
fi

section "systemd unit + install.sh"
U=$D/systemd/nvidia-gate.service
v=$(systemd-analyze --user verify "$U" 2>&1); eq "unit verifies" "" "$v"
has "unit runs 'nvidia-gate watch'" '^ExecStart=%h/.local/bin/nvidia-gate watch$' "$(cat "$U")"
has "unit restarts on failure" '^Restart=on-failure$' "$(cat "$U")"
has "unit tied to graphical session" '^WantedBy=graphical-session.target$' "$(cat "$U")"
bash -n "$D/install.sh" && ok "install.sh parses" || bad "install.sh parses"
has "install.sh links the script"  'ln -sfn "\$D/bin/nvidia-gate" ~/.local/bin/nvidia-gate' "$(cat "$D/install.sh")"
has "install.sh links the unit"    'nvidia-gate.service" ~/.config/systemd/user/nvidia-gate.service' "$(cat "$D/install.sh")"
has "install.sh enables the unit"  'enable --now nvidia-gate.service' "$(cat "$D/install.sh")"

section "live install"
eq "~/.local/bin/nvidia-gate -> dotfiles" "$BIN" "$(readlink ~/.local/bin/nvidia-gate)"
eq "unit symlink -> dotfiles" "$U" "$(readlink ~/.config/systemd/user/nvidia-gate.service)"
eq "service enabled" enabled "$(systemctl --user is-enabled nvidia-gate 2>&1)"
eq "service active"  active  "$(systemctl --user is-active nvidia-gate 2>&1)"
live=$(nvidia-gate status)
w=$(sed -n 's/^charger: \([0-9]*\)W.*/\1/p' <<<"$live"); st=$(sed -n 's/^gate: *//p' <<<"$live")
exp=block; (( w >= 65 )) && exp=allow
eq "real gate matches real charger (${w} W)" "$exp" "$st"
env_now=$(systemctl --user show-environment)
has   "session env points EGL at gate"    "^__EGL_VENDOR_LIBRARY_DIRS=$HOME/.local/state/nvidia-gate/egl$" "$env_now"
has   "session env points Vulkan at gate" "^VK_DRIVER_FILES=$HOME/.local/state/nvidia-gate/vulkan$" "$env_now"
hasnt "session env has no overriding EGL filenames" "^__EGL_VENDOR_LIBRARY_FILENAMES=" "$env_now"

if [ $HW = 1 ]; then
  section "hardware: real Vulkan/EGL loaders (wakes the dGPU briefly)"
  cat > "$T/egl.py" <<'EOF'
import ctypes
egl = ctypes.CDLL("libEGL.so.1"); egl.eglGetDisplay.restype = ctypes.c_void_p
egl.eglInitialize(ctypes.c_void_p(egl.eglGetDisplay(ctypes.c_void_p(0))), None, None)
print(" ".join(sorted({l.split()[-1].rsplit('/',1)[-1] for l in open('/proc/self/maps') if 'libEGL_' in l})))
EOF
  probe() {  # probe GATEDIR -> "vulkan devices | egl vendors"
    local vk egl
    vk=$(env -u __EGL_VENDOR_LIBRARY_FILENAMES __EGL_VENDOR_LIBRARY_DIRS="$1/egl" VK_DRIVER_FILES="$1/vulkan" \
         vulkaninfo --summary 2>/dev/null | sed -n 's/.*deviceName *= *//p' | paste -sd,)
    egl=$(env -u __EGL_VENDOR_LIBRARY_FILENAMES __EGL_VENDOR_LIBRARY_DIRS="$1/egl" WAYLAND_DISPLAY= python3 -I "$T/egl.py")
    echo "$vk | $egl"
  }
  G=$T/gate3
  gate "$BATPS" "$G" >/dev/null; out=$(probe "$G")
  has   "blocked: Vulkan sees the AMD 890M" "Radeon 890M" "$out"
  hasnt "blocked: Vulkan does not see NVIDIA" "NVIDIA" "$out"
  has   "blocked: EGL loads mesa" "libEGL_mesa" "$out"
  hasnt "blocked: EGL does not load NVIDIA" "libEGL_nvidia" "$out"
  gate "$ACPS" "$G" >/dev/null; out=$(probe "$G")
  has "allowed: Vulkan sees NVIDIA" "NVIDIA GeForce RTX 4060" "$out"
  has "allowed: Vulkan still sees AMD" "Radeon 890M" "$out"
  has "allowed: EGL loads NVIDIA" "libEGL_nvidia" "$out"
  out=$(__EGL_VENDOR_LIBRARY_DIRS="$T/gate1/egl" VK_DRIVER_FILES="$T/gate1/vulkan" "$BIN" run vulkaninfo --summary 2>/dev/null)
  has "'run' reaches NVIDIA through a blocked gate" "NVIDIA GeForce RTX 4060" "$out"

  section "hardware: dGPU goes back to sleep"
  s=; for _ in $(seq 30); do s=$(cat /sys/bus/pci/devices/0000:64:00.0/power/runtime_status); [ "$s" = suspended ] && break; sleep 1; done
  eq "dGPU runtime-suspends within 30 s" suspended "$s"
fi

echo; echo "$pass passed, $fail failed"
[ $fail = 0 ]
