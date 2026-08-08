#!/usr/bin/env python3
"""Install the shared Codex and Claude Code status-line wiring.

Only the status-line fields are changed. Existing JSON values and TOML lines
outside those fields are retained byte-for-byte wherever possible.
"""

from __future__ import print_function

import argparse
import json
import os
import re
import shlex
import stat
import sys
import tempfile
from pathlib import Path


CODEX_STATUS_ITEMS = (
    "current-dir",
    "git-branch",
    "context-used",
    "five-hour-limit",
    "weekly-limit",
    "model-with-reasoning",
    "task-progress",
)

TOML_HEADER_RE = re.compile(r"^\s*\[[^\]]+\]")
TUI_HEADER_RE = re.compile(r"^\s*\[tui\]\s*(?:#.*)?(?:\r?\n)?$")
TOML_KEY_RE = {
    "status_line": re.compile(r"^\s*status_line\s*="),
    "status_line_use_colors": re.compile(r"^\s*status_line_use_colors\s*="),
}


def read_text(path):
    with path.open("r", encoding="utf-8", newline="") as handle:
        return handle.read()


def resolved_target(path):
    """Write through a symlink instead of replacing the symlink itself."""

    if path.is_symlink():
        return path.resolve()
    return path


def atomic_write(path, content, mode=None):
    target = resolved_target(path)
    target.parent.mkdir(parents=False, exist_ok=True)
    if mode is None:
        mode = stat.S_IMODE(target.stat().st_mode) if target.exists() else 0o600

    fd, temporary = tempfile.mkstemp(prefix=".%s." % target.name, dir=str(target.parent))
    try:
        os.fchmod(fd, mode)
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.write(content)
        os.replace(temporary, str(target))
    except Exception:
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


def json_top_level_members(content):
    """Return the root object end and its top-level member value spans."""

    decoder = json.JSONDecoder()
    start = len(content) - len(content.lstrip())
    root, root_end = decoder.raw_decode(content, start)
    if not isinstance(root, dict):
        raise RuntimeError("Claude settings must contain a JSON object")

    members = []
    index = start + 1
    while index < root_end - 1:
        while index < root_end and content[index].isspace():
            index += 1
        if index >= root_end - 1:
            break
        key_start = index
        key, index = decoder.raw_decode(content, index)
        if not isinstance(key, str):
            raise RuntimeError("Claude settings contains a non-string JSON key")
        while index < root_end and content[index].isspace():
            index += 1
        if index >= root_end or content[index] != ":":
            raise RuntimeError("invalid JSON member near %s" % key)
        index += 1
        while index < root_end and content[index].isspace():
            index += 1
        value_start = index
        _, value_end = decoder.raw_decode(content, index)
        members.append((key, key_start, value_start, value_end))
        index = value_end
        while index < root_end and content[index].isspace():
            index += 1
        if index < root_end and content[index] == ",":
            index += 1
    return start, root_end, members


def json_fragment(value, indent, newline, compact=False):
    if compact:
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    rendered = json.dumps(value, ensure_ascii=False, indent=2)
    rendered_lines = rendered.splitlines()
    return rendered_lines[0] + "".join(
        newline + indent + line for line in rendered_lines[1:]
    )


def surgical_json_statusline(content, status):
    """Replace or add one root member without reserializing other settings."""

    root_start, root_end, members = json_top_level_members(content)
    newline = "\r\n" if "\r\n" in content else "\n"
    existing = next((member for member in members if member[0] == "statusLine"), None)

    if existing is not None:
        _, key_start, value_start, value_end = existing
        line_start = content.rfind("\n", 0, key_start) + 1
        line_indent = re.match(r"[ \t]*", content[line_start:]).group(0)
        fragment = json_fragment(status, line_indent, newline, "\n" not in content)
        return content[:value_start] + fragment + content[value_end:]

    close = root_end - 1
    pretty = "\n" in content[:root_end]
    if pretty:
        key_indents = []
        for _, key_start, _, _ in members:
            line_start = content.rfind("\n", 0, key_start) + 1
            key_indents.append(re.match(r"[ \t]*", content[line_start:]).group(0))
        indent = key_indents[0] if key_indents else "  "
        fragment = json_fragment(status, indent, newline)
        body_end = close
        while body_end > root_start + 1 and content[body_end - 1] in " \t\r\n":
            body_end -= 1
        if not members:
            return (
                content[: root_start + 1]
                + newline
                + indent
                + '"statusLine": '
                + fragment
                + newline
                + content[close:]
            )
        trailing = content[body_end:close]
        return (
            content[:body_end]
            + ","
            + newline
            + indent
            + '"statusLine": '
            + fragment
            + trailing
            + content[close:]
        )

    fragment = json_fragment(status, "", newline, compact=True)
    if not members:
        return content[: root_start + 1] + '"statusLine":' + fragment + content[close:]
    return content[:close] + ',"statusLine":' + fragment + content[close:]


