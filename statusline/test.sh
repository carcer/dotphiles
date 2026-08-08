#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/dotphiles-statusline-test.XXXXXX")
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/codex" "$fixture/claude" "$fixture/ocd" "$fixture/abcs"

test -x "$script_dir/claude-statusline.sh"
test -x "$script_dir/install.sh"

cat > "$fixture/codex/config.toml" <<'EOF'
# Keep this comment and the unrelated settings.
[projects."/fixture"]
trust_level = "trusted"

[tui]
status_line = ["old-item"]
status_line_use_colors = false
resume_cwd = "session"

[other]
value = "keep"
EOF

cat > "$fixture/claude/settings.json" <<'EOF'
{
  "hooks": {"SessionStart": ["keep this hook"]},
  "model": "opus"
}
EOF

cat > "$fixture/ocd/settings.json" <<'EOF'
{
  "model": "fable",
  "statusLine": {
    "type": "old",
    "command": "old-command",
    "padding": 4,
    "keep": "this field"
  },
  "theme": "dark"
}
EOF

run_installer() {
  HOME="$fixture" \
  DOTFILES_ROOT="$repo_root" \
  CODEX_HOME="$fixture/codex" \
  CLAUDE_HOME="$fixture/claude" \
  CLAUDE_OCD_HOME="$fixture/ocd" \
  CLAUDE_ABCS_HOME="$fixture/abcs" \
    "$script_dir/install.sh" >/dev/null
}

run_installer
snapshot="$fixture/snapshot"
mkdir "$snapshot"
cp "$fixture/codex/config.toml" "$snapshot/codex.toml"
cp "$fixture/claude/settings.json" "$snapshot/claude.json"
cp "$fixture/ocd/settings.json" "$snapshot/ocd.json"
cp "$fixture/abcs/settings.json" "$snapshot/abcs.json"

run_installer
cmp -s "$fixture/codex/config.toml" "$snapshot/codex.toml"
cmp -s "$fixture/claude/settings.json" "$snapshot/claude.json"
cmp -s "$fixture/ocd/settings.json" "$snapshot/ocd.json"
cmp -s "$fixture/abcs/settings.json" "$snapshot/abcs.json"

python3 - "$fixture" <<'PY'
import json
import pathlib
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
codex = tomllib.loads((root / "codex/config.toml").read_text())
assert codex["projects"]["/fixture"]["trust_level"] == "trusted"
assert codex["tui"]["resume_cwd"] == "session"
assert codex["other"]["value"] == "keep"
assert codex["tui"]["status_line"] == [
    "current-dir",
    "git-branch",
    "context-used",
    "five-hour-limit",
    "weekly-limit",
    "model-with-reasoning",
    "task-progress",
]
assert codex["tui"]["status_line_use_colors"] is True

claude = json.loads((root / "claude/settings.json").read_text())
assert claude["hooks"] == {"SessionStart": ["keep this hook"]}
assert claude["model"] == "opus"
assert claude["statusLine"]["type"] == "command"

ocd = json.loads((root / "ocd/settings.json").read_text())
assert ocd["model"] == "fable"
assert ocd["theme"] == "dark"
assert ocd["statusLine"]["padding"] == 4
assert ocd["statusLine"]["keep"] == "this field"

abcs = json.loads((root / "abcs/settings.json").read_text())
assert abcs["statusLine"]["type"] == "command"
PY

status_input='{"model":{"display_name":"Claude Test"},"workspace":{"current_dir":"/tmp"},"context_window":{"context_window_size":200000,"total_input_tokens":1000,"used_percentage":1},"rate_limits":{"five_hour":{"used_percentage":1},"seven_day":{"used_percentage":2}}}'
for settings in "$fixture/claude/settings.json" "$fixture/ocd/settings.json" "$fixture/abcs/settings.json"; do
  configured_command=$(jq -r '.statusLine.command' "$settings")
  printf '%s\n' "$status_input" | eval "$configured_command" | grep -F 'Claude Test' >/dev/null
done

HOME="$fixture" \
DOTFILES_ROOT="$repo_root" \
CODEX_HOME="$fixture/codex" \
CLAUDE_HOME="$fixture/claude" \
CLAUDE_OCD_HOME="$fixture/ocd" \
CLAUDE_ABCS_HOME="$fixture/abcs" \
  "$script_dir/install.sh" --profile ocd --dry-run \
  | grep -F 'profile not selected' >/dev/null

printf 'statusline tests: ok\n'
