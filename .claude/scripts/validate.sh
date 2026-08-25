#!/usr/bin/env bash
#
# validate.sh — the crew's quality gate, run automatically by the Stop hook.
#
# It runs your project's validation command (tests + lint + typecheck + build).
# By default it is NON-BLOCKING and SELF-DISABLING until you configure it, so a
# fresh clone of the boilerplate never breaks. Turn it on in one of two ways:
#
# Configure it by editing `.claude/crew.env` (seeded by install.sh/update.sh;
# `/onboard` writes it for you), or by exporting CLAUDE_VALIDATE_CMD in your
# environment / .claude/settings.local.json env — the env var always wins.
#
# To make a failing gate BLOCK the agent from stopping (recommended once green),
# set BLOCK_ON_FAILURE=1 (also in .claude/crew.env). When blocking, a non-zero
# exit (code 2) feeds the error back to Claude so it fixes the problem instead
# of ending the turn.
#
# WHEN IT DECLINES TO RUN. A Stop hook fires at EVERY turn end, including the
# turns where the orchestrator deliberately pauses mid-task while background
# work (a subagent, a long build) keeps writing files. Running the gate then is
# worse than useless: it validates a half-written tree, always fails, and — when
# blocking — the block forces a new turn that ends the same way, so the whole
# gate re-fires in a loop. Four cheap guards make the gate fire once per
# meaningful state instead (docs/TESTING.md §5.1):
#
#   1. `stop_hook_active` — Claude Code sets this on the stdin payload when the
#      turn only exists because a Stop hook blocked the previous one. We never
#      block twice in a row: one forced continuation is the signal, a second is
#      a loop.
#   2. In-flight subagents — gate-inflight.sh (SubagentStart/SubagentStop)
#      keeps a marker per running subagent. While any is live, the tree belongs
#      to someone else and the gate stays quiet.
#   3. Unchanged working tree — the result is memoized against a fingerprint of
#      the tree + the gate command (both before and after the run, so a gate
#      that leaves artifacts behind doesn't invalidate its own memo). The same
#      state never gets validated (or blocked on) twice.
#   4. CREW_GATE_SKIP=1 in the hook's environment — human escape hatch, same
#      trust level as PR_GATE_SKIP in pre-pr-gate.sh.
#
# None of this weakens the ship gate: pre-pr-gate.sh still runs the same command
# unconditionally before `gh pr create`, and that one cannot be skipped from a
# command string.
#
set -uo pipefail

PAYLOAD="$(cat 2>/dev/null || true)"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# shellcheck source=/dev/null
[[ -f "${PROJECT_DIR}/.claude/crew.env" ]] && source "${PROJECT_DIR}/.claude/crew.env"

VALIDATE_CMD="${CLAUDE_VALIDATE_CMD:-}"
BLOCK_ON_FAILURE="${BLOCK_ON_FAILURE:-0}"
# Minutes after which an in-flight marker is assumed leaked (a subagent that
# died without its SubagentStop hook firing) and ignored.
INFLIGHT_TTL_MIN="${CREW_GATE_INFLIGHT_TTL_MIN:-60}"

note() { echo "$1" >&2; }

# --- helpers ---------------------------------------------------------------

# Top-level field out of the hook's stdin JSON. jq first, then python3; with
# neither, every lookup returns empty and the gate degrades to guard 3 alone
# (which is enough on its own to stop the loop).
json_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${PAYLOAD}" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "${PAYLOAD}" | python3 -c '
import json, sys
try:
    v = json.load(sys.stdin).get(sys.argv[1], "")
    print("" if v is None else ("true" if v is True else "false" if v is False else v))
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

# Per-project state, outside the repo on purpose: no .gitignore entry to ship,
# and it evaporates with the temp dir instead of accumulating in the checkout.
TMP_ROOT="${TMPDIR:-/tmp}"
TMP_ROOT="${TMP_ROOT%/}"
STATE_DIR="${TMP_ROOT}/claude-crew-gate-$(printf '%s' "${PROJECT_DIR}" | hash_stdin | cut -c1-12)"
INFLIGHT_DIR="${STATE_DIR}/inflight"
LAST_RUN_FILE="${STATE_DIR}/last-run"

# --- guard 4: human escape hatch -------------------------------------------

if [[ "${CREW_GATE_SKIP:-0}" == "1" ]]; then
  note "⏭ validation gate skipped (CREW_GATE_SKIP=1 set in the environment)."
  exit 0
