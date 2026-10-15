# Host profile: Framework Laptop 13 (AMD), CachyOS + Sway.
# Sourced by deploy/linux and deploy/configure-system.sh via deploy/hosts/load.sh.
#
# From 2026-10 it stays in the UK with Andy as Chris's second lane runner
# beside sc-dev-01, reached from the Mac over Tailscale (SSH and Herdr's
# saved-machine view). Chris administers it, so deploy/linux may use sudo.
# Back to DOTPHILES_ROLE=laptop (and herdr/sshd off) if it returns as a laptop.

DOTPHILES_ROLE=host             # lanes run unattended: ignore lid, never idle-suspend
DOTPHILES_FINGERPRINT=1         # fprintd PAM for sudo/ly/swaylock
DOTPHILES_MT7925_BT=1           # MediaTek MT7925 Bluetooth cold-boot workaround
DOTPHILES_HERDR_SERVER=1        # herdr-server user unit enabled at boot
DOTPHILES_SSHD=1                # sshd enabled for the Mac
DOTPHILES_DPT_TMP_PRUNE=1       # prune estate lane temp in ~/.cache/dpt-tmp
DOTPHILES_ESTATE_SAMPLER=1      # sample memory, slots and disk headroom; ~/estate-metrics/ALERT
