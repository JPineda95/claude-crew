#!/usr/bin/env bash
#
# test-stop-gate.sh — behavior tests for the Stop-hook validation gate
# (.claude/scripts/validate.sh + .claude/scripts/gate-inflight.sh).
#
# Run by scripts/check.sh, so CI runs it too. It builds a throwaway git repo,
# drives the two hook scripts with synthetic Claude Code payloads, and asserts
# on both the exit code AND how many times the gate command actually ran —
# the second half is the point: the bug this suite locks down was the gate
# re-running the full test+lint+build on turns where nothing had changed.
#
# Usage:
#   scripts/test-stop-gate.sh
#
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE="${SRC}/.claude/scripts/validate.sh"
INFLIGHT="${SRC}/.claude/scripts/gate-inflight.sh"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "${SANDBOX}"' EXIT

REPO="${SANDBOX}/repo"
# Harness state lives OUTSIDE the repo on purpose — anything it wrote inside
# would surface as an untracked change and defeat the memoization under test.
RUNS="${SANDBOX}/runs"
export CLAUDE_PROJECT_DIR="${REPO}"
export TMPDIR="${SANDBOX}/tmp"
# The gate reads these from the environment when crew.env doesn't set them;
# a value inherited from the developer's shell would skew every assertion.
unset CLAUDE_VALIDATE_CMD BLOCK_ON_FAILURE CREW_GATE_SKIP CREW_GATE_INFLIGHT_TTL_MIN

mkdir -p "${REPO}" "${TMPDIR}"
cd "${REPO}" || exit 1
git init -q .
git config user.email test@example.com
git config user.name Test
echo base > file.txt
git add -A && git commit -qm init
mkdir -p .claude

PASS=0
FAIL=0

# Rewrite the project's gate config. The gate command always leaves a mark in
# ${RUNS} so the harness can count real invocations.
write_env() { # $1 = shell command the gate should run, $2 = BLOCK_ON_FAILURE
  cat > .claude/crew.env <<EOF
: "\${CLAUDE_VALIDATE_CMD:=echo x >> '${RUNS}'; ${1}}"
: "\${BLOCK_ON_FAILURE:=${2}}"
export CLAUDE_VALIDATE_CMD BLOCK_ON_FAILURE
EOF
}

runs() { if [[ -f "${RUNS}" ]]; then grep -c . "${RUNS}"; else echo 0; fi; }

stop_payload() { # $1 = stop_hook_active
  printf '{"session_id":"sess1","hook_event_name":"Stop","cwd":"%s","stop_hook_active":%s}' \
    "${REPO}" "$1"
}

subagent() { # $1 = SubagentStart|SubagentStop, $2 = agent_id
  printf '{"session_id":"sess1","hook_event_name":"%s","agent_id":"%s"}' "$1" "$2" \
    | bash "${INFLIGHT}"
}

check() { # $1 = name, $2 = expected exit, $3 = expected gate runs, $4 = stop_hook_active (default false)
  local name="$1" want_exit="$2" want_runs="$3" active="${4:-false}"
  local before after got_runs out code
  before="$(runs)"
  out="$(stop_payload "${active}" | bash "${VALIDATE}" 2>&1)"
  code=$?
  after="$(runs)"
  got_runs=$(( after - before ))
  if [[ "${code}" == "${want_exit}" && "${got_runs}" == "${want_runs}" ]]; then
    echo "  ✓ ${name} (exit ${code}, gate ran ${got_runs}x)"
    PASS=$((PASS + 1))
  else
    echo "  ✗ ${name}: expected exit ${want_exit} and ${want_runs} gate run(s), got exit ${code} and ${got_runs}" >&2
    echo "     hook output: ${out}" >&2
    FAIL=$((FAIL + 1))
  fi
}

echo "== Stop-hook gate behavior =="

echo "1. unconfigured project"
check "no CLAUDE_VALIDATE_CMD → silent no-op" 0 0

echo "2. configured, clean tree"
write_env "false" 1
git add -A && git commit -qm crew-env
check "nothing changed → skipped" 0 0

echo "3. dirty tree, red gate, BLOCK_ON_FAILURE=1"
echo change >> file.txt
check "first red verdict → blocks the stop (exit 2)" 2 1

echo "4. the loop this suite exists to prevent"
check "same tree next turn → memoized, no re-run" 0 0
check "and the turn after that → still no re-run" 0 0

echo "5. stop_hook_active"
echo more >> file.txt
check "turn follows a block → stands down" 0 0 true
check "same tree, normal turn → runs and blocks" 2 1

echo "6. in-flight subagents"
subagent SubagentStart agent-one
subagent SubagentStart agent-two
echo yet-more >> file.txt
check "2 subagents writing → skipped" 0 0
subagent SubagentStop agent-one
check "1 still writing → skipped" 0 0
subagent SubagentStop agent-two
check "all finished → runs" 2 1

echo "7. untracked-only changes"
write_env "true" 1
echo new > brand-new.txt
check "new untracked file, green gate → runs and passes" 0 1
check "unchanged since → memoized" 0 0
echo edit >> brand-new.txt
check "untracked file edited → re-runs" 0 1

echo "8. leaked in-flight marker"
subagent SubagentStart ghost-agent
find "${TMPDIR}" -type f -name 'sess1.ghost-agent' -exec touch -t 200001010000 {} + 2>/dev/null
echo x >> file.txt
check "marker older than the TTL → swept, gate runs" 0 1

echo "9. a gate command that leaves artifacts in the tree"
write_env "mkdir -p build && date +%s > build/out.txt" 1
git add -A && git commit -qm crew-env-2
echo z >> file.txt
check "artifact-producing gate → runs once" 0 1
check "artifacts alone don't invalidate the memo" 0 0
check "still memoized a turn later" 0 0

echo "10. CREW_GATE_SKIP escape hatch"
echo y >> file.txt
if stop_payload false | CREW_GATE_SKIP=1 bash "${VALIDATE}" >/dev/null 2>&1; then
  echo "  ✓ CREW_GATE_SKIP=1 → exit 0"
  PASS=$((PASS + 1))
else
  echo "  ✗ CREW_GATE_SKIP=1 should exit 0" >&2
  FAIL=$((FAIL + 1))
fi

echo
if [[ "${FAIL}" -eq 0 ]]; then
  echo "Stop-hook gate: ${PASS} checks passed."
  exit 0
fi
echo "Stop-hook gate: ${FAIL} of $((PASS + FAIL)) checks FAILED." >&2
exit 1
