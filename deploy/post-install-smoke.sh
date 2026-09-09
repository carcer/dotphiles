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
echo '== host profile =='
# shellcheck source=hosts/load.sh
source "$(cd "$(dirname "$0")" && pwd)/hosts/load.sh" 2>/dev/null || true
printf 'host=%s role=%s fingerprint=%s mt7925=%s herdr-server=%s sshd=%s\n' \
  "${DOTPHILES_HOST:-?}" "${DOTPHILES_ROLE:-?}" "${DOTPHILES_FINGERPRINT:-?}" \
  "${DOTPHILES_MT7925_BT:-?}" "${DOTPHILES_HERDR_SERVER:-?}" "${DOTPHILES_SSHD:-?}"
printf 'sway host.conf -> %s\n' "$(readlink "$HOME/.config/sway/host.conf" 2>/dev/null || echo 'missing')"
if [[ "${DOTPHILES_HERDR_SERVER:-0}" == 1 ]]; then
  printf 'herdr-server (user): %s\n' "$(systemctl --user is-active herdr-server.service 2>/dev/null || echo unknown)"
  herdr status 2>/dev/null | sed -n '/^server:/,/^$/p' || true
fi
if [[ "${DOTPHILES_SSHD:-0}" == 1 ]]; then
  printf 'sshd: %s\n' "$(systemctl is-active sshd 2>/dev/null || echo unknown)"
fi
if [[ "${DOTPHILES_ROLE:-laptop}" == host ]]; then
  echo 'logind lid/idle policy (expect ignore):'
  loginctl show-logind 2>/dev/null | grep -Ei 'HandleLidSwitch|IdleAction' || true
fi
if [[ "${DOTPHILES_FINGERPRINT:-0}" == 1 ]]; then
  echo '== fingerprint =='
  for command in fprintd-enroll fprintd-list fprintd-verify; do check "$command"; done
  fprintd-list "$USER" 2>/dev/null || true
fi
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
