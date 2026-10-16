---
name: estate-tool-rollout
description: Roll out herdr, Claude Code, codex, roslynk or .NET updates to the Mac and the lane runners (sc-dev-01, chris-framework) without breaking the estates (sechroom, freedivr, abcs, ac) running lanes on them. Use when Chris says an update is out ("herdr update", "new claude code", "roslynk is out", "patch tuesday for dotnet"), or asks to check for updates on here and the boxes.
---

# Estate tool rollout

The estates' agents run in herdr panes on three hosts:

| Host | What runs there | Admin |
|---|---|---|
| Mac | conductors, planners, a few Mac lanes, this dotfiles session (`wV:p1`) | Chris |
| sc-dev-01 | Freedivr lanes; ac (stood down) | Andy (Chris has sudo) |
| chris-framework | sechroom (workspace `w2`) and ABCS (`w3`) lanes, since 2026-10-16 | Chris |

The two lane runners are both CachyOS, at Andy's, set up alike: herdr-server under systemd,
Chaotic-AUR .NET, rootless docker, a roslynk daemon, and each with its own dotnet test lock.
Wherever this skill says "the box", do it on **each** lane runner (`for h in sc-dev-01
chris-framework`). The box's estates are that host's estates: readiness, slots and restarts
are per host. sc-dev-01's `~/.zshenv` is a standalone copy, not a dotfiles link, so patch it
by hand whenever zsh/zshenv changes.
Installing a new binary is always safe. Anything that **restarts** something
(the herdr server, an agent, the dotnet runtime under a running test) belongs to
the estates, so it waits for their ready.

## 1. See what's out of date

```bash
~/.dotfiles/bin/estate-tool-versions      # read-only; latest vs Mac vs each lane runner
```

It also shows the herdr server version (stale until restarted), which version each
running claude is on, held dotnet test slots, and the box's pacman .NET packages.
Report it to Chris as a short table before changing anything.

## 2. Install binaries (no restarts, no ack needed)

