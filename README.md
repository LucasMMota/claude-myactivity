# claude-myactivity

> **TL;DR** — Claude Code is a powerful *foundation*, but managing many sessions in
> it is painful: sessions are ephemeral, their files scatter, and reopening a past
> conversation means starting from scratch. **claude-myactivity is a layer on top of
> Claude Code — almost a small operating system for your sessions — that gives every
> conversation a persistent folder, one-click start/resume/fork, and automatic
> tidying, so you can bootstrap a past session's context in seconds.** It's a
> productivity tool.

> ℹ️ **Model:** clone-and-run. You clone this repo, run `./setup.sh` once, and work
> inside the folder — everything is self-contained, nothing is installed globally.
> **First release is macOS + iTerm2 only.**

---

## Contents

- [The problem](#the-problem) · [What it is](#what-it-is) · [Features](#features)
- [Commands](#commands) · [Files & directory layout](#files--directory-layout)
- [Setup — how to start](#setup--how-to-start) · [What it changes on your machine](#what-it-changes-on-your-machine)
- [Requirements](#requirements) · [Status](#status) · [License](#license)

---

## The problem

Claude Code is excellent at the core task. The surface around *managing your work
across sessions*, though, is thin — and it hurts in predictable ways:

- **Sessions are ephemeral.** They pile up as anonymous transcripts; you can't tell
  them apart, group them, or find them again.
- **Session files get lost.** Scripts, notes, and docs you generate during a chat
  scatter with no home and are hard to track down later.
- **The recurring questions:** *"Where's that file I made?"* · *"How do I get that
  session's context back?"* When you can't, you **start over** — slow and costly.

## What it is

Claude Code is the **foundation**: very capable, but not always a friendly *product*
for day-to-day session management. **claude-myactivity is the layer on top of it** —
an abstraction, a lightweight *OS over Claude Code*, whose only job is to make
sessions easy to manage and to **bootstrap context fast**: get a past conversation
back in seconds instead of rebuilding it.

## Features

- **Persistent folder per session.** Every conversation gets its own folder under
  `MyActivity/`, created automatically. All its artifacts live in one place.
- **Start / resume / fork in one click.** Positioned iTerm windows for a new session
  (`new.sh`), reopening a past one (`resume.sh`), or branching one (`fork.sh`).
- **Resume any session — even closed ones.** Reopen a conversation exactly where you
  left off. No hunting for ids.
- **Fork into nested sub-sessions.** Branch a conversation into a child session
  (full history preserved) whose folder nests inside the parent — a navigable
  *lineage tree* of your work.
- **Pre-created "agents".** Promote a session to the root and reuse it as a named
  agent you reopen anytime — it's just a session folder parked at the top level.
- **Automatic housekeeping.** One command removes empty folders and archives the
  rest into monthly buckets, keeping today's work at hand.
- **Readable naming + optional ticket prefix.** Human alias in the folder name and
  matching terminal tab title; opt into a ticket-id prefix during setup.
- **Survives renames/moves.** Each folder is tied to its conversation by a marker
  file, so you can rename, move, or promote folders without breaking resume.

## Commands

### Root launchers (run from your terminal / double-click)

| Script | What it does |
|---|---|
| `./setup.sh` | **First-run setup.** Pure bash, no Claude needed — asks your preferences (ticket convention, iTerm window size), writes `myactivity.config`, and offers to open Claude at the end. Re-run anytime. |
| `./new.sh ["Title"]` | **Start a new conversation** in a positioned iTerm window at the project root. The hook creates its session folder automatically. |

### Slash commands (inside Claude Code)

| Command | What it does | When to use |
|---|---|---|
| `/pwd` | Prints the absolute path of the **current session's folder**. | You forgot where this session's files are saved. |
| `/mv-to-work` | Moves the current session's folder into `MyActivity/Work/` (no-op if already there). | A session was created loose/at the root and you want it filed under `Work/`. |
| `/prune-activity [--dry-run]` | Housekeeping in `Work/`: deletes empty folders, then archives the rest into monthly buckets `Work/YYYY-MM/` — **today's stay loose**. `--dry-run` previews. | Periodic cleanup; group history by month. |
| `/wrapup [topic]` | Prints a tight **TL;DR** of the current conversation. | Right after resuming an old session, to catch up fast. |
| `/myactivity-setup` | Re-runs `./setup.sh` to change your preferences. | Toggle the ticket convention, resize the window, etc. |

### Per-folder scripts (inside each session folder)

Every session folder ships two self-contained helpers. They discover the project
root and session id on their own, so they keep working after you rename/move the
folder.

- **`resume.sh`** — Reopens **this exact conversation** in a positioned iTerm window
  (`claude --resume <id>`). The *"get me back into that chat"* button.
- **`fork.sh`** — **Forks** this conversation into a new **child session inside a
  sub-folder** of this one: mints a new id, creates the nested session folder,
  seeds the child's transcript from this conversation (**full history preserved**),
  and opens an iTerm on the child. Forks nest recursively; `/pwd` inside a fork
  returns its own sub-folder.

### Automatic components (no command needed)

- **`SessionStart` hook** — Runs on every session start. Creates the session's
  folder (or re-finds it by marker, even if renamed/moved), drops the marker +
  `resume.sh` + `fork.sh`, and tells Claude the folder path so artifacts land there.
- **`my-activity` skill** — The naming & organization brain. On a new session's first
  message it renames the folder with a readable alias (and optional ticket prefix);
  decides where saved files go; and handles rename/relocate/find requests.

## Files & directory layout

### What's in the repo

The repo *is* the workspace — you clone it and work inside it.

```
claude-myactivity/
├── .claude/
│   ├── settings.json               # registers the SessionStart hook
│   ├── hooks/
│   │   └── session-start-activity.sh   # the hook: create/reuse folder + helpers
│   ├── scripts/
│   │   └── prune-activity.sh           # prune empties + archive by month
│   ├── skills/
│   │   └── my-activity/SKILL.md        # naming / rename / relocate conventions
│   └── commands/
│       ├── pwd.md · mv-to-work.md · prune-activity.md · wrapup.md · myactivity-setup.md
├── setup.sh                        # first-run setup (writes myactivity.config)
├── new.sh                          # start a new conversation in a positioned iTerm
├── myactivity.config               # your prefs (created by setup.sh; git-ignored)
├── MyActivity/                     # your session workspaces (created at runtime; git-ignored)
├── README.md · LICENSE · .gitignore
```

| File | What it's for |
|---|---|
| `.claude/settings.json` | Registers the `SessionStart` hook so it runs in this workspace. |
| `session-start-activity.sh` | **The core hook.** Creates or re-finds the session folder; writes the marker + `resume.sh` + `fork.sh`; reports the path to Claude. |
| `prune-activity.sh` | Housekeeping behind `/prune-activity`. |
| `my-activity/SKILL.md` | Instructions Claude follows to name, rename, relocate, and file session folders. |
| `commands/*.md` | The slash commands. |
| `setup.sh` / `new.sh` | Root launchers (see *Commands*). |
| `myactivity.config` | Your saved preferences (ticket convention, window size). |

### What it looks like in use (`MyActivity/`)

```
MyActivity/
├── Data Onboarding Agent/                 # a "root agent": a promoted, reusable session
│   ├── 9f8e7d6c-…                          # marker: full session id (empty file)
│   ├── resume.sh · fork.sh
│   └── Explore Schema - 3c4d5e6f - 24-07-2026/   # a fork nested inside the agent
│       └── 3c4d5e6f-… · resume.sh · fork.sh
├── Work/                                   # day-to-day sessions
│   ├── Fix Login Bug - a1b2c3d4 - 24-07-2026/    # today → stays loose
│   │   ├── a1b2c3d4-…                       # marker
│   │   ├── resume.sh · fork.sh
│   │   └── repro.md                         # ← an artifact you saved this session
│   └── 2026-06/                             # monthly archive bucket
│       └── Migrate API - 7a8b9c0d - 12-06-2026/ …
```

| Item | What it is |
|---|---|
| `<full-session-uuid>` (empty file) | **The marker** — the durable link between a folder and a conversation. Everything keys off it. |
| `resume.sh` / `fork.sh` | Per-folder helpers. |
| `<alias> - <short> - <date>/` (nested) | A **fork** — a child session folder inside its parent. |
| `Work/` | Where new day-to-day sessions are born. |
| `Work/YYYY-MM/` | Monthly archive buckets created by `/prune-activity`. |
| root-level folders | **Agents** — sessions promoted out of `Work/` to reuse. |

## Setup — how to start

**Prerequisites:** Claude Code, macOS + iTerm2, and standard CLI tools
(`bash`, `jq`, `uuidgen`, `sed`, `find`, `date`).

```bash
# 1. Clone the repo (this folder becomes your workspace)
git clone https://github.com/LucasMMota/claude-myactivity.git
cd claude-myactivity

# 2. Run first-run setup (pure bash — no Claude needed)
./setup.sh
#    → asks: ticket convention on/off (+ prefix), iTerm window size
#    → writes myactivity.config
#    → offers to open Claude at the end

# 3. Work. Start a session anytime with:
./new.sh
#    (or just run `claude` in this folder)
```

On the **first session**, Claude Code will ask you to approve the project's
`SessionStart` hook — accept it. From then on: a folder is created per session under
`MyActivity/`; save files and they land there; `/pwd` shows where; `resume.sh`
reopens a session; `fork.sh` branches it; `/prune-activity` tidies up.

## What it changes on your machine

Everything is scoped to the **cloned folder** — it does not install into `~/.claude`
or touch your other projects.

**It adds (inside the clone):**
- a **`SessionStart` hook** (declared in `.claude/settings.json`) — Claude Code asks
  you to approve it on first run;
- **slash commands** (`/pwd`, `/mv-to-work`, `/prune-activity`, `/wrapup`,
  `/myactivity-setup`) and the **`my-activity` skill**.

**It creates and writes:**
- `myactivity.config` (your prefs) and a **`MyActivity/` directory**, and per session
  a folder with an empty **marker** + `resume.sh` + `fork.sh`;
- when you **fork**, a copied session transcript under a new id in
  `~/.claude/projects/<project>/` (this is how history is carried into the child);
- when you run **`/prune-activity`**, it moves/removes folders **inside
  `MyActivity/Work/` only**.

**It runs `osascript`** (AppleScript) to open an iTerm window — **only** when you
invoke `new.sh` / `resume.sh` / `fork.sh`.

**It does NOT:** modify your source code or git history, alter Claude Code's existing
transcripts, or touch anything outside the clone (besides the one new fork transcript).

## Requirements

- **Claude Code**
- **macOS + iTerm2** — the launcher scripts open terminal windows via AppleScript.
- `bash`, `jq`, `uuidgen`, `sed`, `find`, `date` (standard on macOS).

## Status

**Working (clone-and-run).** The scripts run in a real project and are in this repo;
clone, `./setup.sh`, and go. This first release is **macOS + iTerm2 only**. Packaging
as an installable Claude Code plugin (marketplace + `/plugin install`) and broader
terminal support are possible future steps.

## License

[MIT](LICENSE) © 2026 Lucas Fonseca.
