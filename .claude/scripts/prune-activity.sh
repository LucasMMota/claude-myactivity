#!/usr/bin/env bash
# Housekeeping for session folders under MyActivity/Work/. Two steps:
#   1. PRUNE   — delete empty session folders (only marker + resume.sh/fork.sh).
#   2. ARCHIVE — group the rest into monthly buckets Work/YYYY-MM/ by the date in
#                the folder name. TODAY's folders stay loose in Work/.
# Only Work/ is touched — promoted "agents" at the MyActivity/ root are left alone.
# The date is read from the folder name: "... - dd-mm-yyyy" (alias format) or
# "yyyy-mm-dd_..." (legacy). Folders with no recognizable date are left in place.
# Usage:
#   prune-activity.sh            # apply prune + archive
#   prune-activity.sh --dry-run  # list what it would do, change nothing
set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
MYACTIVITY_DIR="${PROJECT_ROOT}/MyActivity"
WORK_DIR="${MYACTIVITY_DIR}/Work"

[ -d "$WORK_DIR" ] || { echo "No MyActivity/Work/ directory found — nothing to do."; exit 0; }

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

TODAY_DMY="$(date +%d-%m-%Y)"
TODAY_YMD="$(date +%Y-%m-%d)"

rel() { echo "${1#"$PROJECT_ROOT"/}"; }

# 1) PRUNE — remove empty session folders (0 files besides the UUID marker and
#    the resume.sh/fork.sh helpers). Folders with fork sub-folders count as
#    non-empty and are preserved.
UUID_RE='.*/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
PRUNED=0
while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  base="$(basename "$dir")"
  [[ "$base" =~ ^[0-9]{4}-[0-9]{2}$ ]] && continue   # never touch month buckets
  if [ -n "$(find -E "$dir" -type f ! -regex "$UUID_RE" ! -name 'resume.sh' ! -name 'fork.sh' -print -quit)" ]; then
    continue
  fi
  PRUNED=$((PRUNED + 1))
  if $DRY_RUN; then
    echo "[dry-run] prune (empty): $(rel "$dir")"
  else
    rm -rf "$dir"
    echo "pruned (empty): $(rel "$dir")"
  fi
done < <(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d)

# 2) ARCHIVE — move remaining folders into Work/YYYY-MM/, except today's.
ARCHIVED=0
while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  base="$(basename "$dir")"
  [[ "$base" =~ ^[0-9]{4}-[0-9]{2}$ ]] && continue   # skip month buckets

  bucket=""; is_today=false
  if [[ "$base" =~ \ -\ ([0-9]{2})-([0-9]{2})-([0-9]{4})$ ]]; then
    dd="${BASH_REMATCH[1]}"; mm="${BASH_REMATCH[2]}"; yyyy="${BASH_REMATCH[3]}"
    bucket="${yyyy}-${mm}"
    [ "${dd}-${mm}-${yyyy}" = "$TODAY_DMY" ] && is_today=true
  elif [[ "$base" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_ ]]; then
    yyyy="${BASH_REMATCH[1]}"; mm="${BASH_REMATCH[2]}"; dd="${BASH_REMATCH[3]}"
    bucket="${yyyy}-${mm}"
    [ "${yyyy}-${mm}-${dd}" = "$TODAY_YMD" ] && is_today=true
  else
    continue   # no recognizable date — leave it
  fi

  $is_today && continue   # keep today's folders loose

  target="${WORK_DIR}/${bucket}"; dest="${target}/${base}"
  if [ -e "$dest" ]; then
    echo "skip (destination exists): $(rel "$dir") -> $(rel "$dest")"
    continue
  fi
  ARCHIVED=$((ARCHIVED + 1))
  if $DRY_RUN; then
    echo "[dry-run] archive: $(rel "$dir") -> Work/${bucket}/"
  else
    mkdir -p "$target"
    mv "$dir" "$dest"
    echo "archived: $(rel "$dir") -> Work/${bucket}/"
  fi
done < <(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d)

if [ "$PRUNED" -eq 0 ] && [ "$ARCHIVED" -eq 0 ]; then
  echo "Nothing to do — no empty folders and nothing to archive."
  exit 0
fi
echo "Summary: ${PRUNED} pruned, ${ARCHIVED} archived."
$DRY_RUN && echo "(dry run — nothing changed; re-run without --dry-run to apply)"
exit 0
