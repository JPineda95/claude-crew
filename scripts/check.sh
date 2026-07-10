#!/usr/bin/env bash
#
# check.sh — this repo's own validation gate (what CLAUDE_VALIDATE_CMD would
# be for a consuming project, but for claude-crew itself). Run before every
# PR; re-run by .github/workflows/gate.yml on every PR to dev/main.
#
# Usage:
#   scripts/check.sh
#
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${SRC}" || exit 1

FAIL=0
fail() { echo "✗ $1" >&2; FAIL=1; }
ok()   { echo "✓ $1"; }

echo "== bash -n (syntax) =="
SYNTAX_OK=1
for f in scripts/*.sh .claude/scripts/*.sh; do
  bash -n "${f}" || { fail "syntax error: ${f}"; SYNTAX_OK=0; }
done
[[ "${SYNTAX_OK}" -eq 1 ]] && ok "all scripts parse"

echo
echo "== shellcheck (warning and above; info-level style nits don't fail) =="
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning scripts/*.sh .claude/scripts/*.sh; then
    ok "shellcheck clean at -S warning"
  else
    fail "shellcheck found warning-or-above issues (see above)"
  fi
else
  echo "  shellcheck not installed — skipping locally (required in CI)." >&2
fi

echo
echo "== scripts/build-plugin.sh (also syncs + checks plugin/marketplace/CHANGELOG version consistency) =="
if bash scripts/build-plugin.sh >/tmp/claude-crew-build.log 2>&1; then
  ok "build-plugin.sh succeeded (includes the version-consistency check)"
else
  fail "build-plugin.sh failed:"
  cat /tmp/claude-crew-build.log >&2
fi
rm -f /tmp/claude-crew-build.log

echo
if [[ "${FAIL}" -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "One or more checks failed — see ✗ lines above." >&2
  exit 1
fi