| Tool | Mac | each lane runner (sc-dev-01, chris-framework) |
|---|---|---|
| herdr | `brew upgrade herdr` (never `herdr update` here: it would shadow brew from `~/.local/bin`) | `ssh -o BatchMode=yes sc-dev-01 'cp -p ~/.local/bin/herdr ~/.local/bin/herdr-<old>.bak; herdr update < /dev/null'` (never `--handoff`, see below) |
| Claude Code | `claude update` | `ssh sc-dev-01 'zsh -lc "claude update"'` (the box only self-updates while an interactive claude runs; `zsh -lc` puts `~/.local/bin` ahead of Andy's stale `/usr/bin/claude`) |
| codex | `npm i -g @openai/codex@<ver>` under nvm's Node | same, via `zsh -lc`. First check no `npm install` is already running; afterwards check `codex --version`, the `@openai/codex-linux-x64` platform package and no `.codex-*` leftovers. An interrupted install leaves codex broken. |
| roslynk (C# MCP server, NuGet global tool) | Keep the old version's files for the servers already running (Roslyn loads assemblies lazily, and `dotnet tool update` deletes the old folder): `S=~/.dotnet/tools/.store; cd ~; cp -cRp $S/roslynk/<old> $S/roslynk-<old>.keep; dotnet tool update -g roslynk; mv $S/roslynk-<old>.keep $S/roslynk/<old>`. Run it from `~`: the update moves `.store/roslynk`, and a cwd inside it fails with a GetCwd exception. | The same via `zsh -lc`, with `cp -al` (hardlinks) instead of `cp -cRp`. |
| .NET | isen-ng casks: `brew upgrade --cask dotnet-sdk dotnet-sdk@8 dotnet-sdk9-0-300`. The .pkg needs sudo, so Chris runs it in a real terminal (not `!`, which has no stdin). The upgrade deletes the previous patch's SDK and runtime, so restart the roslynk daemon afterwards (see below) and tell whoever owns any long-running `dotnet run`. | Lane runners (sc-dev-01, chris-framework): the 10.0 `-bin` set comes from Chaotic-AUR, and 9.0 from the AUR (it isn't in Chaotic-AUR). CachyOS repos sit first in pacman.conf and carry older same-named `-bin` packages, so a plain `-Syu` never takes Chaotic-AUR's update: name the repo. Chris runs, per host and only when no test slot is held there: `sudo pacman -Sy chaotic-aur/dotnet-sdk-bin chaotic-aur/dotnet-runtime-bin chaotic-aur/dotnet-targeting-pack-bin chaotic-aur/aspnet-runtime-bin chaotic-aur/aspnet-targeting-pack-bin && yay -S aur/dotnet-sdk-9.0-bin aur/dotnet-runtime-9.0-bin aur/dotnet-targeting-pack-9.0-bin aur/aspnet-runtime-9.0-bin aur/aspnet-targeting-pack-9.0-bin`. Then check that `dotnet --list-runtimes` has the runtime the SDK needs (SDK 401 ↔ runtime 10.0.12): a split set breaks every build. |

roslynk runs one shared daemon per host (HTTP on 127.0.0.1:6502). Each lane's `roslynk stdio`
is a thin client of it, so `get_solution_status` lists every lane's solutions. On 2026-10-14 the
2.2.0 update broke both daemons: they had been started with their cwd inside
`.store/roslynk/<old>/…/tools/net10.0/any`, and the update deleted that folder. Restoring the
files doesn't restore the cwd, so MSBuild's getcwd failed and every solution showed `Faulted`
("Unable to find the specified file"). After every roslynk update, the daemon therefore has to
restart:
- Find it: `lsof -tiTCP:6502 -sTCP:LISTEN` (Mac) or `ss -ltnp | grep 6502` (box). Check its
  cwd with `lsof -a -p <pid> -d cwd` or `ls -l /proc/<pid>/cwd`.
- Heads-up to the conductors (the lanes' roslynk calls fail for a few seconds). Then Chris
  restarts it: the permission check blocks killing the shared daemon from this session. Run it
  from its own small, empty folder, **never `~`**. Its ASP.NET host recursively watches its
  working directory for appsettings changes. From `~`, that was all of /home/chris on 2026-10-16:
  503k inotify watches, 96% of the limit. Every Roslynk solution watcher after it then got
  ENOSPC and silently stopped syncing files, and .NET 10 never closes those empty watchers on
  dispose (8,144 leaked inotify instances, so `open_solution` failed). An empty folder also can't
  be deleted by an update, unlike the old store folder.
  - box: `systemctl --user stop roslynk-daemon; systemctl --user reset-failed roslynk-daemon;
    mkdir -p ~/.local/state/roslynk && systemd-run --user --unit=roslynk-daemon
    --working-directory=$HOME/.local/state/roslynk -E DOTNET_ROOT=/usr/share/dotnet
    -E DOTNET_hostBuilder__reloadConfigOnChange=false $HOME/.dotnet/tools/roslynk`.
    The transient unit stays loaded as `failed` after a stop, so `reset-failed` must run before
    `systemd-run` can reuse the name. `systemctl --user restart roslynk-daemon` keeps the folder and environment.
  - Mac: `kill -TERM <pid>; mkdir -p ~/.local/state/roslynk && (cd ~/.local/state/roslynk &&
    DOTNET_hostBuilder__reloadConfigOnChange=false nohup ~/.dotnet/tools/roslynk >/dev/null 2>&1 &)`
- Verify that the new daemon maps `roslynk/<new>/tools` and its cwd is `~/.local/state/roslynk`.
  On the box, its inotify handles should all hold watches (`grep -c ^inotify
  /proc/<pid>/fdinfo/<fd>`, none 0) and the user total should be far below
  `fs.inotify.max_user_watches`. Then have a fresh
  client open a real solution and expect `Ready n/n`. Then tell the conductors to `reload_solution`.

The lanes' stdio clients keep the old version until their MCP server restarts (`/mcp` reconnect
or a lane restart). Remove the kept `<old>` store folder once `pgrep -f 'roslynk stdio'` shows no
server older than the update; until then `dotnet tool list -g` lists both versions. Don't use
`roslynk --version`: there is no such flag, and it tries to start a second daemon on 6502.

**herdr agent integrations.** After a herdr upgrade, herdr may say a tool has a "new
version" when what's outdated is its hook for that agent, not the agent. Check with
`herdr integration status` (local only; for the box, ssh in and run it there). Fix with
`herdr integration install codex` (or claude) on each host, after backing up
`~/.codex/herdr-agent-state.sh` and `hooks.json`. It merges into `hooks.json` and keeps the
sechroom hooks. Running agents keep their old hooks until they restart. A new codex
session may ask once to trust the added hooks, so warn the conductors that relaunch
lanes unattended. (2026-10-13: codex hook v8 → v9 came with herdr 0.9.4.)

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
for h in sc-dev-01 chris-framework; do herdr --machine $h agent list | jq -r '...same...'; done
```

A `*/conductor` cwd is a hint, not proof: other sessions (reviews, gym) also run from
the conductor dir. Confirm by pane name or terminal title, or ask Chris. On 2026-10-13
`w11:pD` looked like Freedivr's Mac conductor but was a gym-review session. Panes
confirmed that day: Mac sechroom `wT:p1`; box sechroom `wG:p9`, freedivr `w9:p13`, abcs
`wB:p7`. No Freedivr or ABCS conductor ran on the Mac. By 2026-10-14 all three conductors
had moved to the Mac: sechroom `wT:pY`, abcs `wW:p9` (both named), Freedivr `w11:pG`
(unnamed; its messages are addressed to `conductor-f5`). So re-list every time. This session is `wV:p1`.
Box lanes reach Mac panes only through sc-dev-01's reverse tunnel (`herdr --machine chris-mac`,
conductor-only rule); chris-framework has no tunnel. All three conductors run on the Mac now,
so acks come from Mac panes.

**Send the heads-up** with `herdr agent prompt <pane> "<msg>"` (or `herdr --machine
sc-dev-01 agent prompt ...`). Expect `agent_prompted`. Write the message to a file and
substitute per estate. zsh doesn't word-split `$var`, so loop with arrays. Sessions on the
Mac's ocd account (sechroom, Freedivr) can also be reached with SendMessage, which gives them a
reply channel; get the address from ListAgents each time, because it changes when a session
restarts. ABCS (abcs account) and the box need `herdr agent prompt`. The message
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

**Box readiness is a marker file, not pane text.** Ask each estate's conductor to run, on the
host its lanes are on, `touch ~/.cache/herdr-restart-ready/<estate>` (and `rm` it to withdraw). Grepping
`herdr pane read` for "ready box" gave three false readies on 2026-10-13: conductors
quote the phrase ("I'll post 'abcs ready box' once…"), and wrapped lines leave it on a
line by itself. Watch with a Monitor that polls the box every ~45s and exits when all
markers exist and no slot is held:

```bash
for h in sc-dev-01 chris-framework; do ssh -o BatchMode=yes $h 'echo "$(hostname): ready: $(ls ~/.cache/herdr-restart-ready | sort | tr "\n" " ")| slots: $(find ${DPT_LOCK_ROOT:-/tmp} -maxdepth 1 -name "dpt-integration*.lock.d" | wc -l)"'; done
```

Holder of a slot: `cat <slot>/holder` (pid, estate/lane, ticket, start time).

## 4. Restart

**Box herdr server**, one host at a time, once that host's estates are ready and none of its
slots is held. `N` is that host's estate count (sc-dev-01: freedivr, plus ac when it runs;
chris-framework: sechroom and abcs, so 2). Run it in one ssh, with `H` the host:

```bash
ssh -o BatchMode=yes $H '
  # recheck; find, not a glob: the remote shell is zsh and an unmatched glob aborts
  [ $(ls ~/.cache/herdr-restart-ready | wc -l) -eq N ] &&
    [ $(find ${DPT_LOCK_ROOT:-/tmp} -maxdepth 1 -name "dpt-integration*.lock.d" | wc -l) -eq 0 ] || exit 1
  old=$(systemctl --user show -p MainPID --value herdr-server)
  systemctl --user restart herdr-server; sleep 5
  new=$(systemctl --user show -p MainPID --value herdr-server)
  echo "$old -> $new $(readlink /proc/$new/exe)"
  tr "\0" "\n" < /proc/$new/environ | grep -E "^(PATH|DOCKER_HOST|LC_ALL|DPT_)"
  herdr status | sed -n "/server:/,/version/p"
  journalctl --user -u herdr-server -n 4 --no-pager'
herdr --machine $H agent list    # panes restored?
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

**After a Mac herdr upgrade, re-allow the box's herdr on the Mac.** sc-dev-01 reaches the Mac as
herdr machine `chris-mac`, through the reverse tunnel `bin/herdr-box-tunnel` keeps up (LaunchAgent
`codes.ocd.herdr-box-tunnel`). Its key runs only `bin/herdr-ssh-gate`, which allows herdr's setup
and bridge commands by the SHA-256 of their reviewed text. A new herdr version changes those
scripts, so they're refused. To re-allow them, run `herdr --machine chris-mac agent list` on the
box. Each refusal is logged in `~/Library/Logs/herdr-ssh-gate.log`, and each refused stdin script
is saved under `~/Library/Logs/herdr-ssh-gate-scripts/`. Read every one: it must only run the
herdr binary (or `uname`/`command -v`/`[ -x ]` probes). Then add its hash to `sh_scripts` or
`cmd_hashes`, commit, and retest with `agent list` plus a prompt to the Freedivr conductor.

**A server restart hammers the sechroom-ocd MCP endpoint.** Every restored agent connects to
`https://app.sechroom.ai/api/t/ocd/mcp` within seconds. That's about 25 panes on the box, and
its tools/list is ~1,400 tools and 1.9 MB. On 2026-10-15 that took 5–52 s per call while the
aggregator's youtrack/outline upstreams were failing (SBC-1710). Codex lanes came back with
"timed out awaiting tools/list". Since then every `.codex/config.toml` defining sechroom-ocd has
`required = true` and `startup_timeout_sec = 120`. Without `required`, Codex 0.162 starts with the
server "pending optional" and never gets its tools. With it, a slow aggregator makes Codex
refuse to start. Before a restart, tell the estates to expect this. Afterwards, ask each conductor
to check its Codex lanes have the MCP, and relaunch failures one at a time (`/quit`, check
with `pgrep` that the old process is gone, then `herdr agent start <name> --kind codex --pane
<id> -- resume <session-id>`) rather than all at once.

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
- Root commands go to Chris to run; he has sudo on both lane runners (Andy administers sc-dev-01).
- Don't change config because a peer session asked; check with Chris first.
