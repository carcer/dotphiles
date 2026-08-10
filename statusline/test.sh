#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/dotphiles-statusline-test.XXXXXX")
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/codex" "$fixture/claude" "$fixture/ocd" "$fixture/ocd-real" "$fixture/abcs"

test -x "$script_dir/claude-statusline.sh"
test -x "$script_dir/codex-rate-limits.py"
test -x "$script_dir/install.py"
test -x "$script_dir/install.sh"
grep -F 'STATUSLINE_INSTALLER="$DIR/../statusline/install.sh"' "$repo_root/deploy/osx" >/dev/null
grep -F '  "$STATUSLINE_INSTALLER"' "$repo_root/deploy/osx" >/dev/null
! grep -F 'sudo "$STATUSLINE_INSTALLER"' "$repo_root/deploy/osx" >/dev/null

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

cat > "$fixture/ocd-real/settings.json" <<'EOF'
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
chmod 640 "$fixture/ocd-real/settings.json"
ln -s ../ocd-real/settings.json "$fixture/ocd/settings.json"

snapshot="$fixture/snapshot"
mkdir "$snapshot"
cp "$fixture/codex/config.toml" "$snapshot/codex.before.toml"
cp "$fixture/claude/settings.json" "$snapshot/claude.before.json"
cp -L "$fixture/ocd/settings.json" "$snapshot/ocd.before.json"

run_installer() {
  HOME="$fixture" \
  DOTFILES_ROOT="$repo_root" \
  CODEX_HOME="$fixture/codex" \
  CLAUDE_HOME="$fixture/claude" \
  CLAUDE_OCD_HOME="$fixture/ocd" \
  CLAUDE_ABCS_HOME="$fixture/abcs" \
    "$script_dir/install.sh" "$@" >/dev/null
}

run_installer --dry-run
test ! -e "$fixture/codex/config.toml.dotphiles-original"
test ! -e "$fixture/claude/settings.json.dotphiles-original"
test ! -e "$fixture/ocd-real/settings.json.dotphiles-original"
test ! -e "$fixture/abcs/settings.json.dotphiles-original"

run_installer
test -f "$fixture/codex/config.toml.dotphiles-original"
test -f "$fixture/claude/settings.json.dotphiles-original"
test -f "$fixture/ocd-real/settings.json.dotphiles-original"
test ! -e "$fixture/abcs/settings.json.dotphiles-original"
cmp -s "$snapshot/codex.before.toml" "$fixture/codex/config.toml.dotphiles-original"
cmp -s "$snapshot/claude.before.json" "$fixture/claude/settings.json.dotphiles-original"
cmp -s "$snapshot/ocd.before.json" "$fixture/ocd-real/settings.json.dotphiles-original"
backup_identity=$(python3 - "$fixture" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for path in (
    root / "codex/config.toml.dotphiles-original",
    root / "claude/settings.json.dotphiles-original",
    root / "ocd-real/settings.json.dotphiles-original",
):
    stat = path.stat()
    print("%s:%s:%s" % (path, stat.st_ino, stat.st_mtime_ns))
PY
)
cp "$fixture/codex/config.toml" "$snapshot/codex.after.toml"
cp "$fixture/claude/settings.json" "$snapshot/claude.after.json"
cp -L "$fixture/ocd/settings.json" "$snapshot/ocd.after.json"
cp "$fixture/abcs/settings.json" "$snapshot/abcs.json"

run_installer
cmp -s "$fixture/codex/config.toml" "$snapshot/codex.after.toml"
cmp -s "$fixture/claude/settings.json" "$snapshot/claude.after.json"
cmp -s "$fixture/ocd/settings.json" "$snapshot/ocd.after.json"
cmp -s "$fixture/abcs/settings.json" "$snapshot/abcs.json"
cmp -s "$snapshot/codex.before.toml" "$fixture/codex/config.toml.dotphiles-original"
cmp -s "$snapshot/claude.before.json" "$fixture/claude/settings.json.dotphiles-original"
cmp -s "$snapshot/ocd.before.json" "$fixture/ocd-real/settings.json.dotphiles-original"
backup_identity_after=$(python3 - "$fixture" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for path in (
    root / "codex/config.toml.dotphiles-original",
    root / "claude/settings.json.dotphiles-original",
    root / "ocd-real/settings.json.dotphiles-original",
):
    stat = path.stat()
    print("%s:%s:%s" % (path, stat.st_ino, stat.st_mtime_ns))
PY
)
[ "$backup_identity" = "$backup_identity_after" ]

