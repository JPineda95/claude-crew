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
set -uo pipefail

[[ -f "${CLAUDE_PROJECT_DIR:-.}/.claude/crew.env" ]] && source "${CLAUDE_PROJECT_DIR:-.}/.claude/crew.env"

VALIDATE_CMD="${CLAUDE_VALIDATE_CMD:-}"
BLOCK_ON_FAILURE="${BLOCK_ON_FAILURE:-0}"

# Nothing configured yet → do nothing, don't get in the way.
if [[ -z "${VALIDATE_CMD}" ]]; then
  exit 0
fi

# Only bother when code actually changed in this session's working tree.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git diff --quiet && git diff --cached --quiet; then
    exit 0   # no changes staged or unstaged
  fi
fi

echo "▶ Validation gate: ${VALIDATE_CMD}" >&2
if bash -lc "${VALIDATE_CMD}"; then
  echo "✓ Validation gate passed." >&2
  exit 0
fi

echo "✗ Validation gate FAILED. Fix the failures above before finishing." >&2
if [[ "${BLOCK_ON_FAILURE}" == "1" ]]; then
  exit 2    # exit 2 → Claude Code feeds stderr back and blocks the stop
fi
exit 0
