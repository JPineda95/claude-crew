#!/usr/bin/env bash
#
# pre-pr-gate.sh — PreToolUse hook: deterministically gate PR creation.
#
# Blocks `gh pr create` (exit 2 → Claude Code cancels the tool call and feeds
# stderr back to the agent) unless:
#   1. CLAUDE_VALIDATE_CMD (lint + full test suite) is configured AND green,
#   2. CLAUDE_E2E_SMOKE_CMD (optional e2e smoke set) is green when configured,
#   3. the branch's diff doesn't change code while touching zero test files.
#
# It also unconditionally blocks a bare `git push --force`/`-f` on ANY Bash
# call (not just PR creation — this hook fires on every one) — CLAUDE.md
# guardrail 2 forbids force-pushing shared branches. `--force-with-lease` is
# exempt (docs/COMMITS.md sanctions it on your own branch) and is never
# matched by the boundary-anchored pattern below. This check runs even when
# PR_GATE_SKIP is set — it's a hard guardrail, not a testing gate.
#
# CLAUDE_VALIDATE_CMD / CLAUDE_E2E_SMOKE_CMD / CLAUDE_INTEGRATION_BRANCH /
# BLOCK_ON_FAILURE are read from the environment, or from `.claude/crew.env`
# in the directory the gate runs in (RUN_DIR below) if not already exported —
# crew.env is the project's single source of truth for these; set it there,
# or via /onboard.
#
# Overrides — deliberately different trust levels:
#   - PR_GATE_ALLOW_NO_TESTS=1 relaxes check 3 only. Honored from the hook's
#     environment OR inline in the command itself (`PR_GATE_ALLOW_NO_TESTS=1
#     gh pr create …`), so an agent can use it for the narrow no-testable-
#     behavior exemptions — visibly, and it must justify the use in the PR's
#     Testing section (docs/TESTING.md §3).
#   - PR_GATE_SKIP=1 skips the whole gate and is honored ONLY from the hook's
#     environment (settings env / exported shell) — never from the command
#     string. Hooks run with Claude Code's environment, not the command's, so
#     an agent writing `PR_GATE_SKIP=1 gh pr create` gains nothing. Human use
#     only.
#
# Worktrees: a PR opened from a ticket worktree arrives as
# `cd <worktree> && gh pr create …` (leading VAR=value assignments are
# stripped first, so `CI=1 cd <worktree> && …` works too). The gate honors a
# single leading `cd <dir> &&` and runs the validation command AND the diff
# check from that directory — otherwise it would validate whatever branch the
# main checkout happens to be on. Without a cd prefix, creating a PR while the
# current checkout sits on the integration branch is blocked (the diff would
# be empty and the tests-accompany-logic check silently vacuous).
#
# Known accepted limitations: matching is textual. Segment splitting (below)
# doesn't respect quotes — a `&&`/`;`/`|` inside a quoted string still splits
# there — but since detection requires a segment's FIRST word to literally be
# `gh` (or `git`, for the force-push guard), a command that merely quotes the
# phrase (e.g. `git commit -m "before gh pr create"`) is never misidentified:
# that whole thing is one segment whose first word is `git`, not `gh`. Only a
# LEADING `cd <dir> &&` is honored for RUN_DIR resolution — a cd buried
# mid-command is not parsed there. The cd target must be a literal path (`~`
# and a leading $HOME are expanded; other variables are not — the gate blocks
# with a retry hint rather than guessing). PRs opened outside the Bash tool
# (e.g. a GitHub MCP) are not intercepted — the workflow docs remain the gate
# there. Full policy: docs/TESTING.md §5.
#
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

fail() {
  echo "✗ PR BLOCKED: $1" >&2
  exit 2
}

# Extract the actual Bash command from the hook's stdin JSON. Tries jq, then
# python3; if NEITHER is available, fail open (exit 0) rather than treating
# the raw JSON payload as the command — that used to falsely trip both checks
# below on every worktree PR when python3 was missing.
CMD=""
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "${INPUT}" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  CMD="$(printf '%s' "${INPUT}" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass
' 2>/dev/null || true)"
else
  echo "⚠ pre-PR gate: neither jq nor python3 found — can't parse the hook payload; skipping (fail-open)." >&2
  exit 0
