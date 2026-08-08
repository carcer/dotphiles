#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MANIFEST="$SCRIPT_DIR/packages/npm"

if [[ ! -s "$MANIFEST" ]]; then
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is unavailable; install/activate Node before installing global tools." >&2
  exit 1
fi

# A distro npm defaults to /usr, which should not receive unmanaged global
# packages. NVM already provides a user-owned prefix and is left untouched.
global_prefix=$(npm prefix --global)
if [[ "$global_prefix" == /usr || "$global_prefix" == /usr/local ]]; then
  npm config set prefix "$HOME/.local"
fi

mapfile -t packages < <(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$MANIFEST")
((${#packages[@]})) || exit 0
npm install --global \
  --allow-scripts=@anthropic-ai/claude-code,protobufjs \
  "${packages[@]}"
