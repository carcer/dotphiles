#!/usr/bin/env bash

set -euo pipefail

for command in fprintd-enroll fprintd-list fprintd-verify; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "$command is missing; install fprintd first." >&2
    exit 1
  }
done

echo "Existing enrollments for $USER:"
fprintd-list "$USER" || true
echo
echo "If no prints are listed, run: fprintd-enroll"
echo "Then verify with: fprintd-verify"
echo
echo "PAM configuration is intentionally not rewritten automatically."
echo "Confirm password authentication remains available before enabling fingerprint PAM."