fi
[[ -z "${CMD}" ]] && CMD="${INPUT}"

# Split CMD into individual invocations on &&, ||, ;, | (a cheap textual
# split — see the accepted limitations above) and check each segment for:
#   (a) a force-push — blocked unconditionally, on every Bash call;
#   (b) an actual `gh … pr create` invocation (segment's first word is `gh`,
#       not just the phrase appearing somewhere in the text).
IS_PR_CREATE=0
# `|| [[ -n "${SEG}" ]]`: printf produces no trailing newline, so `read`
# reports EOF-with-failure on the final segment even though it populated
# SEG — the extra clause still runs the loop body for that last line.
while IFS= read -r SEG || [[ -n "${SEG}" ]]; do
  [[ -z "${SEG}" ]] && continue
  # Strip leading VAR=value assignments (e.g. `CI=1 gh pr create`).
  while [[ "${SEG}" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do
    SEG="${BASH_REMATCH[1]}"
  done

  if [[ "${SEG}" =~ ^[[:space:]]*git([[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$) ]] \
    && [[ "${SEG}" =~ (^|[[:space:]])(--force|-f)([[:space:]]|$) ]]; then
    fail "git push --force (or -f) is blocked — CLAUDE.md guardrail 2 forbids
force-pushing shared branches. Use --force-with-lease on your own branch
instead (docs/COMMITS.md), or ask the human to force-push."
  fi

  if [[ "${SEG}" =~ ^[[:space:]]*gh([[:space:]]+[^[:space:]]+)*[[:space:]]+pr[[:space:]]+create([[:space:]]|$) ]]; then
    IS_PR_CREATE=1
  fi
done < <(printf '%s' "${CMD}" | sed -E 's/(&&|\|\||;|\|)/\n/g')

if [[ "${IS_PR_CREATE}" -eq 0 ]]; then
  exit 0
fi

if [[ "${PR_GATE_SKIP:-0}" == "1" ]]; then
  echo "⚠ pre-PR gate skipped (PR_GATE_SKIP=1 set in the environment)." >&2
  exit 0
fi

# Honor a single leading `cd <dir> &&` so the gate validates the checkout the
# PR is actually created from (ticket worktrees — docs/WORKTREES.md). Leading
# VAR=value env assignments are stripped before matching.
RUN_DIR="$(pwd)"
CD_PREFIX=0
CMD_HEAD="${CMD}"
while [[ "${CMD_HEAD}" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do
  CMD_HEAD="${BASH_REMATCH[1]}"
done
if [[ "${CMD_HEAD}" =~ ^[[:space:]]*cd[[:space:]]+(\"([^\"]+)\"|\'([^\']+)\'|([^;\&\|[:space:]]+))[[:space:]]*\&\& ]]; then
  CD_DIR="${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[4]}"
  CD_DIR="${CD_DIR/#\~/$HOME}"
  CD_DIR="${CD_DIR/#\$HOME/$HOME}"
  CD_DIR="${CD_DIR/#\$\{HOME\}/$HOME}"
  if [[ "${CD_DIR}" == *'$'* ]]; then
    # Never eval agent-controlled input to expand it — an embedded command
    # substitution would run before the gate decides.
    fail "the command starts with 'cd ${CD_DIR}' — the pre-PR gate can't expand
shell variables in cd targets. Retry with a literal absolute path."
  fi
  if [[ -d "${CD_DIR}" ]]; then
    RUN_DIR="${CD_DIR}"
    CD_PREFIX=1
  else
    fail "the command starts with 'cd ${CD_DIR}' but that directory doesn't exist."
  fi
fi

# Project gate config (CLAUDE_VALIDATE_CMD, CLAUDE_E2E_SMOKE_CMD,
# CLAUDE_INTEGRATION_BRANCH, BLOCK_ON_FAILURE). Loaded before BASE resolution
# below, which reads CLAUDE_INTEGRATION_BRANCH. A value already exported in
# the calling environment wins (crew.env uses ':=' defaults).
[[ -f "${RUN_DIR}/.claude/crew.env" ]] && source "${RUN_DIR}/.claude/crew.env"

# Exact-name check: trusts CLAUDE_INTEGRATION_BRANCH verbatim. Unset, it
# prefers `dev` when the repo has one — the crew never integrates on main
# (CLAUDE.md guardrail 1) — falling back to `main`.
BASE="${CLAUDE_INTEGRATION_BRANCH:-}"
if [[ -z "${BASE}" ]]; then
  if git -C "${RUN_DIR}" rev-parse --verify --quiet "origin/dev" >/dev/null 2>&1 \
    || git -C "${RUN_DIR}" rev-parse --verify --quiet "dev" >/dev/null 2>&1; then
    BASE="dev"
  else
    BASE="main"
  fi
fi
if [[ "${CD_PREFIX}" == "0" ]] \
  && git -C "${RUN_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CURRENT_BRANCH="$(git -C "${RUN_DIR}" branch --show-current 2>/dev/null || true)"
  if [[ -n "${CURRENT_BRANCH}" && "${CURRENT_BRANCH}" == "${BASE}" ]]; then
    fail "this checkout is on the integration branch ('${BASE}') — the gate
would validate the wrong code. Run the command from the branch's checkout
instead: 'cd <ticket-worktree> && gh pr create …' (docs/WORKTREES.md)."
  fi
fi

GATE_CMD="${CLAUDE_VALIDATE_CMD:-}"
if [[ -z "${GATE_CMD}" ]]; then
  fail "no validation gate is configured. Set it in .claude/crew.env (or export
CLAUDE_VALIDATE_CMD — docs/TESTING.md §5, PROJECT.md §3–4), run it green, then
retry. If this project has no test suite yet, run /tests to bootstrap one."
fi

echo "▶ pre-PR gate (in ${RUN_DIR}): ${GATE_CMD}" >&2
if ! (cd "${RUN_DIR}" && bash -lc "${GATE_CMD}") >&2; then
  fail "the validation gate failed. Fix the failures above, then retry 'gh pr create'."
fi

E2E_CMD="${CLAUDE_E2E_SMOKE_CMD:-}"
if [[ -n "${E2E_CMD}" ]]; then
  echo "▶ pre-PR e2e smoke: ${E2E_CMD}" >&2
  if ! (cd "${RUN_DIR}" && bash -lc "${E2E_CMD}") >&2; then
    fail "the e2e smoke suite failed — a core flow may be broken. Fix it, then retry."
  fi
fi

# "Tests accompany logic": refuse code-only diffs with zero test changes.
ALLOW_NO_TESTS="${PR_GATE_ALLOW_NO_TESTS:-0}"
case "${CMD}" in
  *"PR_GATE_ALLOW_NO_TESTS=1"*) ALLOW_NO_TESTS=1 ;;
esac
if [[ "${ALLOW_NO_TESTS}" != "1" ]] \
  && git -C "${RUN_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  RANGE=""
  if git -C "${RUN_DIR}" rev-parse --verify --quiet "origin/${BASE}" >/dev/null; then
    RANGE="origin/${BASE}...HEAD"
  elif git -C "${RUN_DIR}" rev-parse --verify --quiet "${BASE}" >/dev/null; then
    RANGE="${BASE}...HEAD"
  fi
  if [[ -n "${RANGE}" ]]; then
    CHANGED="$(git -C "${RUN_DIR}" diff --name-only "${RANGE}" 2>/dev/null || true)"
    TEST_RE='(^|/)(tests?|__tests__|cypress|e2e|spec)(/|$)|\.(test|spec|cy)\.|_test\.'
    CODE_RE='\.(ts|tsx|js|jsx|mjs|cjs|py|go|rb|rs|java|kt|kts|swift|cs|php|vue|svelte|dart|scala|ex|exs)$'
    code_changed="$(printf '%s\n' "${CHANGED}" | grep -E "${CODE_RE}" | grep -Ev "${TEST_RE}" || true)"
    tests_changed="$(printf '%s\n' "${CHANGED}" | grep -E "${TEST_RE}" || true)"
    if [[ -n "${code_changed}" && -z "${tests_changed}" ]]; then
      fail "this branch changes code but touches no tests:
$(printf '%s\n' "${code_changed}" | head -20)
Write or extend tests first (docs/TESTING.md §3). Only if this change truly has
no testable behavior: retry as 'PR_GATE_ALLOW_NO_TESTS=1 gh pr create …' and
state the reason in the PR's Testing section."
    fi
  fi
fi

echo "✓ pre-PR gate passed." >&2
exit 0
