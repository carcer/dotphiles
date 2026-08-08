# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal dotfiles repo built on the [dotphiles](https://github.com/dotphiles/dotphiles) framework. It lives at `~/.dotfiles` and is driven by [`dotsync`](https://github.com/dotphiles/dotsync), which symlinks selected files out of this repo into `$HOME`. The actual config files here are *sources*; the live files in `$HOME` are symlinks back to them, so editing a file in this repo edits the running config directly.

## Trunk and platform overlays

`master` is the shared trunk and the active Framework configuration. The Mac remains on a temporary platform overlay while its reusable configuration is promoted incrementally. The `[hosts]` section of `dotsyncrc` maps each hostname:

```
Chriss-MacBook-Air.local   git=envs/mac
chris-framework            git=master
xps-2019                   git=envs/xps-2019
xps-i3 / chris-xps159500   git=envs/i3
```

Put reusable configuration on `master`; keep only macOS-specific installation and presentation differences on `envs/mac`. Do not switch branches casually in a live checkout because home-directory symlinks point into the working tree. Use comparison, cherry-picking, or a separate worktree for cross-platform changes.

## How symlinking works (dotsync)

`dotsyncrc` (itself symlinked to `~/.dotsyncrc`) has a `[files]` section listing what gets linked:

- `srcfile` → linked to `~/.srcfile` (basename, dotted) by default.
- `srcfile:dstfile` → explicit destination, e.g. `kitty:.config/kitty`, `i3blocks:.config/i3blocks`.
- Commented (`#`) lines are disabled on this branch. Enabling a tool means uncommenting its line here.

The `dotsync` script is vendored at `dotsync/bin/dotsync` (a git submodule). Common invocations:

```bash
dotsync/bin/dotsync -L    # symlink enabled dotfiles into $HOME (apply changes to dotsyncrc)
dotsync/bin/dotsync -l    # list configured hosts and the dotfiles that would be linked
dotsync/bin/dotsync -U    # update to latest dotfiles including submodules
dotsync/bin/dotsync -P    # push local changes back to the repo
```

There is no build/test/lint step — verification is "run `dotsync -L` and check the symlinks / start a new shell."

## Bootstrapping a machine

`install.sh` → clones the repo recursively, checks out the env branch, then runs `quick.sh` → installs nvm and runs `dotsync -L`. `post.sh` does Linux-only post-setup (docker group, bluetooth). `deploy/` holds optional one-off setup: `deploy/osx` (macOS `defaults` tweaks, gated behind a "yes" prompt — read before running), `deploy/packages/homebrew`, `deploy/oh-my-zsh.sh`, `deploy/terminal/iterm2`.

## Submodules

Several directories are git submodules (see `.gitmodules`): `dotsync`, `zsh/dotzsh`, `vim/dotvim`, and the zsh plugins/themes under `zsh/custom/` (`zsh-syntax-highlighting`, `zsh-completions`, `zsh-autosuggestions`, `spaceship-prompt`), plus `i3blocks/i3blocks-contrib`. Don't edit vendored submodule contents directly; update them via the submodule's own remote.

## Layout notes

- Each top-level dir is one tool's config (`git/`, `vim/`, `ssh/`, `kitty/`, `i3/`, etc.). Only those uncommented in `dotsyncrc` are active on a given branch.
- Herdr supersedes the former tmux configuration on both active machines.
- `zsh/` uses oh-my-zsh with the `spaceship` theme; `ZSH_CUSTOM` points at `zsh/custom/`. The actual settings live in `zsh/zshrc`.
- `bin/` is linked to `~/bin` and holds personal scripts (`az`, `kill_docker`, `webstorm`, etc.).
