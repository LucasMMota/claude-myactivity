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