def patch_claude_settings(path, command, dry_run):
    exists = path.exists()
    if exists:
        original = read_text(path)
        try:
            before = json.loads(original)
        except ValueError as error:
            raise RuntimeError("invalid JSON in %s: %s" % (path, error))
        if not isinstance(before, dict):
            raise RuntimeError("Claude settings must contain a JSON object: %s" % path)
    else:
        if not path.parent.is_dir():
            return "skipped", "profile directory is missing"
        original = "{}\n"
        before = {}

    after = dict(before)
    existing_status = before.get("statusLine")
    if isinstance(existing_status, dict):
        status = dict(existing_status)
        status["type"] = "command"
        status["command"] = command
        if "padding" not in status:
            status["padding"] = 0
    else:
        status = {"type": "command", "command": command, "padding": 0}
    after["statusLine"] = status

    if after == before:
        return "unchanged", "already configured"
    updated = surgical_json_statusline(original, status)
    try:
        if json.loads(updated) != after:
            raise RuntimeError("surgical JSON patch failed validation: %s" % path)
    except ValueError as error:
        raise RuntimeError("surgical JSON patch produced invalid JSON in %s: %s" % (path, error))
    if not dry_run:
        mode = stat.S_IMODE(resolved_target(path).stat().st_mode) if exists else 0o600
        atomic_write(path, updated, mode)
    return "would update" if dry_run else "updated", "statusLine"


def line_ending(content):
    return "\r\n" if "\r\n" in content else "\n"


def render_toml_key(key, newline):
    if key == "status_line":
        lines = ["status_line = ["]
        lines.extend('  "%s",' % item for item in CODEX_STATUS_ITEMS)
        lines.append("]")
    else:
        lines = ["status_line_use_colors = true"]
    return [line + newline for line in lines]


def array_assignment_end(lines, start, section_end):
    """Return the exclusive end of a TOML array assignment."""

    depth = 0
    found_open = False
    in_string = False
    escaped = False
    for index in range(start, section_end):
        line = lines[index]
        for character in line:
            if in_string:
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == '"':
                    in_string = False
                continue
            if character == '"':
                in_string = True
            elif character == "#":
                break
            elif character == "[":
                found_open = True
                depth += 1
            elif character == "]" and found_open:
                depth -= 1
                if depth == 0:
                    return index + 1
    raise RuntimeError("unterminated status_line array in TOML")


def assignment_spans(lines, section_start, section_end):
    spans = {}
    for key, pattern in TOML_KEY_RE.items():
        matches = []
        index = section_start
        while index < section_end:
            if pattern.match(lines[index]):
                end = (
                    array_assignment_end(lines, index, section_end)
                    if key == "status_line"
                    else index + 1
                )
                matches.append((index, end))
                index = end
            else:
                index += 1
        if len(matches) > 1:
            raise RuntimeError("duplicate %s assignments in [tui] in TOML" % key)
        if matches:
            spans[key] = matches[0]
    return spans


