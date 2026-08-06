#!/usr/bin/env bash

set -u

OUT=${1:-"$HOME/framework-preflight-$(date +%Y%m%d-%H%M%S)"}
mkdir -p "$OUT"

run() {
  local name=$1
  shift
  { printf '> '; printf '%q ' "$@"; printf '\n'; "$@"; } >"$OUT/$name.txt" 2>&1 || true
}

run uname uname -a
run os-release cat /etc/os-release
run kernel-cmdline cat /proc/cmdline
run lsblk lsblk -p -o NAME,TRAN,HOTPLUG,RM,SIZE,MODEL,SERIAL,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS
run findmnt findmnt -R /
run blkid sudo blkid
run efibootmgr sudo efibootmgr -v
run lspci lspci -nnk
run lsusb lsusb
run network nmcli device status
run rfkill rfkill list
run failed-units systemctl --failed --no-pager
run display-manager systemctl status display-manager --no-pager
run firmware fwupdmgr get-devices
run pacman-explicit pacman -Qqe
run pacman-foreign pacman -Qqm
run npm-globals npm ls --global --depth=0
run audio wpctl status
run fingerprint-packages pacman -Q fprintd libfprint
run fingerprint-enrollments fprintd-list "$USER"
run dotfiles-status git -C "$HOME/.dotfiles" status --short --branch
run dotfiles-remotes git -C "$HOME/.dotfiles" remote -v
run dotfiles-head git -C "$HOME/.dotfiles" log -1 --oneline --decorate

cat >"$OUT/README.txt" <<EOF
Pre-install system capture generated $(date -Is).
Root filesystem: /dev/nvme0n1p3 (replace during installation).
Home filesystem: /dev/nvme0n1p4 (preserve and mount as /home; do not format).
EFI system partition: /dev/nvme0n1p1 (reuse; do not format unless explicitly required).
Fingerprint enrollments live under /var/lib/fprint and normally need re-enrollment.

This capture intentionally excludes environment variables, credential files,
browser profiles, SSH/GPG private material, tokens, and secret contents.
EOF

printf 'Capture written to %s\n' "$OUT"
