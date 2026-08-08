# CachyOS/Sway migration runbook

This repository is live configuration: files under `$HOME` are symlinks into the
checked-out branch. Do not switch branches casually from a graphical session.
Use `bin/safe-dotfiles-switch` for normal host-matched switches.

## Fixed partition map

- `/dev/nvme0n1p1`: EFI, reuse without formatting.
- `/dev/nvme0n1p3`: current Manjaro root, replace with CachyOS.
- `/dev/nvme0n1p4`: persistent Btrfs `/home`, mount as `/home` without formatting.
- `/dev/nvme0n1p2`: swap.

Always verify this map with `lsblk` in the live ISO. Device names can change when
USB/storage devices are added. Prefer UUIDs and filesystem labels in the installer.
CachyOS recommends manual partitioning; do not use an automatic replace option.

## Before installation

1. Run `deploy/preflight-capture.sh` (the default destination is on persistent home).
2. Push all durable repository changes.
3. Back up irreplaceable files and ignored credentials separately and securely.
4. Boot the USB in UEFI mode and verify networking before launching the installer.
5. Select Sway as the only desktop environment.

The CachyOS desktop ISO is not tied to Andy's desktop choice; Sway is selected
for this laptop inside the installer.

## After installation

1. Mount the existing home filesystem without formatting it and retain username `chris`.
2. Clone/switch to `envs/framework`, then run `deploy/linux`.
3. Run dotsync to restore links. `deploy/linux` applies the managed PAM and Limine settings via `deploy/configure-system.sh`.
4. Re-enroll and verify fingerprints with `deploy/verify-fingerprint.sh`.
5. Validate Sway with `sway --validate --config ~/.config/sway/config`.
6. Run `deploy/post-install-smoke.sh` and work through the validation checklist.

Fingerprint templates are stored under `/var/lib/fprint`, not `$HOME`, so a root
replacement normally requires re-enrollment. Never enable fingerprint-only PAM;
retain password access as a recovery path.
