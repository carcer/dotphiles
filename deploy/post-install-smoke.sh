#!/usr/bin/env bash

set -u

check() {
  if command -v "$1" >/dev/null 2>&1; then
    printf 'OK   %-24s %s\n' "$1" "$(command -v "$1")"
  else
    printf 'MISS %-24s\n' "$1"
  fi
}

echo '== core =='
for command in sway swaymsg fuzzel kitty git ssh zsh jq curl herdr; do check "$command"; done
echo '== Wayland desktop =='
for command in wl-copy wl-paste grim slurp swayidle swaylock mako i3blocks playerctl brightnessctl pavucontrol; do check "$command"; done
echo '== development =='
for command in dotnet node npm npx docker code gh codex sechroom; do check "$command"; done
echo '== fingerprint =='
for command in fprintd-enroll fprintd-list fprintd-verify; do check "$command"; done
fprintd-list "$USER" 2>/dev/null || true
echo '== environment =='
printf 'XDG_SESSION_TYPE=%s\nWAYLAND_DISPLAY=%s\nSWAYSOCK=%s\n' \
  "${XDG_SESSION_TYPE:-unset}" "${WAYLAND_DISPLAY:-unset}" "${SWAYSOCK:-unset}"
echo '== failed systemd units =='
systemctl --failed --no-pager || true
echo '== Sway outputs and inputs =='
swaymsg -t get_outputs 2>/dev/null || true
swaymsg -t get_inputs 2>/dev/null || true
echo '== audio =='
wpctl status 2>/dev/null || true
echo '== network =='
nmcli device status 2>/dev/null || true
echo '== firmware =='
fwupdmgr get-devices 2>/dev/null || true
