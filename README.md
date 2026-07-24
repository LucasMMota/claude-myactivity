# claude-myactivity

> **TL;DR** — Claude Code is a powerful *foundation*, but managing many sessions in
> it is painful: sessions are ephemeral, their files scatter, and reopening a past
> conversation means starting from scratch. **claude-myactivity is a layer on top of
> Claude Code — almost a small operating system for your sessions — that gives every
> conversation a persistent folder, one-click resume/fork, and automatic tidying, so
> you can bootstrap a past session's context in seconds.** It's a productivity tool.

> ⚠️ **Status: early / pre-release.** The scripts work in a real project; this repo is
> where they get genericized and packaged as an installable plugin. The `Setup`
> commands below describe the target flow — see [Status](#status).

---

## Contents

- [The problem](#the-problem)
- [What it is](#what-it-is)
- [Features](#features)
- [Commands](#commands)
- [Files & directory layout](#files--directory-layout)
- [Setup — how to start using it](#setup--how-to-start-using-it)
- [What it changes on your machine](#what-it-changes-on-your-machine)
- [Requirements](#requirements) · [Status](#status) · [License](#license)

---

## The problem

Claude Code is excellent at the core task. The surface around *managing your work
across sessions*, though, is thin — and it hurts in predictable ways:

- **Sessions are ephemeral.** They pile up as anonymous transcripts; you can't tell
  them apart, group them, or find them again.
- **Session files get lost.** Scripts, SQL, notes, and docs you generate during a
  chat scatter with no home and are hard to track down later.
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
- **Resume any session — even closed ones.** Reopen a conversation exactly where you
  left off. No hunting for ids.
- **Fork into nested sub-sessions.** Branch a conversation into a child session
  (full history preserved) whose folder nests inside the parent — a navigable
  *lineage tree* of your work.
- **Pre-created "agents".** Promote a session to the root and reuse it as a named
  agent you reopen anytime — it's just a session folder parked at the top level.
- **Automatic housekeeping.** One command removes empty folders and archives the
  rest into monthly buckets, keeping today's work at hand.
- **Readable naming.** Human alias in the folder name and matching terminal tab
  title; optional ticket-id prefix (e.g. a Jira key) enabled at setup.
- **Survives renames/moves.** Every folder is tied to its conversation by a marker
  file, so you can rename, move, or promote folders freely without breaking resume.

## Commands

The framework surfaces through three kinds of pieces: **slash commands** you type in
Claude Code, **folder scripts** you run from your terminal, and **automatic
components** that work in the background.

### Slash commands (inside Claude Code)

| Command | What it does | When to use |
|---|---|---|
| `/pwd` | Prints the absolute path of the **current session's folder**. | You forgot where this session's files are saved. |
| `/mv-to-work` | Moves the current session's folder into `MyActivity/Work/`, keeping its name (no-op if already there). | A session was created loose/at the root and you want it filed under `Work/`. |
| `/prune-activity [--dry-run]` | Housekeeping in `Work/`: **(1)** deletes empty session folders, **(2)** archives the rest into monthly buckets `Work/YYYY-MM/` by folder-name date — **today's folders stay loose**. `--dry-run` previews. | Periodic cleanup; keep `Work/` tidy and history grouped by month. |
| `/wrapup [topic]` | Prints a tight **TL;DR** of the current conversation — *Assunto · O que já foi feito · Estado atual · Próximos passos*. `topic` focuses it. | Right after resuming an old session, to re-grasp context fast. |

### Folder scripts (run from your terminal / double-click)

Every session folder ships two self-contained helpers. They discover the project
root and session id on their own (from the folder's marker file), so they keep
working after you rename or move the folder.

- **`resume.sh`** — Reopens **this exact conversation**. Opens a new iTerm window
  (top-right, ~1100×700) at the project root and runs
  `claude --resume <session-id> --name "<alias>"`. The *"get me back into that chat"*
  button.
- **`fork.sh`** — **Forks** this conversation into a new **child session inside a
  sub-folder** of this one: generates a new id, creates the nested session folder
  (with its own marker + `resume.sh` + `fork.sh`), seeds the child's transcript from
  this conversation (**full history preserved**), and opens an iTerm on the child.
  Forks nest recursively; `/pwd` inside a fork returns its own sub-folder.

```bash
# from anywhere:
"MyActivity/Work/Fix Login Bug - a1b2c3d4 - 24-07-2026/resume.sh"
"MyActivity/Work/Fix Login Bug - a1b2c3d4 - 24-07-2026/fork.sh"
```

### Automatic components (no command needed)

- **`SessionStart` hook** — Runs on every session start. Creates the session's
  folder (or re-finds it by marker, even if renamed/moved), drops the marker +
  `resume.sh` + `fork.sh`, and tells Claude the folder path so artifacts land there.
- **`my-activity` skill** — The naming & organization brain. On a new session's first
  message it renames the folder with a readable alias (and optional ticket prefix);
  decides where saved files go; and handles rename/relocate/find requests.

## Files & directory layout

### What ships (the plugin repo)

Packaged as a Claude Code plugin inside a repo that is also its marketplace:

```
claude-myactivity/
├── .claude-plugin/
│   └── marketplace.json          # marketplace catalog (lists the plugin)
├── plugins/
│   └── myactivity/
│       ├── .claude-plugin/
│       │   └── plugin.json        # plugin manifest: name, version, author…
│       ├── hooks/
│       │   └── hooks.json         # registers the SessionStart hook
│       ├── scripts/
│       │   ├── session-start-activity.sh   # the hook: create/reuse folder + helpers
│       │   └── prune-activity.sh           # prune empties + archive by month
│       ├── skills/
│       │   └── my-activity/
│       │       └── SKILL.md        # naming / rename / relocate conventions
│       └── commands/
│           ├── pwd.md · mv-to-work.md · prune-activity.md · wrapup.md
├── README.md · LICENSE · .gitignore
```

| File | What it is / what it's for |
|---|---|
| `marketplace.json` | Marketplace manifest — lets users `/plugin marketplace add` this repo. |
| `plugin.json` | Plugin manifest — name, version, author; how Claude Code identifies the plugin. |
| `hooks/hooks.json` | Declares the `SessionStart` hook, pointing at `scripts/session-start-activity.sh` (via `${CLAUDE_PLUGIN_ROOT}`). |
| `session-start-activity.sh` | **The core hook.** Creates or re-finds the session folder; writes the marker + `resume.sh` + `fork.sh`; reports the path to Claude. |
| `prune-activity.sh` | Housekeeping behind `/prune-activity`: deletes empty folders, archives the rest into `Work/YYYY-MM/`. |
| `my-activity/SKILL.md` | Instructions Claude follows to name, rename, relocate, and file session folders. |
| `commands/*.md` | The four slash commands (`/pwd`, `/mv-to-work`, `/prune-activity`, `/wrapup`). |

### What it looks like in use (your `MyActivity/`)

```
MyActivity/
├── Data Onboarding Agent/                 # a "root agent": a promoted, reusable session
│   ├── 9f8e7d6c-…-a1b2c3d4e5f6             # marker: full session id (empty file)
│   ├── resume.sh · fork.sh                 # reopen / fork this agent
│   └── Explore Schema - 3c4d5e6f - 24-07-2026/   # a fork nested inside the agent
│       └── 3c4d5e6f-… · resume.sh · fork.sh
├── Work/                                   # day-to-day sessions
│   ├── Fix Login Bug - a1b2c3d4 - 24-07-2026/    # today → stays loose, at hand
│   │   ├── a1b2c3d4-…                       # marker
│   │   ├── resume.sh · fork.sh
│   │   └── repro.md                         # ← an artifact you saved this session
│   └── 2026-06/                             # monthly archive bucket (older sessions)
│       └── Migrate API - 7a8b9c0d - 12-06-2026/ …
```

| Item | What it is |
|---|---|
| `MyActivity/` | Root of all your session workspaces (local; git-ignored). |
| `<full-session-uuid>` (empty file) | **The marker** — the durable link between a folder and a conversation. Everything keys off it. |
| `resume.sh` / `fork.sh` | Per-folder helpers (see *Folder scripts*). |
| your saved files | Artifacts from that chat, collected in one place. |
| `<alias> - <short> - <date>/` (nested) | A **fork** — a child session folder inside its parent. |
| `Work/` | Where new day-to-day sessions are born. |
| `Work/YYYY-MM/` | Monthly archive buckets created by `/prune-activity`. |
| root-level folders | **Agents** — sessions promoted out of `Work/` to reuse. |

## Setup — how to start using it

**Prerequisites:** Claude Code, macOS + iTerm2, and standard CLI tools
(`bash`, `jq`, `uuidgen`, `sed`, `find`, `date`).

**1. Add the marketplace and install the plugin** (from inside Claude Code):

```
/plugin marketplace add LucasMMota/claude-myactivity
/plugin install myactivity@claude-myactivity
```

Choose the scope when prompted:
- **project** — only this repo gets the session system.
- **user** — every project you open in Claude Code gets it.

**2. First-run setup.** On first use, a short setup asks your preferences (e.g. turn
the ticket-id naming convention on/off and its prefix, iTerm window size). Your
answers are saved to a local config; you can re-run setup anytime.

**3. Just work.** Start (or reload) a session — a folder is created for it
automatically under `MyActivity/`. From then on: save files and they land in that
folder; run `/pwd` to see where; double-click `resume.sh` to reopen it later;
`fork.sh` to branch it; `/prune-activity` to tidy up.

> Until packaging lands (see [Status](#status)), you can also install manually by
> copying the `plugins/myactivity/` contents into your project's `.claude/` and
> registering the hook in `settings.json`. The plugin path above is the intended,
> supported way.

## What it changes on your machine

Transparency on exactly what the framework touches — and what it leaves alone.

**It adds (scoped to where you install — project or user):**
- a **`SessionStart` hook** that runs at the start of every session;
- **four slash commands** (`/pwd`, `/mv-to-work`, `/prune-activity`, `/wrapup`);
- the **`my-activity` skill**.

With the plugin install, these come *from the plugin* — it does **not** edit your own
`settings.json`. (Only the optional manual install adds a hook entry to
`settings.json`.)

**It creates and writes:**
- a **`MyActivity/` directory** in your project, and per session a folder containing
  an empty **marker** file + `resume.sh` + `fork.sh`;
- when you **fork**, a copied session transcript under a new id in
  `~/.claude/projects/<project>/` (this is how history is carried into the child);
- when you run **`/prune-activity`**, it moves/removes folders **inside
  `MyActivity/Work/` only**.

**It reads:**
- the session id and transcript path that Claude Code passes to the hook.

**It runs:**
- `osascript` (AppleScript) to open an iTerm window — **only** when you invoke
  `resume.sh` / `fork.sh`.

**It does NOT:**
- modify your source code or your git repository;
- delete or alter Claude Code's existing transcripts;
- touch anything outside `MyActivity/` and the single new fork-transcript file.

## Requirements

- **Claude Code**
- **macOS + iTerm2** — the resume/fork helpers open terminal windows via AppleScript.
  (This first release is macOS + iTerm only.)
- `bash`, `jq`, `uuidgen`, `sed`, `find`, `date` (standard on macOS).

## Status

🚧 **Early / pre-release.** The concept and scripts are working in a real project;
this repo is where they get extracted, genericized, and packaged as an installable
Claude Code plugin (marketplace + `/plugin install`), including the first-run setup
flow. Until then, the `Setup` commands describe the target experience.

## License

[MIT](LICENSE) © 2026 Lucas Fonseca.
