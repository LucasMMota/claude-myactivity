---
description: Prune empty MyActivity/Work/ folders and archive the rest into monthly buckets (pass --dry-run to preview)
allowed-tools: Bash(.claude/scripts/prune-activity.sh:*)
---

Run the prune script and report the result to the user.

```
!`.claude/scripts/prune-activity.sh $ARGUMENTS`
```

The script does two things in `Work/`: (1) deletes empty session folders, then
(2) archives the remaining ones into `Work/YYYY-MM/` monthly buckets by the date
in the folder name — **today's folders stay loose** in `Work/`.

If the user passed no arguments, run it for real. If they passed `--dry-run`, it
only previews. Summarize what was pruned and archived (or that nothing changed).
