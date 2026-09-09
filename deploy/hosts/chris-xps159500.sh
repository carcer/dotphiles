# Host profile: Dell XPS 15 9500 (i9, 4K touch), CachyOS + Sway.
# Sourced by deploy/linux and deploy/configure-system.sh via deploy/hosts/load.sh.
#
# Hostname: chris-xps159500. Role: always-on host for the sechroom and freedivr
# estates, driven from the Mac over SSH and Herdr's saved-machine view.

DOTPHILES_ROLE=host             # ignore lid, never idle-suspend
DOTPHILES_FINGERPRINT=0         # no fingerprint reader in use
DOTPHILES_MT7925_BT=0           # Intel wireless; workaround not applicable
DOTPHILES_HERDR_SERVER=1        # herdr-server user unit enabled at boot
DOTPHILES_SSHD=1                # sshd enabled for the Mac