def patch_codex_config(path, dry_run):
    exists = path.exists()
    if exists:
        original = read_text(path)
    else:
        if not path.parent.is_dir():
            return "skipped", "Codex directory is missing"
        original = ""
    source = original

    newline = line_ending(original)
    lines = original.splitlines(keepends=True)
    tui_start = None
    section_end = len(lines)
    for index, line in enumerate(lines):
        if TUI_HEADER_RE.match(line):
            tui_start = index
            for next_index in range(index + 1, len(lines)):
                if TOML_HEADER_RE.match(lines[next_index]):
                    section_end = next_index
                    break
            break

    if tui_start is None:
        block = ["[tui]" + newline]
        block.extend(render_toml_key("status_line", newline))
        block.extend(render_toml_key("status_line_use_colors", newline))
        if source and not source.endswith(("\n", "\r")):
            source += newline
        if source and not source.endswith(newline + newline):
            source += newline
        updated = source + "".join(block)
    else:
        spans = assignment_spans(lines, tui_start + 1, section_end)
        section_lines = lines[tui_start + 1 : section_end]
        updated_section = []
        index = 0
        local_spans = {
            key: (start - (tui_start + 1), end - (tui_start + 1))
            for key, (start, end) in spans.items()
        }
        while index < len(section_lines):
            replacement = None
            for key, (start, end) in local_spans.items():
                if index == start:
                    replacement = render_toml_key(key, newline)
                    index = end
                    break
            if replacement is not None:
                updated_section.extend(replacement)
            else:
                updated_section.append(section_lines[index])
                index += 1

        missing = [key for key in TOML_KEY_RE if key not in spans]
        if missing:
            if updated_section and not updated_section[-1].endswith(("\n", "\r")):
                updated_section[-1] += newline
            for key in missing:
                updated_section.extend(render_toml_key(key, newline))

        updated = "".join(lines[: tui_start + 1] + updated_section + lines[section_end:])

    if updated == source:
        return "unchanged", "already configured"
    if not dry_run:
        mode = stat.S_IMODE(resolved_target(path).stat().st_mode) if exists else 0o600
        atomic_write(path, updated, mode)
    return "would update" if dry_run else "updated", "status_line/status_line_use_colors"


def display_result(label, path, result):
    state, detail = result
    print("%s: %s (%s; %s)" % (label, state, path, detail))


def stable_script_command(script, home):
    """Prefer the checkout's stable $HOME-relative path on this Mac."""

    script = script.resolve()
    home = home.resolve()
    try:
        relative = script.relative_to(home).as_posix()
    except ValueError:
        return "bash %s" % shlex.quote(str(script))
    relative = relative.replace("\\", "\\\\").replace('"', '\\"')
    relative = relative.replace("$", "\\$").replace("`", "\\`")
    return 'bash "$HOME/%s"' % relative


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run", action="store_true", help="report changes without writing files"
    )
    parser.add_argument(
        "--no-create-missing-settings",
        action="store_true",
        help="skip a profile whose settings.json does not exist",
    )
    parser.add_argument(
        "--profile",
        dest="profiles",
        action="append",
        choices=("default", "ocd", "abcs"),
        metavar="PROFILE",
        help="select a Claude profile; repeatable, defaults to all three",
    )
    args = parser.parse_args(argv)

    home = Path(os.environ.get("HOME", str(Path.home()))).expanduser()
    root = Path(
        os.environ.get("DOTFILES_ROOT", str(Path(__file__).resolve().parents[1]))
    ).expanduser()
    script = root / "statusline" / "claude-statusline.sh"
    if not script.is_file():
        raise RuntimeError("shared Claude status line is missing: %s" % script)
    command = stable_script_command(script, home)

    codex_home = Path(os.environ.get("CODEX_HOME", str(home / ".codex"))).expanduser()
    codex_config = codex_home / "config.toml"
    if codex_home.is_dir():
        display_result("Codex", codex_config, patch_codex_config(codex_config, args.dry_run))
    else:
        display_result("Codex", codex_config, ("skipped", "Codex directory is missing"))

    profiles = (
        ("default", "Claude", "CLAUDE_HOME", home / ".claude"),
        ("ocd", "Claude OCD", "CLAUDE_OCD_HOME", home / ".claude-ocd"),
        ("abcs", "Claude ABCS", "CLAUDE_ABCS_HOME", home / ".claude-abcs"),
    )
    selected_profiles = set(args.profiles or ("default", "ocd", "abcs"))
    for profile_name, label, environment_name, default_home in profiles:
        if profile_name not in selected_profiles:
            display_result(label, default_home / "settings.json", ("skipped", "profile not selected"))
            continue
        profile_home = Path(os.environ.get(environment_name, str(default_home))).expanduser()
        settings = profile_home / "settings.json"
        if not profile_home.is_dir():
            display_result(label, settings, ("skipped", "profile directory is missing"))
            continue
        if args.no_create_missing_settings and not settings.exists():
            display_result(label, settings, ("skipped", "settings.json is missing"))
            continue
        display_result(label, settings, patch_claude_settings(settings, command, args.dry_run))

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError) as error:
        print("statusline installer: %s" % error, file=sys.stderr)
        sys.exit(1)
