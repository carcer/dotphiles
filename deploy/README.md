deploy
======

Scripts to deploy a new machine

osx
---

Setup OSX with sensible default options

### packages/macports

Install required packages using macports

### packages/brew

Install required packages using homebrew

linux
-----

Bootstrap a CachyOS/Arch host on the master trunk. The script installs
official repository packages first, bootstraps `yay` without requiring Pamac,
then installs AUR packages, global npm tools, Herdr, and Oh My Zsh. It runs the
shared Codex/Claude status-line installer, seeds `~/.codex/config.toml` from
`codex/config.seed.toml` on a fresh machine, links this host's Sway overrides,
and runs `configure-system.sh`. Host-role services (the `herdr-server` user
unit, `sshd`) are enabled when the host profile asks for them.

`configure-system.sh` patches only the relevant lines in distro-owned files. It
keeps password authentication intact and stores the first-seen originals beside
their targets as `*.dotphiles-original`. Fingerprint PAM is applied only when
the host profile enables it; logind drop-ins under
`hosts/<hostname>/logind.conf.d/` are installed to `/etc/systemd/logind.conf.d/`.

### hosts/

One profile per machine, selected by `hostname -s` (override with
`DOTPHILES_HOST`), sourced through `hosts/load.sh` by `linux`,
`configure-system.sh`, `../systemd/install-system-configs.sh` and
`post-install-smoke.sh`. Unknown hosts get laptop-safe defaults with every
host-only service off.

| Profile               | Role   | Notes                                                        |
|-----------------------|--------|--------------------------------------------------------------|
| `chris-framework.sh`  | laptop | fingerprint PAM, MT7925 Bluetooth workaround                 |
| `chris-xps159500.sh`  | host   | always-on estate host: herdr-server, sshd, lid/idle ignored  |

Sway per-host output/input/autostart lives in `../sway/hosts/<hostname>.conf`;
`linux` links it to `~/.config/sway/host.conf`, which the shared config includes.

### packages/arch-repo

Packages installed from configured Pacman repositories.

### packages/arch-aur

Packages installed through `yay`. Review AUR sources before installation.

### packages/npm

Unpinned global developer CLIs installed as the user. A distro npm is given a
user-owned `$HOME/.local` prefix; an active NVM prefix is preserved.

### packages/apt

Deprecated historical compatibility list. It is not consumed by `deploy/linux`.

See `CACHYOS-MIGRATION.md` for the fixed partition map and migration procedure.
