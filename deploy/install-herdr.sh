#!/usr/bin/env bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if ! command -v herdr >/dev/null 2>&1; then
  installer=$(mktemp "${TMPDIR:-/tmp}/herdr-install.XXXXXX")
  trap 'rm -f -- "$installer"' EXIT
  curl --fail --silent --show-error --location https://herdr.dev/install.sh --output "$installer"
  sh "$installer"
  hash -r
fi

if ! command -v herdr >/dev/null 2>&1; then
  echo "Herdr installed but is not on PATH; restart the shell and rerun this script." >&2
  exit 1
fi

for integration in codex claude; do
  herdr integration install "$integration"
done

herdr --version
