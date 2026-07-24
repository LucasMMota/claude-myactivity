#!/usr/bin/env bash
# Start a NEW Claude Code conversation in this workspace: opens a positioned iTerm
# window at the project root and runs `claude`. The SessionStart hook then creates
# the session's folder automatically under MyActivity/Work/.
# Optional: pass a title, e.g.  ./new.sh "Spike Ideas"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root = where this script lives (repo root); fall back to a .git walk.
PROJECT_ROOT="$SCRIPT_DIR"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -d "$PROJECT_ROOT/.git" ]; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ -d "$PROJECT_ROOT/.git" ] || PROJECT_ROOT="$SCRIPT_DIR"

TAB_TITLE="${1:-${PROJECT_ROOT##*/}}"

# Window size: env override > myactivity.config > built-in default.
[ -f "$PROJECT_ROOT/myactivity.config" ] && . "$PROJECT_ROOT/myactivity.config"
WIN_W="${RESUME_WIN_W:-${WIN_W:-1100}}"
WIN_H="${RESUME_WIN_H:-${WIN_H:-700}}"
WIN_MARGIN="${RESUME_WIN_MARGIN:-${WIN_MARGIN:-40}}"

# Fresh session (no --resume): the hook creates the folder in Work/.
CMD="cd '$PROJECT_ROOT' && claude --name '$TAB_TITLE'; echo; echo '[claude exited — window kept for reading]'; exec \$SHELL -il"
CMD_AS=${CMD//\\/\\\\}; CMD_AS=${CMD_AS//\"/\\\"}
TITLE_AS=${TAB_TITLE//\\/\\\\}; TITLE_AS=${TITLE_AS//\"/\\\"}

osascript <<OSA
tell application "Finder" to set sb to bounds of window of desktop
set screenW to item 3 of sb
set winW to $WIN_W
set winH to $WIN_H
set marginT to $WIN_MARGIN
set leftX to screenW - winW
if leftX < 0 then set leftX to 0
tell application "iTerm"
  activate
  set newWin to (create window with default profile)
  try
    set fullscreen of newWin to false
  end try
  delay 0.2
  set bounds of newWin to {leftX, marginT, leftX + winW, marginT + winH}
  tell current session of newWin
    set name to "$TITLE_AS"
    write text "$CMD_AS"
  end tell
end tell
OSA
