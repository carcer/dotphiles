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

Bootstrap the Framework workstation on CachyOS/Arch. The script installs
official repository packages first, bootstraps `yay` without requiring Pamac,
then installs AUR packages, global npm tools, Herdr, and Oh My Zsh. Finally it
runs the shared Codex/Claude status-line installer and `configure-system.sh` to
enable fingerprint authentication for installed sudo/Ly/swaylock PAM services
and configure Limine's one-second hidden menu.

`configure-system.sh` patches only the relevant lines in distro-owned files. It
keeps password authentication intact and stores the first-seen originals beside
their targets as `*.dotphiles-original`.

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
