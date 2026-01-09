#!/bin/bash
# Backup current PAM configurations before modification
#
# This script creates backups of PAM config files that will be modified
# for fingerprint authentication. Backups are timestamped and stored in
# the backup directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup"
PAM_DIR="/etc/pam.d"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root"
    echo "Usage: sudo $0"
    exit 1
fi

# Create backup directories
mkdir -p "$BACKUP_DIR/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "=== PAM Configuration Backup ==="
echo "Timestamp: $TIMESTAMP"
echo "Backup location: $BACKUP_DIR/$TIMESTAMP"
echo ""

# List of PAM configs to backup
CONFIGS=(
    "system-auth"
    "sudo"
    "i3lock"
    "polkit-1"
    "lightdm"
    "system-login"
    "system-local-login"
)

# Backup each config
BACKED_UP=0
SKIPPED=0

for config in "${CONFIGS[@]}"; do
    if [[ -f "$PAM_DIR/$config" ]]; then
        echo "Backing up: $config"
        cp "$PAM_DIR/$config" "$BACKUP_DIR/$TIMESTAMP/"

        # Also create/update the .original backup if it doesn't exist
        if [[ ! -f "$BACKUP_DIR/$config.original" ]]; then
            echo "  → Creating .original backup: $config.original"
            cp "$PAM_DIR/$config" "$BACKUP_DIR/$config.original"
        fi

        ((BACKED_UP++))
    else
        echo "Skipping (not found): $config"
        ((SKIPPED++))
    fi
done

echo ""
echo "=== Backup Complete ==="
echo "Files backed up: $BACKED_UP"
echo "Files skipped: $SKIPPED"
echo ""
echo "Backups stored in:"
echo "  - Timestamped: $BACKUP_DIR/$TIMESTAMP/"
echo "  - Originals: $BACKUP_DIR/*.original"
echo ""
echo "To restore from this backup:"
echo "  sudo cp $BACKUP_DIR/$TIMESTAMP/* /etc/pam.d/"
echo ""
