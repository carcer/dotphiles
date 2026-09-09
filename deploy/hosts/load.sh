# Load the host profile for this machine. Source this file; do not execute it.
#
#   source "$DIR/hosts/load.sh"
#
# Resolves deploy/hosts/<hostname>.sh (override with DOTPHILES_HOST) and falls
# back to laptop-safe defaults when no profile exists, so an unknown host still
# deploys without enabling any host-only services.

DOTPHILES_ROLE=${DOTPHILES_ROLE:-laptop}
DOTPHILES_FINGERPRINT=${DOTPHILES_FINGERPRINT:-0}
DOTPHILES_MT7925_BT=${DOTPHILES_MT7925_BT:-0}
DOTPHILES_HERDR_SERVER=${DOTPHILES_HERDR_SERVER:-0}
DOTPHILES_SSHD=${DOTPHILES_SSHD:-0}

_dotphiles_hosts_dir=$(dirname "${BASH_SOURCE[0]}")
DOTPHILES_HOST=${DOTPHILES_HOST:-$(hostname -s 2>/dev/null || hostname)}
_dotphiles_profile="$_dotphiles_hosts_dir/$DOTPHILES_HOST.sh"

if [[ -f "$_dotphiles_profile" ]]; then
  # shellcheck source=/dev/null
  source "$_dotphiles_profile"
  echo "Host profile: $DOTPHILES_HOST (role=$DOTPHILES_ROLE)"
else
  echo "No host profile for '$DOTPHILES_HOST'; using laptop-safe defaults" >&2
fi

export DOTPHILES_HOST DOTPHILES_ROLE DOTPHILES_FINGERPRINT DOTPHILES_MT7925_BT \
  DOTPHILES_HERDR_SERVER DOTPHILES_SSHD
unset _dotphiles_hosts_dir _dotphiles_profile
