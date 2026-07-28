#!/usr/bin/env bash
# SessionStart hook — gives each Claude Code session its own folder under
# MyActivity/ and injects the path into context so artifacts are saved there.
# It also drops two self-contained helpers into the folder: resume.sh (reopen
# this conversation) and fork.sh (branch it into a nested child session).
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(jq -r '.session_id // "unknown"' <<<"$INPUT")

# Project root: prefer CLAUDE_PROJECT_DIR (set by Claude Code), else derive from
# this script's location (.claude/hooks/ -> project root).
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Optional user preferences from ./setup.sh (TICKET_ENABLED, TICKET_PREFIX, WIN_*).
TICKET_ENABLED="false"; TICKET_PREFIX=""
[ -f "$PROJECT_ROOT/myactivity.config" ] && . "$PROJECT_ROOT/myactivity.config"

SHORT_ID="${SESSION_ID:0:8}"
MYACTIVITY_DIR="${PROJECT_ROOT}/MyActivity"
# New day-to-day sessions are born in MyActivity/Work/. Promoted "agents" live
# loose at the MyActivity/ root; monthly archive buckets (YYYY-MM) hold the rest.
WORK_DIR="${MYACTIVITY_DIR}/Work"
mkdir -p "$WORK_DIR"

# Ensure a top-level "start a new session" launcher lives where your sessions are:
# browse into MyActivity/ and run (or double-click) new.sh. Created once.
if [ ! -f "$MYACTIVITY_DIR/new.sh" ]; then
  cat > "$MYACTIVITY_DIR/new.sh" <<'NEW_SH'
#!/usr/bin/env bash
# Start a NEW Claude Code conversation in this workspace: opens a positioned iTerm
# window at the project root and runs `claude`. The SessionStart hook then creates
# the session's folder automatically under MyActivity/Work/.
# Optional: pass a title,  e.g.  ./new.sh "Spike Ideas"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Walk up to the project root (contains .git).
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
NEW_SH
  chmod +x "$MYACTIVITY_DIR/new.sh"
fi

# Re-find this session's folder by its MARKER FILE (full id), not by directory
# name — so a folder you renamed, moved, or promoted is still recognized instead
# of being duplicated.
MARKER=$(find "$MYACTIVITY_DIR" -type f -name "$SESSION_ID" 2>/dev/null | head -n1 || true)
EXISTING=""
[ -n "$MARKER" ] && EXISTING="$(dirname "$MARKER")"

if [ -n "$EXISTING" ]; then
  SESSION_FOLDER="$EXISTING"
  STATUS="existing"
else
  DATE=$(date +%d-%m-%Y)
  # A brand-new session lands in Work/. (Forks are created deterministically by
  # fork.sh, which pre-creates the nested folder with the chosen id; when Claude
  # boots, the marker lookup above finds it and takes the "existing" branch.)
  SESSION_FOLDER="${WORK_DIR}/${SHORT_ID} - ${DATE}"
  mkdir -p "$SESSION_FOLDER"
  # Empty marker file named after the full session id — the durable link between
  # this folder and the conversation, surviving renames.
  touch "$SESSION_FOLDER/${SESSION_ID}"

  # --- resume.sh: reopen THIS conversation in a positioned iTerm window --------
  cat > "$SESSION_FOLDER/resume.sh" <<'RESUME_SH'
#!/usr/bin/env bash
# Reopen this folder's conversation: opens a new iTerm window at the project root
# and runs `claude --resume <id>`. Self-discovers the id from the marker file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Walk up to the project root (contains .git). Robust at any depth.
PROJECT_ROOT="$SCRIPT_DIR"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -d "$PROJECT_ROOT/.git" ]; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

SESSION_ID="$(find "$SCRIPT_DIR" -maxdepth 1 -type f \
  -name '????????-????-????-????-????????????' -exec basename {} \; | head -n1)"
if [ -z "${SESSION_ID:-}" ]; then
  echo "No session marker (UUID) found in: $SCRIPT_DIR" >&2
  exit 1
fi

# Tab title = folder alias (part before " - <id> - <date>").
TAB_TITLE="${SCRIPT_DIR##*/}"; TAB_TITLE="${TAB_TITLE%% - *}"

# Window size: env override > myactivity.config > built-in default.
[ -f "$PROJECT_ROOT/myactivity.config" ] && . "$PROJECT_ROOT/myactivity.config"
WIN_W="${RESUME_WIN_W:-${WIN_W:-1100}}"
WIN_H="${RESUME_WIN_H:-${WIN_H:-700}}"
WIN_MARGIN="${RESUME_WIN_MARGIN:-${WIN_MARGIN:-40}}"

CMD="cd '$PROJECT_ROOT' && claude --resume $SESSION_ID --name '$TAB_TITLE'; echo; echo '[claude exited — window kept for reading]'; exec \$SHELL -il"
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
RESUME_SH
  chmod +x "$SESSION_FOLDER/resume.sh"

  # --- fork.sh: branch THIS conversation into a nested child session -----------
  cat > "$SESSION_FOLDER/fork.sh" <<'FORK_SH'
