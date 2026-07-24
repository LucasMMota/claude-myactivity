# claude-myactivity

> **TL;DR** — Claude Code is a powerful *foundation*, but managing many sessions in
> it is painful: sessions are ephemeral, their files scatter, and reopening a past
> conversation means starting from scratch. **claude-myactivity is a layer on top —
> almost an operating system over Claude Code — that makes session management easy
> and guarantees a fast context bootstrap: reopen any conversation, right where you
> left it, with all its files in one place.** It's a productivity tool.

---

## The problem

Claude Code is excellent at the core task. But the surface around *managing your
work across sessions* is thin, and it hurts in predictable ways:

- **Sessions are ephemeral.** They pile up as anonymous transcripts and become hard
  to manage — you can't easily tell them apart, group them, or find them again.
- **Session files get lost.** Artifacts you generate during a chat (scripts, SQL,
  notes, docs) end up scattered with no home, hard to track down later.
- **The recurring questions:** *"Where is that file I made?"* · *"How do I get the
  context of that session back?"* — and when you can't, you **start everything over**,
  which is slow and costly.

## What it is

Claude Code is the **foundation** — very capable, but not always a friendly
*product* for day-to-day session management. **claude-myactivity is the layer built
on top of it**: an abstraction — think a lightweight *operating system over Claude
Code* — whose whole job is to make sessions easy to manage and, above all, to
**bootstrap context fast** (get a past conversation back in seconds instead of
rebuilding it).

## What it gives you

- **Recover any session — even closed ones.** Reopen a conversation and pick up
  exactly where you left off; go back to a point in time instead of restarting.
- **All of a conversation's files in one place.** Every session gets its own folder
  that collects its artifacts, so nothing gets lost.
- **Pre-created agents.** Persistent "agents" that you open straight from their
  folder — under the hood they're just session folders parked at the root, ready to
  resume with one click.
- **Housekeeping built in.** A `prune` command tidies up (removes empty folders,
  archives the rest into monthly buckets), plus several internal commands to help
  you manage sessions day to day.
- **Fast, one-click resume & fork.** Each folder ships helper scripts that reopen
  the session (by id or name) in a new terminal, or *fork* it into a nested child
  conversation — forming a navigable lineage of your work.

Net effect: a **productivity tool** that turns a pile of ephemeral transcripts into
a browsable, resumable workspace.

## Who is this for?

Heavy Claude Code users — individuals or team leads — who juggle many parallel
conversations and want **traceability, instant resume, and a browsable history**
without manual bookkeeping. If you regularly think *"where did that chat go?"* or
*"let me get that session's context back,"* this is for you.

## How it works (in one breath)

A `SessionStart` hook gives each session its own folder (under `MyActivity/`), tied
to the session id by a marker file, and drops self-contained helper scripts into it.
Those helpers discover the project and session id at runtime, so folders can be
renamed, promoted to the root (as reusable "agents"), or archived freely — the
marker keeps the link between a folder on disk and a conversation in Claude Code.
Internal commands handle resume, fork, prune/archive, and navigation.

---

## Commands & components

The framework surfaces through three kinds of pieces: **slash commands** you type
inside Claude Code, **folder scripts** you run from your terminal, and **automatic
components** that just work in the background.

### Slash commands (inside Claude Code)

| Command | What it does | When to use |
|---|---|---|
| `/pwd` | Prints the absolute path of the **current session's folder** (the one the hook assigned this chat). | You forgot where this session's files are being saved. |
| `/mv-to-work` | Moves the current session's folder into `MyActivity/Work/`, keeping its name. No-op if already there. | A session was created loose or at the root and you want it filed under `Work/`. |
| `/prune-activity [--dry-run]` | Housekeeping in `Work/`: **(1)** deletes empty session folders, **(2)** archives the rest into monthly buckets `Work/YYYY-MM/` by the date in the folder name — **today's folders stay loose**. `--dry-run` previews without changing anything. | Periodic cleanup; keep `Work/` tidy and history grouped by month. |
| `/wrapup [topic]` | Produces a tight **TL;DR** of the current conversation — *Assunto · O que já foi feito · Estado atual · Próximos passos*. Optional `topic` focuses it. | Right after resuming an old session, to re-grasp context fast. |

### Folder scripts (run from your terminal / double-click)

Every session folder ships two self-contained helpers. They figure out the project
root and the session id on their own (from the folder's marker file), so they keep
working even after you rename or move the folder.

- **`resume.sh`** — Reopens **this exact conversation**. Opens a new iTerm window
  (positioned top-right, ~1100×700) at the project root and runs
  `claude --resume <session-id> --name "<alias>"`. This is the *"get me back into
  that chat"* button.
  ```bash
  "MyActivity/Work/My Session - a1b2c3d4 - 24-07-2026/resume.sh"
  ```

- **`fork.sh`** — **Forks** this conversation into a brand-new **child session that
  lives in a sub-folder** of this one. It generates a new session id, creates the
  nested session folder (with its own marker + `resume.sh` + `fork.sh`), seeds the
  child's transcript from this conversation (**full history preserved**), and opens
  an iTerm running `claude --resume <new-id>`. Forks nest recursively, so your
  conversations form a **lineage tree**; `/pwd` inside a fork returns its own
  sub-folder.
  ```bash
  "MyActivity/Work/My Session - a1b2c3d4 - 24-07-2026/fork.sh"
  ```

### Automatic components (no command needed)

- **`SessionStart` hook** (`session-start-activity.sh`) — Runs every time a session
  starts. Creates the session's folder (or re-finds it by marker if it already
  exists — even if you renamed/moved it), drops the marker file and the
  `resume.sh` / `fork.sh` helpers, and injects the folder path into the assistant's
  context so artifacts are saved in the right place.
