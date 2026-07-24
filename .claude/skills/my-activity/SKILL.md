---
name: my-activity
description: Manage per-session activity folders under MyActivity/. On the first user message of a NEW session, rename the folder with a title slug (kept in Work/). Also invoke when the user asks about the session folder, where artifacts were saved, to relocate/rename the folder, or when you need to save an artifact and want to confirm the target path. Folders are created automatically by the SessionStart hook at .claude/hooks/session-start-activity.sh.
---

# my-activity

Every Claude Code session gets its own folder to collect the artifacts produced
during that chat (files the user asked to save, scripts, notes, snippets). This
skill defines how those folders are named, organized, and reused.

## How folders are created

1. **SessionStart hook** (`.claude/hooks/session-start-activity.sh`) runs when a
   session starts.
   - Creates `MyActivity/Work/<shortid> - <dd-mm-yyyy>/` (no alias yet), where
     `shortid` is the first 8 chars of the session id. It drops a **marker file**
     named after the full session id, plus `resume.sh` and `fork.sh` helpers.
   - **Reuse is by marker file, not folder name.** On start it finds this
     session's existing folder by locating the marker file named after the full
     session id (anywhere under `MyActivity/`). So a folder you renamed, moved, or
     promoted to the root is still recognized — it won't spawn a duplicate.
   - **Fork nesting is deterministic.** The hook does no guessing: `fork.sh`
     pre-creates the child folder inside the parent before launching Claude, and
     the hook then finds it by marker. A brand-new session always lands in `Work/`.
   - Injects the folder path into context via `additionalContext`.

2. **After the first user message (NEW session only)**, rename the folder in place,
   prepending a pretty alias:
   - Pattern: `MyActivity/Work/<A Pretty Alias> - <shortid> - <dd-mm-yyyy>/`
   - Example: `MyActivity/Work/Wait Time Bots - abc12345 - 27-05-2026/`
   - Use a single `mv`. Keep it in the **same parent directory** shown in the
     session context (do not move a nested fork out of its parent).
   - **Do not ask** where to put it — new sessions default to `Work/`.

3. **During the session**, any artifact the user asks to save — without an explicit
   path — goes into this folder.

4. **Resumed sessions** (`source=resume`/`clear`) reuse the existing folder for that
   session id; **do not rename or move**.

## Pretty alias rules

- Derived from the **first user message**.
- 2–5 words describing the intent (e.g. `Refactor Auth Flow`, `Debug CI Timeout`).
- **Title Case with spaces** — human-readable, not a slug.
- Strip accents and filesystem-hostile characters (`/ \ : * ? " < > |`).
- Max 40 characters (truncate at a word boundary).

### Optional: ticket id in the folder name

If the session context says the **ticket convention is enabled** (the SessionStart
hook injects this, with a prefix, only when the user turned it on in `setup.sh`):

- When a session is about resolving a ticket, put the ticket key at the **front** of
  the alias: `<TICKET-KEY> <Pretty Alias> - <shortid> - <dd-mm-yyyy>`
  (e.g. `ACME-1234 Fix Login Bug - abc12345 - 27-05-2026`).
- Keep the key uppercase, exactly as the user references it.
- Apply on the first rename if the first message names/links a ticket; otherwise
  rename in place the moment it becomes clear the session is about a ticket.
- If unsure which ticket, ask for the key — do not invent one.

If the context does **not** mention the ticket convention, ignore this entirely.

## Rename / relocate

```bash
mv "MyActivity/Work/abc12345 - 23-04-2026" \
   "MyActivity/Work/Refactor Auth Flow - abc12345 - 23-04-2026"
```

- Promote a session to a reusable **agent**: move its folder to the `MyActivity/`
  root (out of `Work/`). It's still found by its marker on the next start.
- Archive old sessions: `/prune-activity` groups them into `Work/YYYY-MM/`.

## Resume log (optional)

When the user asks for a pointer to reopen the conversation later, the folder's own
`resume.sh` is the durable way (it reads the marker id and runs `claude --resume`).
The marker file (named after the full session id) is what ties the folder to the
conversation for `claude --resume`.
