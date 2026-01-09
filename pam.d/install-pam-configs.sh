#!/bin/bash
# Install PAM configurations for fingerprint authentication
#
# This script installs PAM configuration templates to /etc/pam.d/ with
# proper permissions. It creates backups before overwriting and can install
# all configs or specific ones.
#
# Usage:
#   sudo ./install-pam-configs.sh              # Install all configs
#   sudo ./install-pam-configs.sh system-auth  # Install specific config
#   sudo ./install-pam-configs.sh polkit-1     # Install specific config

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
BACKUP_DIR="$SCRIPT_DIR/backup"
PAM_DIR="/etc/pam.d"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Usage: sudo $0 [config-name]"
    exit 1
fi

# Check if templates directory exists
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo -e "${RED}ERROR: Templates directory not found: $TEMPLATE_DIR${NC}"
    exit 1
fi

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to backup and install a PAM config
install_pam_config() {
    local config="$1"
    local template="$TEMPLATE_DIR/$config"
    local target="$PAM_DIR/$config"

    # Check if template exists
    if [[ ! -f "$template" ]]; then
        echo -e "${YELLOW}WARNING: Template not found: $template${NC}"
        return 1
    fi

    echo -e "${GREEN}Installing:${NC} $config"

    # Backup original if exists and not already backed up
    if [[ -f "$target" ]] && [[ ! -f "$BACKUP_DIR/$config.original" ]]; then
        echo "  → Creating backup: $config.original"
        cp "$target" "$BACKUP_DIR/$config.original"
    elif [[ -f "$target" ]]; then
        echo "  → Backup already exists: $config.original"
    else
        echo "  → No existing config to backup (creating new file)"
    fi

    # Install new config
    echo "  → Copying template to $target"
    cp "$template" "$target"
    chown root:root "$target"
    chmod 644 "$target"

    echo -e "${GREEN}  ✓ Installed successfully${NC}"
    echo ""

    return 0
}

# Main installation logic
echo "=== PAM Fingerprint Configuration Installer ==="
echo ""

# Check if specific config was requested
if [[ $# -eq 1 ]]; then
    CONFIG_TO_INSTALL="$1"
    echo "Installing specific config: $CONFIG_TO_INSTALL"
    echo ""

    if install_pam_config "$CONFIG_TO_INSTALL"; then
        echo -e "${GREEN}=== Installation Complete ===${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Test authentication in a NEW terminal (keep this one open!)"
        echo "  2. Verify fingerprint works: fprintd-verify"
        echo ""
        echo "To rollback:"
        echo "  sudo cp $BACKUP_DIR/$CONFIG_TO_INSTALL.original $PAM_DIR/$CONFIG_TO_INSTALL"
    else
        echo -e "${RED}=== Installation Failed ===${NC}"
        exit 1
    fi
else
    # Install all configs
    echo "Installing all PAM configs..."
    echo ""

    CONFIGS=(
        "polkit-1"      # Install low-risk first
        "i3lock"        # Screen locker (low-risk if exists)
        "system-auth"   # Core config (higher risk)
    )

    INSTALLED=0
    FAILED=0

    for config in "${CONFIGS[@]}"; do
        if install_pam_config "$config"; then
            ((INSTALLED++))
        else
            ((FAILED++))
        fi
    done

    echo "=== Installation Summary ==="
    echo -e "${GREEN}Successfully installed: $INSTALLED${NC}"
    if [[ $FAILED -gt 0 ]]; then
        echo -e "${YELLOW}Failed: $FAILED${NC}"
    fi
    echo ""

    if [[ $INSTALLED -gt 0 ]]; then
        echo -e "${YELLOW}⚠ IMPORTANT: Test authentication immediately!${NC}"
        echo ""
        echo "1. Keep this terminal open (you have root access here)"
        echo "2. Open a NEW terminal and test:"
        echo "     sudo -k"
        echo "     sudo ls"
        echo "3. Verify fingerprint prompt appears (10 second timeout)"
        echo "4. Test password fallback (press Enter to skip fingerprint)"
        echo ""
        echo "If authentication fails, restore backups:"
        echo "  sudo cp $BACKUP_DIR/*.original $PAM_DIR/"
        echo ""
        echo "Test additional use cases:"
        echo "  - PolicyKit: pkexec ls"
        echo "  - System login: Log out and log back in"
        echo ""
    fi
fi

echo "Backups stored in: $BACKUP_DIR/"
echo ""
