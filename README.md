# claude-myactivity

> **TL;DR** — A Claude Code plugin that gives **every conversation a persistent
> workspace folder on disk**, with automatic lineage, one-click resume, forking
> into nested sub-sessions, and monthly auto-archiving. Think *"project structure
> + git-style branching for your AI chats."*

---

## What is this?

Claude Code sessions are ephemeral and hard to find again. You don't know where a
conversation's artifacts ended up, you can't reopen *that specific session* without
hunting for its id, and there's no relationship between a chat and the ones that
grew out of it. Your history becomes a pile of anonymous `.jsonl` files.

**claude-myactivity** fixes that. Every session gets its **own folder** (under
`MyActivity/`) tied to its session id by a marker file. From then on, the folder is
the conversation's *home*: it holds the artifacts, knows how to reopen itself, and
knows how to branch.

It is **workflow infrastructure**, not a domain tool — there's nothing about any
specific company or subject in it. Anyone who lives inside Claude Code can use it.

## What it gives you

- **A folder per session** — created automatically at session start (via a
  `SessionStart` hook) and re-found by its marker even if you rename or move the
  folder later.
- **Resume with one click** — each folder gets a `resume.sh` that opens a
  positioned iTerm window and runs `claude --resume` for that session (by id, and
  by the folder's alias/name).
- **Fork into a sub-session** — each folder gets a `fork.sh` that spawns a *child*
  conversation **inside** the parent's folder: full history preserved, its own new
  id. Forks nest recursively, forming a lineage tree of your conversations.
- **Automatic tidying** — a prune script deletes empty session folders and archives
  the rest into monthly buckets (`Work/YYYY-MM/`), keeping today's sessions loose
  and at hand.
- **Readable naming** — human alias in the folder name, matching iTerm tab title,
  and an optional ticket-id prefix (e.g. a Jira key) turned on during setup.

## Who is this for?

Heavy Claude Code users — individuals or team leads — who juggle many parallel
conversations and want **traceability, quick resume, and a browsable history**
without any manual bookkeeping. If you routinely think *"where did that chat go?"*
or *"let me branch this conversation and try another approach,"* this is for you.

## How it works (in one breath)

A `SessionStart` hook creates/re-finds the session folder and drops helper scripts
into it. `resume.sh` and `fork.sh` are self-contained (they discover the project
root and session id at runtime), so folders can be renamed, promoted, or moved
freely. A prune command handles housekeeping. Everything keys off a per-folder
marker file named after the full session id — that's the durable link between a
folder on disk and a conversation in Claude Code.

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
