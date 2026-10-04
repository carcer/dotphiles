# List the directory after cd, but only at an interactive terminal. Agent and
# script shells (Claude Code snapshots these functions) get a plain cd, so they
# don't dump a listing into their output. A failed cd returns its error.
function cd() {
  builtin cd "$@" || return
  [[ -o interactive && -t 1 ]] && ls
  return 0
}
