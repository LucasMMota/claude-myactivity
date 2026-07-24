---
description: Move the current session's MyActivity folder into MyActivity/Work/
allowed-tools: Bash(mv:*), Bash(mkdir:*), Bash(ls:*)
---

Move the **current session's MyActivity folder** (the path from the SessionStart hook context) into `MyActivity/Work/`, keeping the same folder name.

Steps:
1. Resolve the current session folder absolute path from context.
2. If it is already under `MyActivity/Work/`, report that and do nothing.
3. Otherwise: `mkdir -p MyActivity/Work` and `mv "<current_folder>" "MyActivity/Work/"`.
4. Report the new path (code span). Do not rename, prune, or touch any other folder.
