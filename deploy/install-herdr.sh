#!/usr/bin/env bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v herdr >/dev/null 2>&1; then
  if [[ "$OSTYPE" == darwin* ]] && command -v brew >/dev/null 2>&1; then
    brew install herdr
  else
    installer=$(mktemp "${TMPDIR:-/tmp}/herdr-install.XXXXXX")
    trap 'rm -f -- "$installer"' EXIT
    curl --fail --silent --show-error --location https://herdr.dev/install.sh --output "$installer"
    sh "$installer"
  fi
  hash -r
fi

if ! command -v herdr >/dev/null 2>&1; then
  echo "Herdr installed but is not on PATH; restart the shell and rerun this script." >&2
  exit 1
fi

herdr integration install codex

if command -v claude >/dev/null 2>&1; then
  for profile in ocd abcs; do
    config_dir="$HOME/.claude-$profile"
    mkdir -p "$config_dir"
    CLAUDE_CONFIG_DIR="$config_dir" herdr integration install claude
  done
fi

herdr --version
