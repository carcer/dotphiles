# Dotfiles Repository

Dotphiles-based dotfiles framework with multi-machine support via per-machine git branches.

## Quick Reference

```bash
# Symlink all dotfiles into $HOME
dotsync/bin/dotsync -L

# Update dotfiles from remote
dotsync/bin/dotsync -u        # without submodules
dotsync/bin/dotsync -U        # with submodules

# Push local changes
dotsync/bin/dotsync -P

# List configured hosts and dotfiles
dotsync/bin/dotsync -l

# Full setup on a new machine
./install.sh    # clone repo, init submodules, run quick.sh
./quick.sh      # install nvm, symlink dotfiles
./post.sh       # enable docker, bluetooth
```

## Architecture

### Branch Strategy
- `master` — shared configuration and the Framework Laptop 13 AMD workstation
- `envs/*` — temporary per-platform or legacy branches with machine-specific overrides
  - `envs/mac` — macOS; keep as an overlay while shared changes move to `master`
  - `envs/xps-2019`, `envs/i3` — other machines
- Machine-to-branch mapping is in `dotsyncrc` under `[hosts]`

### dotsyncrc (Central Config)
The `[files]` section maps source paths to symlink destinations:
```
# srcfile:dstfile — links to ~/dstfile
# srcfile alone   — links to ~/.$srcfile (path stripped)
zsh/zshrc                    # → ~/.zshrc
config/rofi:.config/rofi     # → ~/.config/rofi
```

The `[hosts]` section maps hostnames to environment branches:
```
chris-framework     git=master
```

### Submodules
Zsh and vim plugins are git submodules (defined in `.gitmodules`):
- `zsh/dotzsh` — dotzsh framework
- `zsh/custom/` — zsh-syntax-highlighting, zsh-completions, zsh-autosuggestions, spaceship-prompt
- `vim/dotvim` — vim distribution
- `i3blocks/i3blocks-contrib` — i3 status bar scripts

### Key Directories
| Directory | Purpose |
|-----------|---------|
| `dotsync/` | Sync tool (tracked, formerly a submodule) |
| `deploy/` | Bootstrap scripts for linux/osx + package lists |
| `bin/` | Custom scripts (idle-suspend, blurlock, etc.) |
| `pam.d/` | Fingerprint auth PAM configs (requires sudo to install) |
| `systemd/` | Suspend/sleep/idle configs and WiFi driver workaround |
| `config/` | XDG config files (rofi, picom, kitty) |

## System-Level Configs (Require sudo)

**PAM fingerprint auth** (`pam.d/`):
- `pam.d/install-pam-configs.sh` — installs templates to `/etc/pam.d/` with backups
- `pam.d/backup-pam-configs.sh` — backs up current PAM configs
- Uses `pam_fprintd.so` with 10s timeout, falls back to password

**Systemd** (`systemd/`):
- `logind.conf.d/` — lid switch and power button behavior
- `sleep.conf.d/` — suspend mode (s2idle)
- `system-sleep/10-wifi-suspend.sh` — MT7925 WiFi+BT module unload/reload workaround for suspend
- `system/mt7925-bt-init.service` — boot-time MT7925 BT reset, fixes cold-boot `wmt command timed out` / `Failed to set up firmware (-110)`. Cold boot only — `reboot` doesn't drop chip power, so a wedged BT chip survives reboots and needs `systemctl poweroff` to recover
- `user/idle-suspend.service` — auto-suspend after 20min idle on battery
- `install-system-configs.sh` — `sudo` helper that copies the two files above into `/etc/systemd/...` and enables `mt7925-bt-init.service`. Re-run after editing either file