#!/usr/bin/env bash
# "Fork" this conversation into a NEW session that lives in a SUB-FOLDER of this
# one (recursive session nesting):
#   1. mint a new id and create the nested session folder (marker + helpers);
#   2. seed the new session's transcript by copying this one and rewriting the id
#      (a real fork: history preserved, new id from the start);
#   3. open an iTerm running `claude --resume <new-id>`.
# Because we resume the NEW id directly, SessionStart sees the new id and resolves
# the folder to the sub-folder (so /pwd in the fork returns the sub-folder).
# We deliberately do NOT use --fork-session: with it SessionStart runs under the
# PARENT id and the resolved folder would be wrong.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_ROOT="$SCRIPT_DIR"
while [ "$PROJECT_ROOT" != "/" ] && [ ! -d "$PROJECT_ROOT/.git" ]; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

PARENT_ID="$(find "$SCRIPT_DIR" -maxdepth 1 -type f \
  -name '????????-????-????-????-????????????' -exec basename {} \; | head -n1)"
if [ -z "${PARENT_ID:-}" ]; then
  echo "No session marker (UUID) found in: $SCRIPT_DIR" >&2
  exit 1
fi

# Alias of this folder (the child inherits it).
ALIAS="${SCRIPT_DIR##*/}"; ALIAS="${ALIAS%% - *}"

# Claude Code's transcript dir for this project (encoding: / -> -).
PROJ_DIR="$HOME/.claude/projects/$(printf '%s' "$PROJECT_ROOT" | sed 's#/#-#g')"
PARENT_TX="$PROJ_DIR/$PARENT_ID.jsonl"
if [ ! -f "$PARENT_TX" ]; then
  echo "Parent session transcript not found: $PARENT_TX" >&2
  exit 1
fi

# Create the fork's nested session folder (new id, chosen by us).
NEW_ID="$(uuidgen | tr 'A-Z' 'a-z')"
SHORT_ID="${NEW_ID:0:8}"
DATE="$(date +%d-%m-%Y)"
FORK_DIR="$SCRIPT_DIR/${ALIAS} - ${SHORT_ID} - ${DATE}"
mkdir -p "$FORK_DIR"
touch "$FORK_DIR/$NEW_ID"
[ -f "$SCRIPT_DIR/resume.sh" ] && cp "$SCRIPT_DIR/resume.sh" "$FORK_DIR/resume.sh" && chmod +x "$FORK_DIR/resume.sh"
cp "$SCRIPT_DIR/fork.sh" "$FORK_DIR/fork.sh" && chmod +x "$FORK_DIR/fork.sh"

# Seed the fork's transcript: copy the parent's, rewriting the session id.
sed "s/$PARENT_ID/$NEW_ID/g" "$PARENT_TX" > "$PROJ_DIR/$NEW_ID.jsonl"

# Window size: env override > myactivity.config > built-in default.
[ -f "$PROJECT_ROOT/myactivity.config" ] && . "$PROJECT_ROOT/myactivity.config"
WIN_W="${RESUME_WIN_W:-${WIN_W:-1100}}"
WIN_H="${RESUME_WIN_H:-${WIN_H:-700}}"
WIN_MARGIN="${RESUME_WIN_MARGIN:-${WIN_MARGIN:-40}}"

CMD="cd '$PROJECT_ROOT' && claude --resume $NEW_ID --name '$ALIAS'; echo; echo '[claude exited — window kept for reading]'; exec \$SHELL -il"
CMD_AS=${CMD//\\/\\\\}; CMD_AS=${CMD_AS//\"/\\\"}
TITLE_AS=${ALIAS//\\/\\\\}; TITLE_AS=${TITLE_AS//\"/\\\"}

osascript <<OSA2
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
OSA2

echo "Fork created: ${FORK_DIR#"$PROJECT_ROOT"/}  (id $NEW_ID)"
FORK_SH
  chmod +x "$SESSION_FOLDER/fork.sh"

  STATUS="new"
fi

# Rename target = the folder's own parent dir (Work/ for normal sessions, or the
# parent conversation's folder when this is a nested fork).
PARENT_DIR="$(dirname "$SESSION_FOLDER")"

# Optional ticket-naming rule, injected only when enabled in myactivity.config.
TICKET_NOTE=""
if [ "${TICKET_ENABLED:-false}" = "true" ]; then
  TICKET_NOTE="
Ticket convention is ENABLED (prefix: ${TICKET_PREFIX:-<none>}). If this session is
about resolving a ticket, put the ticket key at the FRONT of the alias
(e.g. \"${TICKET_PREFIX:-KEY}-1234 <Alias>\"), keeping the \" - <shortid> - <date>\" suffix."
fi

MSG=$(cat <<EOF
MyActivity session folder (${STATUS}): ${SESSION_FOLDER}

Follow the my-activity skill for this session:
1. After the first user message in a NEW session (status=new), rename this folder to prepend a pretty alias (keep it in the SAME parent directory shown below — do not move it to Work/ if it is nested inside the folder of another session):
     target: ${PARENT_DIR}/<A Pretty Alias> - ${SHORT_ID} - <dd-mm-yyyy>
     A Pretty Alias = 2-5 words from the first user message, Title Case with spaces, human-readable, max 40 chars.
     use: mv "<current_folder>" "<new_folder>"${TICKET_NOTE}
2. Whenever the user asks you to save a file (script, SQL, note, etc.) without specifying a path, save it inside this folder.
3. If status=existing, the folder was already set up in a prior turn — do not rename, just keep using it.
EOF
)

jq -n --arg msg "$MSG" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $msg}}'