- **`my-activity` skill** — The naming & organization brain. On the first message of
  a new session it renames the folder with a human-readable alias (and, optionally,
  a ticket-id prefix); it decides where saved artifacts go; and it handles your
  requests to rename, relocate, or find a session folder.

---

## Directory layout

### The framework (what ships)

Packaged as a Claude Code plugin inside a repo that is also its marketplace:

```
claude-myactivity/
├── .claude-plugin/
│   └── marketplace.json          # marketplace catalog (lists the plugin below)
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
│           ├── pwd.md              # /pwd
│           ├── mv-to-work.md       # /mv-to-work
│           ├── prune-activity.md   # /prune-activity
│           └── wrapup.md           # /wrapup
├── README.md
├── LICENSE
└── .gitignore                      # ignores users' own MyActivity/ content
```

| File | What it is |
|---|---|
| `marketplace.json` | Marketplace manifest — lets users `/plugin marketplace add` this repo. |
| `plugin.json` | Plugin manifest — name, version, author; how Claude Code identifies the plugin. |
| `hooks/hooks.json` | Declares the `SessionStart` hook and points it at `scripts/session-start-activity.sh` (via `${CLAUDE_PLUGIN_ROOT}`). |
| `session-start-activity.sh` | The core hook. Creates or re-finds the session folder, writes the marker + `resume.sh` + `fork.sh`, and reports the path. |
| `prune-activity.sh` | Housekeeping script behind `/prune-activity`: deletes empty folders, archives the rest into `Work/YYYY-MM/`. |
| `my-activity/SKILL.md` | Instructions Claude follows to name, rename, relocate, and file session folders. |
| `commands/*.md` | The four slash commands (`/pwd`, `/mv-to-work`, `/prune-activity`, `/wrapup`). |

### A live workspace (what `MyActivity/` looks like as you use it)

```
MyActivity/
├── Data Onboarding Agent/                 # a "root agent": a promoted, reusable session
│   ├── 9f8e7d6c-…-a1b2c3d4e5f6             # marker: full session id (empty file)
│   ├── resume.sh                           # reopen this agent's conversation
│   ├── fork.sh                             # fork it into a nested child session
│   └── Explore Schema - 3c4d5e6f - 24-07-2026/   # a fork nested inside the agent
│       ├── 3c4d5e6f-…                       # its own marker + helpers…
│       ├── resume.sh
│       └── fork.sh
├── Work/                                   # day-to-day sessions
│   ├── Fix Login Bug - a1b2c3d4 - 24-07-2026/    # today → stays loose, at hand
│   │   ├── a1b2c3d4-…                       # marker
│   │   ├── resume.sh
│   │   ├── fork.sh
│   │   └── repro.md                         # ← an artifact you saved this session
│   └── 2026-06/                             # monthly archive bucket (older sessions)
│       └── Migrate API - 7a8b9c0d - 12-06-2026/
│           └── …
└── …
```

| Item | What it is |
|---|---|
| `MyActivity/` | Root of all your session workspaces (local to your machine, git-ignored). |
| `<full-session-uuid>` (empty file) | **The marker.** Durable link between a folder on disk and a conversation in Claude Code. Everything keys off it. |
| `resume.sh` / `fork.sh` | Per-folder helpers (see *Folder scripts* above). |
| your saved files | Artifacts produced during that chat, collected in one place. |
| `<alias> - <short> - <date>/` (nested) | A **fork** — a child session folder living inside its parent (recursive lineage). |
| `Work/` | Where new day-to-day sessions are born. |
| `Work/YYYY-MM/` | Monthly archive buckets created by `/prune-activity`. |
| root-level folders (e.g. `Data Onboarding Agent/`) | **Agents** — sessions you promoted out of `Work/` to reuse; open them via their own `resume.sh`. |

---

## Requirements

- **Claude Code**
- **macOS + iTerm2** — the resume/fork helpers open terminal windows via
  AppleScript. (This first release is macOS + iTerm only.)
- `bash`, `jq`, `uuidgen`, `sed`, `find`, `date` (standard on macOS).

## Status

🚧 **Early / pre-release.** The concept and scripts are working in a real project;
this repo is where they get extracted, genericized, and packaged as an installable
Claude Code plugin (marketplace + `/plugin install`). Packaging and a first-run
setup flow (opt-in ticket convention, window size, etc.) are in progress.

## Install

_Coming soon_ — will be a Claude Code plugin:

```
/plugin marketplace add LucasMMota/claude-myactivity
/plugin install myactivity@claude-myactivity
```

---

*License: TBD.*
