#!/usr/bin/env bash
# Prompt-cache segment for the Claude Code status line. Reads status JSON on
# stdin; prints one line, or nothing when prompt_cache is absent or caching
# isn't observed. Fields are read defensively so older versions just skip them.
set -u
input=$(cat)
now=${CACHE_SEGMENT_NOW:-$(date +%s)}

printf '%s' "$input" | jq -e '(.prompt_cache // null) != null' >/dev/null 2>&1 || exit 0
printf '%s' "$input" | jq -e '.prompt_cache.caching_observed != false' >/dev/null 2>&1 || exit 0

j() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

warm=$(j '.prompt_cache.warm // false')
ttl=$(j '.prompt_cache.ttl // empty')
expires=$(j '.prompt_cache.expires_at // empty')
hit=$(j '.prompt_cache.hit_ratio // empty')
misses=$(j '.prompt_cache.misses // empty')
recache=$(j '.prompt_cache.recache_tokens_if_cold // empty')
cause=$(j '(.prompt_cache.last_miss_cause.causes // []) | join(", ")')

green=$'\033[32m'; yellow=$'\033[33m'; red=$'\033[31m'; rst=$'\033[0m'

case "$ttl" in 5m) ttl_s=300 ;; 1h) ttl_s=3600 ;; *) ttl_s="" ;; esac
remaining=""
case "$expires" in ''|*[!0-9]*) ;; *) remaining=$((expires - now)) ;; esac

# Warm flag can lag the clock between refreshes; an expired timestamp means cold.
if [ "$warm" != "true" ] || { [ -n "$remaining" ] && [ "$remaining" -le 0 ]; }; then
  out="cache ○ cold"
  if [ -n "$recache" ]; then
    k=$(awk -v t="$recache" 'BEGIN { printf "%.0f", t / 1000 }')
    out="${out} · next message re-caches ${k}k tokens"
  fi
  [ -n "$cause" ] && out="${out} · last miss: ${cause}"
  printf '%s%s%s' "$red" "$out" "$rst"
  exit 0
fi

color=$green
out="cache ●"
[ -n "$ttl" ] && out="${out} ${ttl}"
if [ -n "$remaining" ]; then
  if [ -n "$ttl_s" ]; then
    filled=$(awk -v r="$remaining" -v t="$ttl_s" 'BEGIN { f = int(r * 6 / t + 0.5); if (f > 6) f = 6; if (f < 0) f = 0; print f }')
    bar=""; i=0
    while [ "$i" -lt 6 ]; do
      if [ "$i" -lt "$filled" ]; then bar="${bar}█"; else bar="${bar}░"; fi
      i=$((i + 1))
    done
    out="${out} ${bar}"
    awk -v r="$remaining" -v t="$ttl_s" 'BEGIN { exit !(r * 5 < t) }' && color=$yellow
  fi
  if [ "$remaining" -ge 3600 ]; then
    left="$((remaining / 3600))h $(((remaining % 3600) / 60))m"
  elif [ "$remaining" -ge 60 ]; then
    left="$((remaining / 60))m"
  else
    left="${remaining}s"
  fi
  out="${out} ${left} left"
fi
if [ -n "$hit" ]; then
  out="${out} · hit $(awk -v h="$hit" 'BEGIN { printf "%.0f", h * 100 }')%"
fi
[ -n "$misses" ] && out="${out} · misses ${misses}"
printf '%s%s%s' "$color" "$out" "$rst"
