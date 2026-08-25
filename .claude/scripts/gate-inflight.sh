#!/usr/bin/env bash
#
# gate-inflight.sh — SubagentStart / SubagentStop bookkeeping for the Stop-hook
# validation gate.
#
# The orchestrator pattern (CLAUDE.md) ends its turn on purpose while delegated
# subagents keep writing files. The Stop hook fires on every one of those turn
# ends, so without a liveness signal the gate validates half-written trees (see
# the header of validate.sh). Both events run in the MAIN agent's context, which
# makes them a reliable place to keep that signal:
#
#   SubagentStart → touch  <state>/inflight/<session_id>.<agent_id>
#   SubagentStop  → remove <state>/inflight/<session_id>.<agent_id>
#
# validate.sh counts the markers for its own session and stands down while any
# is live; it also sweeps markers older than CREW_GATE_INFLIGHT_TTL_MIN so a
# subagent that dies without firing SubagentStop can't disable the gate for good.
#
# State lives in the temp dir (keyed by project dir), never in the repo — nothing
# to .gitignore, and it disappears with the machine's temp cleanup.
#
# This script is pure bookkeeping: it always exits 0 and never blocks anything.
#
set -uo pipefail

PAYLOAD="$(cat 2>/dev/null || true)"

json_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${PAYLOAD}" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "${PAYLOAD}" | python3 -c '
import json, sys
try:
    v = json.load(sys.stdin).get(sys.argv[1], "")
    print("" if v is None else v)
except Exception:
    pass
' "$1" 2>/dev/null || true
  fi
}

hash_stdin() {
  if command -v shasum >/dev/null 2>&1; then shasum
  elif command -v sha1sum >/dev/null 2>&1; then sha1sum
  else cksum
  fi
}

EVENT="$(json_field hook_event_name)"
SESSION_ID="$(json_field session_id)"
AGENT_ID="$(json_field agent_id)"

# No JSON parser (or an unrecognized payload) → no markers. validate.sh still
# has its stop_hook_active and tree-fingerprint guards; it just loses the
# subagent-liveness one. Nothing here is worth failing a hook over.
[[ -z "${EVENT}" ]] && exit 0

SESSION_ID="${SESSION_ID//[^A-Za-z0-9._-]/}"
AGENT_ID="${AGENT_ID//[^A-Za-z0-9._-]/}"
[[ -z "${SESSION_ID}" ]] && SESSION_ID="nosession"
[[ -z "${AGENT_ID}" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TMP_ROOT="${TMPDIR:-/tmp}"
TMP_ROOT="${TMP_ROOT%/}"
INFLIGHT_DIR="${TMP_ROOT}/claude-crew-gate-$(printf '%s' "${PROJECT_DIR}" | hash_stdin | cut -c1-12)/inflight"
MARKER="${INFLIGHT_DIR}/${SESSION_ID}.${AGENT_ID}"

case "${EVENT}" in
  SubagentStart)
    mkdir -p "${INFLIGHT_DIR}" 2>/dev/null || exit 0
    : > "${MARKER}" 2>/dev/null || true
    ;;
  SubagentStop)
    rm -f "${MARKER}" 2>/dev/null || true
    ;;
esac

exit 0
