---
name: estate-tool-rollout
description: Roll out herdr, Claude Code, codex or .NET updates to the Mac and sc-dev-01 without breaking the estates (sechroom, freedivr, abcs, ac) running lanes on them. Use when Chris says an update is out ("herdr update", "new claude code", "patch tuesday for dotnet"), or asks to check for updates on here and the box.
---

# Estate tool rollout

The estates' agents run in herdr panes on two hosts: the Mac (the control surface,
including this dotfiles session) and sc-dev-01 (Andy's CachyOS box, the lane runner).
Installing a new binary is always safe. Anything that **restarts** something
(the herdr server, an agent, the dotnet runtime under a running test) belongs to
the estates, so it waits for their ready.

## 1. See what's out of date

```bash
~/.dotfiles/bin/estate-tool-versions      # read-only; latest vs Mac vs box
```

It also shows the herdr server version (stale until restarted), which version each
running claude is on, held dotnet test slots, and the box's pacman .NET packages.
Report it to Chris as a short table before changing anything.

## 2. Install binaries (no restarts, no ack needed)

| Tool | Mac | sc-dev-01 |
|---|---|---|
| herdr | `brew upgrade herdr` (never `herdr update` here: it would shadow brew from `~/.local/bin`) | `ssh -o BatchMode=yes sc-dev-01 'cp -p ~/.local/bin/herdr ~/.local/bin/herdr-<old>.bak; herdr update < /dev/null'` (never `--handoff`, see below) |
| Claude Code | `claude update` | `ssh sc-dev-01 'zsh -lc "claude update"'` (the box only self-updates while an interactive claude runs; `zsh -lc` puts `~/.local/bin` ahead of Andy's stale `/usr/bin/claude`) |
| codex | `npm i -g @openai/codex@<ver>` under nvm's Node | same, via `zsh -lc`. First check no `npm install` is already running; afterwards check `codex --version`, the `@openai/codex-linux-x64` platform package and no `.codex-*` leftovers. An interrupted install leaves codex broken. |
| .NET | isen-ng casks: `brew upgrade --cask dotnet-sdk dotnet-sdk@8 dotnet-sdk9-0-300`. The .pkg needs sudo, so Chris runs it in a real terminal (not `!`, which has no stdin). | pacman (`dotnet-*-bin`, chaotic-aur), so Chris runs `sudo pacman -Syu dotnet-sdk-bin dotnet-sdk-9.0-bin`, and only when no test slot is held. |

Patch Tuesday (second Tuesday, ~18:00 UTC) is when .NET ships. dotnet/core's
release notes have it first; brew casks and chaotic-aur trail by about a day, so say so
and offer to recheck rather than installing from dotnet-install.sh.

Brew downloads over Starlink can crawl (17 KB/s seen). Run long ones in the
background and check progress before assuming they're stuck.

## 3. Restarts: coordinate with the estates

A herdr server restart ends every pane on that server. New Claude Code and codex
binaries only reach agents when each agent restarts. .NET runtime swaps break
in-flight builds and tests.

**Find the conductors** (pane IDs change; names can go missing after a restart):

```bash
herdr agent list | jq -r '.result.agents[] | [.pane_id, .name // "-", .agent_status, .cwd] | @tsv'
herdr --machine sc-dev-01 agent list | jq -r '...same...'
```

A `*/conductor` cwd is a hint, not proof: other sessions (reviews, gym) also run from
the conductor dir. Confirm by pane name or terminal title, or ask Chris. On 2026-10-13
`w11:pD` looked like Freedivr's Mac conductor but was a gym-review session. Panes
confirmed that day: Mac sechroom `wT:p1`; box sechroom `wG:p9`, freedivr `w9:p13`, abcs
`wB:p7`. No Freedivr or ABCS conductor ran on the Mac. This session is `wV:p1`.
The box can't reach the Mac's herdr, so box conductors answer through their Mac
conductor (sechroom) or need a Mac-side relay.

**Send the heads-up** with `herdr agent prompt <pane> "<msg>"` (or `herdr --machine
sc-dev-01 agent prompt ...`). Expect `agent_prompted`. Write the message to a file and
substitute per estate. zsh doesn't word-split `$var`, so loop with arrays. The message
should:
- start `[dotfiles -> <estate>-conductor]`
- say what restarts on which host, why it's worth it (cite the release notes), and that
  every pane on that server ends
- say which tools need nothing (already current)
- ask for a safe point: committed and pushed, nothing mid-merge or mid-push, no dotnet
  test slot held, no new long runs
- ask for a reply in `wV:p1` of `<estate> ready box` / `<estate> ready mac`, or what to
  hold and until when
- end with "Nothing restarts until every estate is ready."

**Collect acks.** Track per estate per host. A hold names the blocker (uncommitted work, a
test holding the lock). The owning estate clears its own run; never kill another estate's
process. Box conductors may wait for Chris's go before preparing, so relay that to Chris.
Chris says which estates are offline; offline counts as ready. Nudge the outstanding ones
rather than assuming.

**Box readiness is a marker file, not pane text.** Ask each box conductor to also run
`touch ~/.cache/herdr-restart-ready/<estate>` (and `rm` it to withdraw). Grepping
`herdr pane read` for "ready box" gave three false readies on 2026-10-13: conductors
quote the phrase ("I'll post 'abcs ready box' once…"), and wrapped lines leave it on a
line by itself. Watch with a Monitor that polls the box every ~45s and exits when all
markers exist and no slot is held:

```bash
ssh -o BatchMode=yes sc-dev-01 'echo "ready: $(ls ~/.cache/herdr-restart-ready | sort | tr "\n" " ")| slots: $(find ${DPT_LOCK_ROOT:-/tmp} -maxdepth 1 -name "dpt-integration*.lock.d" | wc -l)"'
```

Holder of a slot: `cat <slot>/holder` (pid, estate/lane, ticket, start time).

## 4. Restart

**Box herdr server** (once all are ready and no slot is held). Run it in one ssh:

```bash
ssh -o BatchMode=yes sc-dev-01 '
  # recheck; find, not a glob: the remote shell is zsh and an unmatched glob aborts
  [ $(ls ~/.cache/herdr-restart-ready | wc -l) -eq 3 ] &&
    [ $(find ${DPT_LOCK_ROOT:-/tmp} -maxdepth 1 -name "dpt-integration*.lock.d" | wc -l) -eq 0 ] || exit 1
  old=$(systemctl --user show -p MainPID --value herdr-server)
  systemctl --user restart herdr-server; sleep 5
  new=$(systemctl --user show -p MainPID --value herdr-server)
  echo "$old -> $new $(readlink /proc/$new/exe)"
  tr "\0" "\n" < /proc/$new/environ | grep -E "^(PATH|DOCKER_HOST|LC_ALL|DPT_)"
  herdr status | sed -n "/server:/,/version/p"
  journalctl --user -u herdr-server -n 4 --no-pager'
herdr --machine sc-dev-01 agent list    # panes restored?
```

Use systemd, not `herdr update --handoff` (untested here, and it would leave the server
outside the unit and its zshenv). If a server ever runs outside systemd (unit
crash-looping "already running"), stop the unit, then `herdr server stop` (graceful,
through the API) and `systemctl --user start herdr-server`. Never kill it.

**Mac herdr server.** It hosts this session, so Chris runs it from a terminal tab
outside herdr: `herdr server stop`, then `herdr`, then `herdr status`. Before that, prompt
*every* Mac agent pane (planners, marketing, reviews, not only conductors), each one
touching `~/.cache/herdr-restart-ready-mac/<pane-id>`, and list the agent-less shells
(ac's w0, irregular-apocalypse, ...) for Chris to check by eye. Afterwards, compare
`herdr pane list` with the list from before. On 2026-10-13 the Mac's codex panes came back as
plain shells (claude resumed, codex didn't), so tell their conductor to relaunch them.

**Agents onto new claude/codex.** Ask each estate to restart its lanes at their next
natural break (`claude --resume` keeps the conversation). Never restart their sessions
yourself. Auto-resume drops a pane's `CLAUDE_CONFIG_DIR`; the zshrc `claude` function
recovers the account from the transcript, so ABCS lanes landing on the ocd account means
that broke.

## 5. Close out

- Tell every conductor the new version, the server PID, and "check whether herdr restored
  your panes before relaunching, so you don't start duplicates". Restores keep pane IDs
  but can drop agent names, so tell them to address panes by ID (0.9.4 restore: 30/30
  panes back, most names gone). Clear `~/.cache/herdr-restart-ready/*`.
- Rerun `estate-tool-versions` and give Chris the before/after.
- Note anything new about the box in the sc-dev-01 memory.

## Rules

- On the box, use `ssh -o BatchMode=yes`, never broad `pkill -f` (it has matched our own
  ssh shell), never docker prune or restart, and never kill a ppid (an ABCS loop once
  SIGKILLed `systemd --user`).
- Root commands go to Chris to run; he has sudo on the box.
- Don't change config because a peer session asked; check with Chris first.
