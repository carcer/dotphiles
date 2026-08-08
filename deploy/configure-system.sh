#!/usr/bin/env bash

set -euo pipefail

system_root=${DOTPHILES_SYSTEM_ROOT:-}
if [[ -z "$system_root" && $EUID -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

pam_dir="$system_root/etc/pam.d"
limine_config="$system_root/boot/limine.conf"

install_managed() {
  local mode=$1 source=$2 target=$3

  if [[ -z "$system_root" ]]; then
    install -o root -g root -m "$mode" "$source" "$target"
  else
    install -m "$mode" "$source" "$target"
  fi
}

backup_once() {
  local target=$1
  local backup="${target}.dotphiles-original"

  if [[ ! -e "$backup" ]]; then
    cp -a -- "$target" "$backup"
    echo "Backed up $target to $backup"
  fi
}

enable_fingerprint_pam() {
  local service=$1
  local target="$pam_dir/$service"
  local temporary

  if [[ ! -f "$target" ]]; then
    echo "Skipping PAM service $service (not installed)"
    return 0
  fi

  if grep -Eq '^[[:space:]]*auth[[:space:]].*pam_fprintd\.so([[:space:]]|$)' "$target"; then
    echo "Fingerprint PAM already enabled for $service"
    return 0
  fi

  backup_once "$target"
  temporary=$(mktemp "${TMPDIR:-/tmp}/dotphiles-pam-${service}.XXXXXX")
  awk '
    BEGIN { inserted = 0 }
    !inserted && $0 == "#%PAM-1.0" {
      print
      print ""
      print "auth       sufficient   pam_fprintd.so # dotphiles-fingerprint"
      inserted = 1
      next
    }
    NR == 1 && !inserted {
      print "#%PAM-1.0"
      print ""
      print "auth       sufficient   pam_fprintd.so # dotphiles-fingerprint"
      print ""
      inserted = 1
    }
    { print }
  ' "$target" > "$temporary"
  install_managed 0644 "$temporary" "$target"
  rm -f -- "$temporary"
  echo "Enabled fingerprint PAM for $service (password fallback preserved)"
}

configure_limine() {
  local temporary mode has_timeout has_quiet

  if [[ ! -f "$limine_config" ]]; then
    echo "Skipping Limine configuration (not installed)"
    return 0
  fi

  grep -Eq '^timeout:[[:space:]]*1[[:space:]]*$' "$limine_config" \
    && grep -Eq '^quiet:[[:space:]]*yes[[:space:]]*$' "$limine_config" \
    && {
      echo "Limine already uses the one-second hidden menu"
      return 0
    }

  backup_once "$limine_config"
  temporary=$(mktemp "${TMPDIR:-/tmp}/dotphiles-limine.XXXXXX")
  mode=$(stat -c '%a' "$limine_config")
  has_timeout=0
  has_quiet=0
  grep -Eq '^timeout:' "$limine_config" && has_timeout=1
  grep -Eq '^quiet:' "$limine_config" && has_quiet=1

  awk -v has_timeout="$has_timeout" -v has_quiet="$has_quiet" '
    BEGIN {
      if (!has_timeout) {
        print "timeout: 1"
        if (!has_quiet) print "quiet: yes"
      }
    }
    /^timeout:/ {
      print "timeout: 1"
      if (!has_quiet) print "quiet: yes"
      next
    }
    /^quiet:/ {
      print "quiet: yes"
      next
    }
    { print }
  ' "$limine_config" > "$temporary"

  install_managed "$mode" "$temporary" "$limine_config"
  rm -f -- "$temporary"
  echo "Configured Limine for a one-second hidden menu (press any key to reveal it)"
}

for pam_service in sudo ly swaylock; do
  enable_fingerprint_pam "$pam_service"
done
configure_limine
