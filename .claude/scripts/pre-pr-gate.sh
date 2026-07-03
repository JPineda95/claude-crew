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
# Known accepted limitation: matching is textual. A command that merely quotes
# the phrase (e.g. git commit -m "before gh pr create") runs the gate too —
# harmless when green; if it blocks, reword the message. PRs opened outside
# the Bash tool (e.g. a GitHub MCP) are not intercepted — the workflow docs
# remain the gate there. Full policy: docs/TESTING.md §5.
#
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

# Extract the actual Bash command from the hook's stdin JSON (fall back to the
# raw payload if python3 is unavailable).
CMD="$(printf '%s' "${INPUT}" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass
' 2>/dev/null || true)"
[[ -z "${CMD}" ]] && CMD="${INPUT}"

# `gh … pr create` with any flags interposed (e.g. `gh --repo o/r pr create`).
if ! printf '%s' "${CMD}" | grep -Eq '(^|[^[:alnum:]_-])gh[[:space:]]+([^;&|]*[[:space:]])?pr[[:space:]]+create'; then
  exit 0
fi

if [[ "${PR_GATE_SKIP:-0}" == "1" ]]; then
  echo "⚠ pre-PR gate skipped (PR_GATE_SKIP=1 set in the environment)." >&2
  exit 0
fi

fail() {
  echo "✗ PR BLOCKED: $1" >&2
  exit 2
}

GATE_CMD="${CLAUDE_VALIDATE_CMD:-}"
if [[ -z "${GATE_CMD}" ]]; then
  fail "no validation gate is configured. Set CLAUDE_VALIDATE_CMD to 'lint + full
test suite' (docs/TESTING.md §5, PROJECT.md §3–4), run it green, then retry.
If this project has no test suite yet, run /tests to bootstrap one."
fi

echo "▶ pre-PR gate: ${GATE_CMD}" >&2
if ! bash -lc "${GATE_CMD}" >&2; then
  fail "the validation gate failed. Fix the failures above, then retry 'gh pr create'."
fi

E2E_CMD="${CLAUDE_E2E_SMOKE_CMD:-}"
if [[ -n "${E2E_CMD}" ]]; then
  echo "▶ pre-PR e2e smoke: ${E2E_CMD}" >&2
  if ! bash -lc "${E2E_CMD}" >&2; then
    fail "the e2e smoke suite failed — a core flow may be broken. Fix it, then retry."
  fi
fi

# "Tests accompany logic": refuse code-only diffs with zero test changes.
ALLOW_NO_TESTS="${PR_GATE_ALLOW_NO_TESTS:-0}"
case "${CMD}" in
  *"PR_GATE_ALLOW_NO_TESTS=1"*) ALLOW_NO_TESTS=1 ;;
esac
if [[ "${ALLOW_NO_TESTS}" != "1" ]] \
  && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BASE="${CLAUDE_INTEGRATION_BRANCH:-main}"
  RANGE=""
  if git rev-parse --verify --quiet "origin/${BASE}" >/dev/null; then
    RANGE="origin/${BASE}...HEAD"
  elif git rev-parse --verify --quiet "${BASE}" >/dev/null; then
    RANGE="${BASE}...HEAD"
  fi
  if [[ -n "${RANGE}" ]]; then
    CHANGED="$(git diff --name-only "${RANGE}" 2>/dev/null || true)"
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