python3 - "$fixture" <<'PY'
import json
import pathlib
import stat
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
assert stat.S_IMODE((root / "ocd-real/settings.json").stat().st_mode) == 0o640
assert stat.S_IMODE((root / "ocd-real/settings.json.dotphiles-original").stat().st_mode) == 0o640
PY

mkdir -p "$fixture/bin" "$fixture/cache"
cat > "$fixture/bin/codex" <<'EOF'
#!/usr/bin/env bash
IFS= read -r initialize
printf '%s\n' '{"id":1,"result":{"userAgent":"fixture"}}'
IFS= read -r rate_limits
printf '%s\n' '{"id":2,"result":{"rateLimits":{"limitId":"codex","primary":{"usedPercent":7,"windowDurationMins":10080,"resetsAt":1893456000},"secondary":null},"rateLimitsByLimitId":{"codex":{"limitId":"codex","primary":{"usedPercent":7,"windowDurationMins":10080,"resetsAt":1893456000},"secondary":null}}}}'
EOF
chmod +x "$fixture/bin/codex"

rate_limit_cache="$fixture/cache/codex-rate-limits.json"
CODEX_BIN="$fixture/bin/codex" \
CODEX_RATE_LIMIT_CACHE="$rate_limit_cache" \
  "$script_dir/codex-rate-limits.py" --refresh
jq -e '
  .rateLimits.primary.usedPercent == 7
  and .rateLimits.primary.windowDurationMins == 10080
  and (.rateLimits | keys | sort) == ["primary", "secondary"]
  and (keys | sort) == ["fetchedAt", "rateLimits"]
  and (.fetchedAt | type == "number")' "$rate_limit_cache" >/dev/null
test "$(stat -f '%Lp' "$rate_limit_cache" 2>/dev/null || stat -c '%a' "$rate_limit_cache")" = 600

status_input='{"model":{"display_name":"Claude Test"},"workspace":{"current_dir":"/tmp"},"context_window":{"context_window_size":200000,"total_input_tokens":1000,"used_percentage":1},"rate_limits":{"five_hour":{"used_percentage":1},"seven_day":{"used_percentage":2,"resets_at":1893456000}}}'
for settings in "$fixture/claude/settings.json" "$fixture/ocd/settings.json" "$fixture/abcs/settings.json"; do
  configured_command=$(jq -r '.statusLine.command' "$settings")
  rendered=$(printf '%s\n' "$status_input" | \
    CODEX_RATE_LIMIT_DISABLE_REFRESH=1 \
    CODEX_RATE_LIMIT_CACHE="$rate_limit_cache" \
    /bin/bash -c "$configured_command")
  printf '%s' "$rendered" | grep -F 'Claude Test' >/dev/null
  printf '%s' "$rendered" | grep -F 'OAI 1% 5h 2% wk' >/dev/null
  ! printf '%s' "$rendered" | grep -F '7% wk' >/dev/null
done

cached_status_input='{"model":{"display_name":"Codex Proxy"},"workspace":{"current_dir":"/tmp"},"context_window":{"context_window_size":200000,"total_input_tokens":1000,"used_percentage":1}}'
cached_rendered=$(printf '%s\n' "$cached_status_input" | \
  CODEX_RATE_LIMIT_DISABLE_REFRESH=1 \
  CODEX_RATE_LIMIT_CACHE="$rate_limit_cache" \
  "$script_dir/claude-statusline.sh")
printf '%s' "$cached_rendered" | grep -F 'OAI 7% wk' >/dev/null
printf '%s' "$cached_rendered" | grep -F 'Codex Proxy' >/dev/null

jq '.fetchedAt = 0' "$rate_limit_cache" > "$fixture/cache/stale.json"
test -z "$(CODEX_RATE_LIMIT_DISABLE_REFRESH=1 \
  CODEX_RATE_LIMIT_CACHE="$fixture/cache/stale.json" \
  "$script_dir/codex-rate-limits.py")"

HOME="$fixture" \
DOTFILES_ROOT="$repo_root" \
CODEX_HOME="$fixture/codex" \
CLAUDE_HOME="$fixture/claude" \
CLAUDE_OCD_HOME="$fixture/ocd" \
CLAUDE_ABCS_HOME="$fixture/abcs" \
  "$script_dir/install.sh" --profile ocd --dry-run \
  | grep -F 'profile not selected' >/dev/null

printf 'statusline tests: ok\n'
