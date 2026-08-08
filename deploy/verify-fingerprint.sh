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
echo "Fingerprint PAM for installed services is managed by deploy/configure-system.sh."
echo "Password authentication remains in each distro-provided PAM stack as fallback."
