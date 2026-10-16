#!/usr/bin/env bash
# Add the Chaotic-AUR repository (prebuilt AUR packages) and install the
# packages listed in packages/chaotic-aur from it, as on sc-dev-01. Run by
# deploy/linux when the host profile sets DOTPHILES_CHAOTIC_AUR=1. Needs sudo;
# safe to rerun.
#
# Steps follow https://aur.chaotic.cx (key 3056513887B78AEB). The repo goes last
# in pacman.conf, as on sc-dev-01, so it never shadows the CachyOS or Arch
# repos. Packages that exist in both (the .NET -bin set) are installed by
# naming the repo explicitly (chaotic-aur/<pkg>), because CachyOS ships older
# builds under the same names.

set -euo pipefail
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MANIFEST="$DIR/packages/chaotic-aur"

if ! pacman -Q chaotic-keyring chaotic-mirrorlist >/dev/null 2>&1; then
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
fi

if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
  printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
fi
sudo pacman -Sy

mapfile -t packages < <(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$MANIFEST")
((${#packages[@]})) || exit 0
# Install from chaotic-aur even when a same-named package from another repo
# (or the AUR) is installed, so the whole set comes from one build.
sudo pacman -S --noconfirm "${packages[@]/#/chaotic-aur/}"
