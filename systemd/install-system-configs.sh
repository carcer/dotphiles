#!/bin/bash
# Install systemd configs that live outside $HOME (require sudo).
#
# Copies:
#   system-sleep/10-wifi-suspend.sh → /etc/systemd/system-sleep/
#   system/mt7925-bt-init.service   → /etc/systemd/system/  (and enables it)
#
# Re-run after editing the repo copies to push changes into /etc.
#
# Usage:
#   sudo ./install-system-configs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backup"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: must be run as root${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

install_file() {
    local src="$1"
    local dst="$2"
    local mode="$3"

    if [[ ! -f "$src" ]]; then
        echo -e "${YELLOW}WARNING: source not found: $src${NC}"
        return 1
    fi

    local name
    name="$(basename "$dst")"

    echo -e "${GREEN}Installing:${NC} $dst"

    if [[ -f "$dst" ]] && [[ ! -f "$BACKUP_DIR/$name.original" ]]; then
        echo "  → backup: $BACKUP_DIR/$name.original"
        cp "$dst" "$BACKUP_DIR/$name.original"
    fi

    install -D -m "$mode" -o root -g root "$src" "$dst"
    echo -e "${GREEN}  ✓ installed${NC}"
}

install_file \
    "$SCRIPT_DIR/system-sleep/10-wifi-suspend.sh" \
    "/etc/systemd/system-sleep/10-wifi-suspend.sh" \
    755

install_file \
    "$SCRIPT_DIR/system/mt7925-bt-init.service" \
    "/etc/systemd/system/mt7925-bt-init.service" \
    644

echo ""
echo "Reloading systemd and enabling mt7925-bt-init.service..."
systemctl daemon-reload
systemctl enable mt7925-bt-init.service

echo ""
echo -e "${GREEN}=== Done ===${NC}"
echo ""
echo "Verify after next cold boot:"
echo "  systemctl status mt7925-bt-init.service"
echo "  bluetoothctl show"
echo ""
echo "Backups stored in: $BACKUP_DIR/"
