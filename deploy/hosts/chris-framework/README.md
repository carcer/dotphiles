# chris-framework as a lane runner

From October 2026 the Framework stays in the UK with Andy as Chris's second
lane runner beside sc-dev-01. It already runs CachyOS on `master` (repaved
2026-08-08). Unlike sc-dev-01, Chris administers it, so `deploy/linux` runs
with `DOTPHILES_SYSTEM=1` and may use sudo (Chris types the password).

## Andy's side (on site)

1. Fit and test the replacement webcam module; watch for the old display
   corruption over a few cold boots.
2. Ethernet on the same network as sc-dev-01; mains power, lid can stay shut.
3. BIOS: power on after AC loss, if offered.
4. Tailscale signed in and the node shared with Chris; hostname `chris-framework`.
5. `sudo systemctl enable --now sshd`; Chris's key in `~/.ssh/authorized_keys`.
6. Report RAM, CPU and disk: `free -g`, `nproc`, `lsblk`.

## Chris's side (remote, from the Mac)

1. **Reach it.** Add `Host chris-framework` with its Tailscale MagicDNS name to
   `~/.ssh/config` (and the `ssh/config` source), then `ssh chris-framework true`.
   Add it to herdr's saved machines as `chris-framework`.
2. **Update.** `yay -Syu`, then `git -C ~/.dotfiles pull --ff-only` and
   `~/.dotfiles/dotsync/bin/dotsync -L`.
3. **Deploy.** `~/.dotfiles/deploy/linux`. With this profile it installs packages
   (docker, docker-rootless-extras, dotnet-sdk, ...), enables herdr-server,
   sshd, dpt-tmp-prune and the estate sampler, and installs the logind drop-in
   that ignores the lid and idle.
4. **Root steps Chris runs** (the agent can't):
   - `sudo loginctl enable-linger chris` (herdr-server survives logout)
   - `sudo mkdir -p /etc/ananicy.d/99-local` and copy sc-dev-01's `sshd.rules`
     and `node.rules`, if ananicy-cpp demotes them here too
   - .NET 9 alongside 10: `sudo pacman -S dotnet-sdk-9.0-bin` (chaotic-aur), to
     match sc-dev-01
5. **Rootless docker.** `dockerd-rootless-setuptool.sh install`, then check
   `DOCKER_HOST` resolves (zshenv points at `$XDG_RUNTIME_DIR/docker.sock`).
6. **Agent tools.** `claude` native install in `~/.local/bin`; codex and
   `@sechroom/cli` npm globals; `dotnet tool install -g roslynk`; Codex config
   with sechroom-ocd `required = true` and `startup_timeout_sec = 120`.
7. **Btrfs.** If / or /home is btrfs, enable btrfsmaintenance like sc-dev-01
   (weekly balance `DUSAGE "5 10 20 30"`, monthly scrub).
8. **Verify.** `bin/estate-tool-versions` (lists chris-framework by default),
   `box-oauth` sign-in test, `deploy/post-install-smoke.sh`.

## Then

- Test slots start at 1 test / 1 build (zshenv) until RAM and a week of
  `~/estate-metrics/box-usage.csv` justify more.
- Its dotnet test lock is separate from sc-dev-01's: lanes on the two boxes
  don't block each other.
- Each estate's conductor decides which lanes move here. The rollout skill
  treats it as a second box: every restart and update covers both.
