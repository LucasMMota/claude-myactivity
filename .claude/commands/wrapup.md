---
description: TL;DR wrap-up of the current conversation (run manually when you need to catch up)
---

Produce a brief **wrap-up (TL;DR)** of the current conversation so the user can quickly
re-grasp the context. Keep it tight — this is a catch-up summary, not a report.

Structure the response as:

- **Subject** — one line on what this conversation is about.
- **Done so far** — 3–6 bullets of the concrete actions/decisions taken.
- **Current state** — where things stand right now (done vs. in progress).
- **Next steps / open items** — what's left to decide or do (if any).

Rules:
- Match the user's language (if they've been writing in another language, use it).
- Be concrete: name files, commands, branches, decisions — not vague summaries.
- No preamble, no "here is your summary". Start straight at **Subject**.
- Base it strictly on this conversation's history; do not invent or re-run work.
- If `$ARGUMENTS` is provided, focus the wrap-up on that topic/aspect.