fi

# Nothing configured yet → do nothing, don't get in the way.
if [[ -z "${VALIDATE_CMD}" ]]; then
  exit 0
fi

# --- guard 1: never block twice in a row -----------------------------------

if [[ "$(json_field stop_hook_active)" == "true" ]]; then
  note "⏭ validation gate: this turn follows a gate block — not re-running (avoids a Stop loop)."
  exit 0
fi

# --- guard 2: someone else is still writing to the tree --------------------

SESSION_ID="$(json_field session_id)"
SESSION_ID="${SESSION_ID//[^A-Za-z0-9._-]/}"
if [[ -d "${INFLIGHT_DIR}" ]]; then
  # Sweep leaked markers first, then count what's genuinely live. Scoped to
  # this session when we know it, so a second session in the same checkout
  # can't silence this one's gate.
  find "${INFLIGHT_DIR}" -type f -mmin "+${INFLIGHT_TTL_MIN}" -delete 2>/dev/null || true
  if [[ -n "${SESSION_ID}" ]]; then
    INFLIGHT_N="$(find "${INFLIGHT_DIR}" -type f -name "${SESSION_ID}.*" 2>/dev/null | grep -c . || true)"
  else
    INFLIGHT_N="$(find "${INFLIGHT_DIR}" -type f 2>/dev/null | grep -c . || true)"
  fi
  if [[ "${INFLIGHT_N:-0}" -gt 0 ]]; then
    note "⏭ validation gate: ${INFLIGHT_N} subagent(s) still running — the tree is mid-flight, skipping."
    exit 0
  fi
fi

# Only bother when code actually changed in this session's working tree.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git diff --quiet && git diff --cached --quiet \
    && [[ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
    exit 0   # nothing staged, unstaged, or newly added
  fi
fi

# --- guard 3: memoize the verdict per tree state ---------------------------

# Everything the gate's verdict depends on: the command, the tracked diff, and
# the content of new untracked files (capped — a huge untracked set is almost
# always build output, and hashing it every turn would cost more than it saves).
fingerprint() {
  {
    printf 'cmd:%s\n' "${VALIDATE_CMD}"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git status --porcelain=v1 2>/dev/null || true
      git diff HEAD 2>/dev/null || true
      local others count
      others="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
      count="$(printf '%s' "${others}" | grep -c . || true)"
      if [[ "${count:-0}" -gt 0 && "${count:-0}" -le 200 ]]; then
        printf '%s\n' "${others}" | git hash-object --stdin-paths 2>/dev/null || true
      fi
    fi
  } | hash_stdin | cut -d' ' -f1
}

FP="$(fingerprint)"
PREV_FP=""
PREV_RESULT=""
PREV_FP_AFTER=""
if [[ -f "${LAST_RUN_FILE}" ]]; then
  read -r PREV_FP PREV_RESULT _ PREV_FP_AFTER < "${LAST_RUN_FILE}" || true
fi

# Two fingerprints count as "already judged": the tree as it went into the last
# run, and the tree as the run left it — a gate command that drops non-ignored
# artifacts (a build dir, a coverage report) would otherwise invalidate its own
# memo on every single turn.
if [[ -n "${FP}" ]] && [[ "${FP}" == "${PREV_FP}" || "${FP}" == "${PREV_FP_AFTER}" ]]; then
  if [[ "${PREV_RESULT}" == "fail" ]]; then
    note "⏭ validation gate: already red on this exact tree — nothing changed since, not re-running."
  else
    note "⏭ validation gate: already green on this exact tree — not re-running."
  fi
  exit 0
fi

# --- run it ----------------------------------------------------------------

record() {
  mkdir -p "${STATE_DIR}" 2>/dev/null || return 0
  printf '%s %s %s %s\n' "${FP}" "$1" "$(date +%s)" "$(fingerprint)" \
    > "${LAST_RUN_FILE}" 2>/dev/null || true
}

note "▶ Validation gate: ${VALIDATE_CMD}"
if bash -lc "${VALIDATE_CMD}"; then
  note "✓ Validation gate passed."
  record pass
  exit 0
fi

record fail
if [[ "${BLOCK_ON_FAILURE}" == "1" ]]; then
  note "✗ Validation gate FAILED. Fix the failures above before finishing."
  exit 2    # exit 2 → Claude Code feeds stderr back and blocks the stop
fi
note "✗ Validation gate FAILED (advisory — BLOCK_ON_FAILURE is not set)."
exit 0
