#!/usr/bin/env bash

# Shared Claude Code status line. It reads the status JSON from stdin and
# deliberately keeps host paths, credentials, and session data out of the
# repository.

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
input=$(cat)

if ! printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
  printf 'statusline: Claude Code sent invalid JSON\n' >&2
  exit 1
fi

model=$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // "."')

dir=$(basename "$cwd")

# Git: branch plus edited (tracked changes) and new (untracked) counts.
branch=""
edited=0
new=0
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  while IFS= read -r git_status; do
    [ -z "$git_status" ] && continue
    case "$git_status" in
      "??"*) new=$((new + 1)) ;;
      *) edited=$((edited + 1)) ;;
    esac
  done < <(git -C "$cwd" status --porcelain 2>/dev/null)
fi

# Claude Code's native context block is authoritative. Older releases need a
# transcript fallback; awk keeps that fallback portable across macOS and Linux
# instead of relying on macOS-only `tail -r`.
tokens=""
pct=""
ctx=200000
if printf '%s' "$input" | jq -e '(.context_window.context_window_size // null) != null' >/dev/null 2>&1; then
  tokens=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
  ctx=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 200000')
  pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0')
else
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
  model_id=$(printf '%s' "$input" | jq -r '.model.id // ""')
  if printf '%s %s' "$model_id" "$model" | grep -qi '1m'; then
    ctx=1000000
  fi
  tokens=0
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    usage_line=$(awk '/"usage"/ { line = $0 } END { print line }' "$transcript" 2>/dev/null)
    if [ -n "${usage_line:-}" ]; then
      tokens=$(printf '%s' "$usage_line" | jq -r '
        (.message.usage // {}) as $u
        | (($u.input_tokens // 0) + ($u.cache_read_input_tokens // 0)
           + ($u.cache_creation_input_tokens // 0))' 2>/dev/null)
    fi
  fi
  [ -n "${tokens:-}" ] || tokens=0
  pct=$(awk -v used="${tokens:-0}" -v window="$ctx" 'BEGIN { if (window > 0) printf "%.0f", used * 100 / window; else print 0 }')
fi

case "$ctx" in
  ''|*[!0-9]*) ctx=200000 ;;
esac
case "${pct:-0}" in
  ''|*[!0-9.]*) pct=0 ;;
esac

tok_k=$(awk -v used="${tokens:-0}" 'BEGIN { printf "%.1fk", used / 1000 }')
if awk -v value="${pct:-0}" 'BEGIN { exit !(value >= 80) }'; then
  tok_icon="⚠️"
else
  tok_icon="🧠"
fi

dim=$'\033[2m'
rst=$'\033[0m'
sep="${dim} · ${rst}"

percentage_high() {
  awk -v value="$1" 'BEGIN { exit !(value >= 80) }'
}

round_percentage() {
  awk -v value="$1" 'BEGIN {
    if (value ~ /^[0-9]+([.][0-9]+)?$/) printf "%.0f", value
  }'
}

usage=""
hour=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ProxyCLI can provide rate limits inline. When it doesn't, use the last
# successful read from Codex's account/rateLimits/read app-server method. The
# cache helper refreshes asynchronously, so rendering never waits on a network
# request or exposes Codex authentication state to Claude Code.
if [ -z "$hour" ] && [ -z "$week" ] && [ -x "$script_dir/codex-rate-limits.py" ]; then
  cached_limits=$("$script_dir/codex-rate-limits.py" 2>/dev/null || true)
  if [ -n "$cached_limits" ]; then
    hour=$(printf '%s' "$cached_limits" | jq -r '
      (.rateLimitsByLimitId.codex // .rateLimits // {})
      | [.primary, .secondary]
      | map(select(.windowDurationMins != null and .windowDurationMins <= 360))
      | .[0].usedPercent // empty' 2>/dev/null)
    week=$(printf '%s' "$cached_limits" | jq -r '
      (.rateLimitsByLimitId.codex // .rateLimits // {})
      | [.primary, .secondary]
      | map(select(.windowDurationMins != null and .windowDurationMins >= 10000))
      | .[0].usedPercent // empty' 2>/dev/null)
    week_reset=$(printf '%s' "$cached_limits" | jq -r '
      (.rateLimitsByLimitId.codex // .rateLimits // {})
      | [.primary, .secondary]
      | map(select(.windowDurationMins != null and .windowDurationMins >= 10000))
      | .[0].resetsAt // empty' 2>/dev/null)
  fi
fi

hour=$(round_percentage "$hour")
week=$(round_percentage "$week")

format_reset() {
  case "$1" in
    ''|*[!0-9]*) return ;;
  esac
  if date -r "$1" '+%a %H:%M' >/dev/null 2>&1; then
    date -r "$1" '+%a %H:%M'
  else
    date -d "@$1" '+%a %H:%M' 2>/dev/null || true
  fi
}

if [ -n "$hour" ] || [ -n "$week" ]; then
  if { [ -n "$hour" ] && percentage_high "$hour"; } || { [ -n "$week" ] && percentage_high "$week"; }; then
    u_icon="⚠️"
  else
    u_icon="📊"
  fi
  usage="${u_icon} OAI"
  [ -n "$hour" ] && usage="${usage} ${hour}% 5h"
  [ -n "$week" ] && usage="${usage} ${week}% wk"
  reset_label=$(format_reset "$week_reset")
  [ -n "$reset_label" ] && usage="${usage} ↻ ${reset_label}"
fi

loc="📁 ${dir}"
[ -n "$branch" ] && loc="${loc}${dim} (${branch})${rst}"

line="${loc}${sep}${edited} 📝 ${new} 🆕${sep}${tok_icon} ${tok_k} (${pct:-0}%)"
[ -n "$usage" ] && line="${line}${sep}${usage}"
line="${line}${sep}🤖 ${model}"
printf '%s' "$line"
