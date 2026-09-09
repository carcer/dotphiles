# Host profile: Framework Laptop 13 (AMD), CachyOS + Sway.
# Sourced by deploy/linux and deploy/configure-system.sh via deploy/hosts/load.sh.

DOTPHILES_ROLE=laptop           # suspend on lid, idle suspend timer
DOTPHILES_FINGERPRINT=1         # fprintd PAM for sudo/ly/swaylock
DOTPHILES_MT7925_BT=1           # MediaTek MT7925 Bluetooth cold-boot workaround
DOTPHILES_HERDR_SERVER=0        # herdr started on demand from the TUI
DOTPHILES_SSHD=0
