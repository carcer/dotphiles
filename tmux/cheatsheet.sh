#!/usr/bin/env bash
# tmux cheatsheet — prints a quick reference for this dotfiles' tmux.conf
# Usage: tmux/cheatsheet.sh   (or bind to `prefix ?` / an alias)
#
# Keeps in sync with tmux/tmux.conf: prefix is C-a, vim-style panes.

set -euo pipefail

# Colors (disabled when not a tty or when NO_COLOR is set)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  B=$'\e[1m'; DIM=$'\e[2m'; R=$'\e[0m'
  CYAN=$'\e[36m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; MAGENTA=$'\e[35m'
else
  B=''; DIM=''; R=''; CYAN=''; GREEN=''; YELLOW=''; MAGENTA=''
fi

hdr() { printf '\n%s%s%s\n' "$B$MAGENTA" "$1" "$R"; }
row() { printf '  %s%-22s%s %s\n' "$CYAN" "$1" "$R" "$2"; }

printf '%s\n' "${B}${GREEN}┌─────────────────────────────────────────────┐${R}"
printf '%s\n' "${B}${GREEN}│            tmux cheatsheet  (C-a)            │${R}"
printf '%s\n' "${B}${GREEN}└─────────────────────────────────────────────┘${R}"
printf '%s\n' "  ${DIM}Prefix = ${R}${B}Ctrl-a${R}${DIM} — press, release, then the key below.${R}"

hdr "Build a 2×2 grid"
row "C-a |"            "split left / right"
row "C-a -"            "split top / bottom (current pane)"
row "C-a h  then  C-a -" "move to other pane, split it → 2×2"
row "C-a <space>"      "cycle layouts (stop on 'tiled' = even 2×2)"

hdr "Switch panes (vim-style)"
row "C-a h"            "← left"
row "C-a j"            "↓ down"
row "C-a k"            "↑ up"
row "C-a l"            "→ right"
row "C-a o"            "cycle to next pane"
row "C-a q"            "show pane numbers; press # to jump"

hdr "Resize (repeatable — keep tapping)"
row "C-a H / J / K / L" "grow pane ← / ↓ / ↑ / → (5 cells)"
row "C-a z"            "zoom pane fullscreen (toggle)"

hdr "Windows & misc"
row "C-a c"            "new window (same dir)"
row "C-a x"            "kill current pane"
row "C-a r"            "reload config"
row "C-a [   then v,y" "copy mode: select (v), yank (y)"

hdr "Plugins (TPM)"
row "C-a I"            "install plugins (REQUIRED before save/restore works)"
row "C-a U"            "update plugins"

hdr "Session save / restore (resurrect + continuum)"
row "C-a C-s"          "save session now (manual snapshot)"
row "C-a C-r"          "restore last saved session"
printf '  %sAuto-saves every 15m; auto-restores on tmux start. Saves: ~/.local/share/tmux/resurrect/%s\n' "$DIM" "$R"
printf '  %sNOTE: declaring the plugins is not enough — run C-a I once or saves never happen.%s\n\n' "$DIM" "$R"
