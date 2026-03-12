#!/usr/bin/env bash
set -euo pipefail

echo "Enabling and starting expressvpn-service..."
sudo systemctl enable --now expressvpn-service.service

echo ""
echo "Enabling background mode (required for headless/i3 usage)..."
expressvpnctl background enable

echo ""
echo "Please log in to ExpressVPN by running:"
echo "  expressvpnctl login <activation-code-file>"
echo ""
echo "You can find your activation code at https://www.expressvpn.com/setup"
read -rp "Press Enter after you have logged in..."

echo ""
echo "Setting protocol to Lightway UDP..."
expressvpnctl set protocol lightway_udp

echo ""
echo "ExpressVPN setup complete."
echo ""
echo "Usage:"
echo "  expressvpnctl connect              # connect to recommended server"
echo "  expressvpnctl connect usny         # connect to specific location"
echo "  expressvpnctl disconnect           # disconnect"
echo "  expressvpnctl status               # check status"
echo "  expressvpnctl locations            # list available locations"
