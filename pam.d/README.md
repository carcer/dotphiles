# PAM Fingerprint Authentication Configuration

## Overview
This directory contains PAM configuration templates and installation scripts for fingerprint authentication using fprintd on Manjaro Linux with i3 window manager.

## Hardware
- **Device:** Goodix Fingerprint USB Device (27c6:609c)
- **Driver:** libfprint 1.94.9+
- **Status:** ✅ Fully supported

## Supported Use Cases
- ✅ **sudo authentication** - Use fingerprint for sudo commands
- ✅ **System login** - Login via LightDM with fingerprint
- ✅ **PolicyKit authorization** - GUI privilege escalation prompts
- ⚠️ **Screen unlock** - Password only (standard i3lock doesn't support PAM)

## Files
- `README.md` - This documentation
- `backup-pam-configs.sh` - Backup current PAM configs before modification
- `install-pam-configs.sh` - Install PAM templates to /etc/pam.d/
- `templates/` - PAM configuration templates with fprintd support
  - `system-auth` - Core authentication config (affects sudo, login, most services)
  - `polkit-1` - PolicyKit authorization config
- `backup/` - Backed up original PAM configurations

## Installation

### 1. Install Required Packages
```bash
sudo pacman -S fprintd libfprint
```

### 2. Verify Hardware Detection
```bash
lsusb | grep -i fingerprint
# Expected: Bus 001 Device 002: ID 27c6:609c ... Goodix Fingerprint
```

### 3. Enroll Fingerprints
```bash
# Enroll primary finger (requires 5 scans)
fprintd-enroll -f right-index-finger

# Enroll backup finger (recommended)
fprintd-enroll -f left-index-finger

# Verify enrollment
fprintd-list $USER

# Test recognition
fprintd-verify
```

**Best practices:**
- Enroll at least 2 different fingers for redundancy
- Use different hands (e.g., right and left index) in case of injury
- Clean and dry your finger for best recognition

### 4. Backup Current PAM Configs
```bash
cd ~/.dotfiles/pam.d
sudo ./backup-pam-configs.sh
```

### 5. Install PAM Configurations
```bash
# Install all PAM configs
sudo ./install-pam-configs.sh

# Or install individual configs
sudo ./install-pam-configs.sh polkit-1    # Low risk - creates new file
sudo ./install-pam-configs.sh system-auth # Higher risk - modifies core auth

# IMPORTANT: Keep your current terminal open until you've tested!
```

### 6. Test Authentication
```bash
# Test sudo (in a NEW terminal)
sudo -k
sudo ls
# Expected: Fingerprint prompt, then password fallback if timeout/failure

# Test PolicyKit
pkexec ls
# Expected: Fingerprint prompt in polkit-gnome dialog

# Test system login
# Log out and log back in via LightDM
```

## PAM Configuration Details

### system-auth Template
The `system-auth` template adds fingerprint authentication as the first sufficient auth method:

```pam
auth    sufficient    pam_fprintd.so    max_tries=1 timeout=10
```

**Parameters:**
- `sufficient` - If fingerprint succeeds, skip password check
- `max_tries=1` - Prevents frustrating repeated failed scans
- `timeout=10` - Falls back to password after 10 seconds

**Password fallback:** All existing `pam_unix.so` lines remain unchanged, providing password fallback if:
- Fingerprint scan fails
- Fingerprint times out
- Hardware unavailable
- User presses Enter/Escape to skip

### polkit-1 Template
Standalone PAM config for PolicyKit GUI authorization:

```pam
auth       sufficient   pam_fprintd.so    max_tries=1 timeout=10
auth       required     pam_unix.so       try_first_pass
```

## Security Considerations

### Best Practices
- ✅ **Always maintain password fallback** - Never use `required` for pam_fprintd
- ✅ **Enroll multiple fingers** - Hardware failure or injury won't lock you out
- ✅ **Test password fallback regularly** - Ensure it still works
- ✅ **Keep backups** - Store original PAM configs before modification
- ✅ **Test with new terminal** - Keep root terminal open during PAM changes

### Limitations
- **Fingerprints cannot be changed** if compromised (unlike passwords)
- **Fingerprints can be spoofed** with sophisticated attacks (rare but possible)
- **Hardware dependency** - If fingerprint reader fails, must use password
- **Per-user enrollment** - Each user must enroll their own fingerprints

### Multi-User Scenarios
Each user must enroll their own fingerprints:
```bash
# Each user runs:
fprintd-enroll
fprintd-enroll -f left-index-finger  # Additional fingers
```

Fingerprints are stored in `/var/lib/fprint/$USERNAME/` (encrypted by fprintd).

## Rollback Procedure

### If PAM Changes Cause Login Lockout

**Method 1: Boot into Rescue Mode**
1. Reboot and press 'e' at GRUB menu
2. Add `systemd.unit=rescue.target` to kernel line
3. Press Ctrl+X to boot
4. Login as root
5. Restore backups:
   ```bash
   mount -o remount,rw /
   cd /home/chris/.dotfiles/pam.d/backup
   cp *.original /etc/pam.d/
   reboot
   ```

**Method 2: Use Live USB**
1. Boot from Manjaro live USB
2. Mount root partition:
   ```bash
   sudo mount /dev/nvme0n1p2 /mnt  # Adjust device as needed
   sudo cp /mnt/home/chris/.dotfiles/pam.d/backup/*.original /mnt/etc/pam.d/
   sudo umount /mnt
   reboot
   ```

### Manual Rollback (If System Still Accessible)
```bash
cd ~/.dotfiles/pam.d/backup
sudo cp system-auth.original /etc/pam.d/system-auth
sudo cp polkit-1.original /etc/pam.d/polkit-1  # If exists
```

## Monitoring and Maintenance

### Check Fingerprint Service Status
```bash
# Service status (D-Bus activated)
systemctl status fprintd.service

# Check logs
journalctl -u fprintd.service -f

# Recent errors
journalctl -u fprintd.service --since today | grep -i error
```

### Monitor Authentication Activity
```bash
# Real-time auth monitoring
journalctl -f | grep -i 'fprintd\|pam'

# Recent fingerprint auth attempts
journalctl --since today | grep fprintd

# Failed authentication attempts
journalctl --since today | grep "authentication failure"
```

### Post-System-Update Maintenance
Manjaro may overwrite `/etc/pam.d/` configs during system updates.

**After major updates, check:**
```bash
# Compare current config with template
diff /etc/pam.d/system-auth ~/.dotfiles/pam.d/templates/system-auth

# If overwritten, re-run installation
sudo ~/.dotfiles/pam.d/install-pam-configs.sh
```

### Regular Maintenance Tasks
```bash
# Verify enrolled fingerprints
fprintd-list $USER

# Test recognition quality
fprintd-verify

# Clear old enrollments (if needed)
fprintd-delete $USER
fprintd-enroll  # Re-enroll
```

## Troubleshooting

### Fingerprint Not Recognized
**Symptoms:** `fprintd-verify` fails consistently

**Solutions:**
1. Check enrollment: `fprintd-list $USER`
2. Re-enroll finger: `fprintd-delete $USER && fprintd-enroll`
3. Try different finger
4. Check hardware: `lsusb | grep fingerprint`
5. Check logs: `journalctl -u fprintd -n 50`
6. Update driver: `sudo pacman -Syu libfprint`

### No Fingerprint Prompt
**Symptoms:** Authentication doesn't prompt for fingerprint

**Solutions:**
1. Verify fprintd is running: `systemctl status fprintd`
2. Check PAM config: `grep fprintd /etc/pam.d/system-auth`
3. Check enrollment: `fprintd-list $USER`
4. Start service manually: `sudo systemctl start fprintd`

### Password Fallback Not Working
**Symptoms:** Cannot login with password after fingerprint timeout

**Solutions:**
1. Check PAM config has `pam_unix.so` lines intact
2. Boot into rescue mode and restore backup
3. Verify PAM syntax: `sudo pam-config-check` (if available)

### Fingerprint Works for sudo, Not Login
**Symptoms:** sudo accepts fingerprint, LightDM doesn't

**Solutions:**
1. Verify PAM chain: `grep system-auth /etc/pam.d/lightdm`
2. Check LightDM logs: `journalctl -u lightdm -n 100`
3. Try adding fprintd directly to `/etc/pam.d/lightdm`
4. Check greeter supports fingerprint prompts

### Service Crashes
**Symptoms:** fprintd service inactive/failed

**Solutions:**
1. Restart: `sudo systemctl restart fprintd`
2. Check USB: `lsusb | grep fingerprint`
3. Check kernel logs: `dmesg | grep -i goodix`
4. Reinstall: `sudo pacman -S fprintd --overwrite '*'`

## Advanced Configuration

### Conditional Fingerprint Authentication
Require password for critical operations:

**Example: Password-only for su to root**
Edit `/etc/pam.d/su`:
```pam
#%PAM-1.0
auth       required     pam_unix.so   # No fprintd
account    include      system-auth
password   include      system-auth
session    include      system-auth
```

### Audit Fingerprint Usage
Log fingerprint authentication attempts:

**Create logging script:** `/usr/local/bin/log-fingerprint-auth`
```bash
#!/bin/bash
logger -t fingerprint-auth "User: $PAM_USER, Service: $PAM_SERVICE"
```

**Add to PAM config:**
```pam
auth    optional    pam_exec.so    /usr/local/bin/log-fingerprint-auth
```

## Screen Locker Limitation

**Current limitation:** Standard i3lock (version 2.16) does NOT support PAM authentication. Screen unlock requires password only.

**Alternatives for fingerprint screen unlock:**
1. **xsecurelock** - Full PAM support, highly secure
2. **i3lock-color** (AUR) - PAM-patched i3lock fork
3. **light-locker** - XFCE's locker with PAM support

To switch lockers, modify `/home/chris/.dotfiles/i3/config` and update the xautolock locker parameter.

## Performance

**Expected Performance:**
- Recognition time: < 1 second
- Timeout: 10 seconds (configurable)
- Enrollment: ~5 scans per finger, ~30 seconds total

**Resource Usage:**
- fprintd: Minimal CPU/memory (D-Bus activated on demand)
- No performance impact when idle
- Slight delay on first auth per session (D-Bus activation)

## References

- **fprintd:** https://fprint.freedesktop.org/
- **libfprint:** https://fprint.freedesktop.org/libfprint-doc/
- **PAM documentation:** `man pam.d`, `man pam_fprintd`
- **Arch Wiki:** https://wiki.archlinux.org/title/Fprint

## Support

For issues or questions:
1. Check this README's troubleshooting section
2. Check system logs: `journalctl -u fprintd -n 100`
3. Consult Arch Wiki: https://wiki.archlinux.org/title/Fprint
4. Manjaro forums: https://forum.manjaro.org/

---

**Last Updated:** 2026-01-09
**Tested On:** Manjaro Linux with i3 window manager, Goodix Fingerprint Device (27c6:609c)
