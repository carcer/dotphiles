# Host profile: sc-dev-01, Andy's 64 GB machine, CachyOS.
# Sourced by deploy/linux and deploy/configure-system.sh via deploy/hosts/load.sh.
#
# Role: remote herdr runner for Chris, reached from the Mac over Tailscale
# (SSH and Herdr's saved-machine view). Runs as the dedicated `chris` user.

DOTPHILES_ROLE=host             # never idle-suspend; lanes run unattended
DOTPHILES_FINGERPRINT=0         # no fingerprint reader in use
DOTPHILES_MT7925_BT=0           # workaround not applicable
DOTPHILES_HERDR_SERVER=1        # herdr-server user unit enabled at boot
DOTPHILES_SSHD=0                # sshd already enabled and hardened box-side by Andy
