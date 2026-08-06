#!/usr/bin/env bash

set -euo pipefail

ZSH=${ZSH:-"$HOME/.oh-my-zsh"}

if [[ -d "$ZSH/.git" ]]; then
  echo "Oh My Zsh already installed at $ZSH"
  exit 0
fi

if [[ -e "$ZSH" ]]; then
  echo "$ZSH exists but is not an Oh My Zsh Git checkout; refusing to overwrite it." >&2
  exit 1
fi

git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
echo "Oh My Zsh installed at $ZSH"
echo "dotsync manages ~/.zshrc; this installer intentionally does not replace it."
