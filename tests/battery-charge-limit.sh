#!/bin/bash
# Tests for the 80% battery charge limit (systemd-system/battery-charge-limit.service).
#   tests/battery-charge-limit.sh
set -u
D=$(cd "$(dirname "$0")/.." && pwd)
U=$D/systemd-system/battery-charge-limit.service
SYS=/etc/systemd/system/battery-charge-limit.service
THR=/sys/class/power_supply/BAT1/charge_control_end_threshold

pass=0 fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; [ -n "${2:-}" ] && echo "        $2"; }
eq()  { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$2] got [$3]"; fi; }
has() { if grep -qE -- "$2" <<<"$3"; then ok "$1"; else bad "$1" "no /$2/"; fi; }
section() { echo; echo "== $1"; }

section "unit file"
eq  "unit verifies" "" "$(systemd-analyze verify "$U" 2>&1)"
has "writes 80 to the threshold" "^ExecStart=/bin/sh -c 'echo 80 > $THR'$" "$(cat "$U")"
for t in multi-user suspend hibernate hybrid-sleep suspend-then-hibernate; do
  has "wanted by $t.target" "^WantedBy=.*\b$t\.target\b" "$(cat "$U")"
  has "ordered after $t.target" "^After=.*\b$t\.target\b" "$(cat "$U")"
done

section "install.sh"
bash -n "$D/install.sh" && ok "install.sh parses" || bad "install.sh parses"
has "installs the unit only when changed" 'cmp -s "\$D/systemd-system/battery-charge-limit.service" /etc/systemd/system/battery-charge-limit.service' "$(cat "$D/install.sh")"
has "enables the unit" 'sudo systemctl enable --now battery-charge-limit.service' "$(cat "$D/install.sh")"

section "live system"
if [ ! -e "$THR" ]; then
  echo "  skip  no charge_control_end_threshold on this machine"
else
  cmp -s "$U" "$SYS" && ok "installed unit matches dotfiles" || bad "installed unit matches dotfiles"
  eq "service enabled" enabled "$(systemctl is-enabled battery-charge-limit 2>&1)"
  eq "last run succeeded" success "$(systemctl show battery-charge-limit -p Result --value)"
  for t in multi-user suspend hibernate hybrid-sleep suspend-then-hibernate; do
    [ -L "/etc/systemd/system/$t.target.wants/battery-charge-limit.service" ] && ok "hooked into $t.target" || bad "hooked into $t.target"
  done
  eq "battery stops at 80%" 80 "$(cat "$THR")"
fi

echo; echo "$pass passed, $fail failed"
[ $fail = 0 ]
