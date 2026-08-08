# Shared agent status lines

This directory owns the status-line pieces shared by the Codex and Claude Code
profiles on each machine. It contains no credentials, session data, or host
names.

Run the normal Mac install from this checkout:

    ./statusline/install.sh

With no profile flags it selects all three Claude profiles. For a deliberate
subset, repeat `--profile` with `default`, `ocd`, or `abcs`:

    ./statusline/install.sh --profile ocd --profile abcs

The installer updates only these fields:

- `~/.codex/config.toml`: `[tui].status_line` and
  `[tui].status_line_use_colors`
- `~/.claude/settings.json`, `~/.claude-ocd/settings.json`, and
  `~/.claude-abcs/settings.json`: `statusLine.type`, `statusLine.command`, and
  `statusLine.padding` when that field is missing

Other JSON values and TOML lines are left in place; the installer replaces only
the selected field values. Existing Claude `padding` values are kept. A
profile directory that doesn't exist is skipped; an existing profile directory
gets a minimal `settings.json` when that profile is selected. Set
`CODEX_HOME`, `CLAUDE_HOME`, `CLAUDE_OCD_HOME`, or `CLAUDE_ABCS_HOME` when a
profile lives somewhere else. Set `DOTFILES_ROOT` when running the installer
from a different checkout.

Before changing an existing target, the installer creates one exact,
mode-preserving sibling backup: `config.toml.dotphiles-original` or
`settings.json.dotphiles-original`. It never overwrites that backup and doesn't
create one for a no-op run or a newly-created ABCS settings file. Symlinks are
resolved before both the target and its backup are written.

The Claude command points back to this checkout, so updating the shared script
using `$HOME/.dotfiles/...` on the normal Mac checkout. A checkout outside
`$HOME` gets a quoted absolute path. Updating the shared script doesn't require
copying a second version into a profile directory. Claude's status input is
read from stdin; `jq`, `git`, and the standard shell tools are required.

Before this migration, OCD was the only profile with a status line. The normal
Mac install enables the same shared renderer for default Claude, OCD, and ABCS;
it doesn't copy any profile settings or account state between them.

`deploy/osx` invokes this installer through its script-relative path, without
`sudo`, after the package steps finish.

To check the installer twice for idempotence:

    ./statusline/test.sh
