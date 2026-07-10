#!/usr/bin/env bash
#
# vendor-skills.sh — normalize vendored-skill paths after `npx skills add`/`update`.
#
# The impeccable skill (pbakaus/impeccable) hardcodes `.agents/skills/` paths
# throughout its SKILL.md, reference docs, and scripts — that's upstream's own
# layout. This crew vendors it at `.claude/skills/` instead, so those literal
# paths are wrong in every consuming install (its own setup step fails with
# module-not-found). Run this after any `npx skills add impeccable` or
# `npx skills update impeccable` to re-normalize the committed copy.
#
# Usage:
#   scripts/vendor-skills.sh
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMPECCABLE="${SRC}/.claude/skills/impeccable"

if [[ ! -d "${IMPECCABLE}" ]]; then
  echo "error: ${IMPECCABLE} not found — nothing to normalize." >&2
  exit 1
fi

rewrite() {
  local f="$1" tmp
  tmp="$(mktemp)"
  sed 's#\.agents/skills/#.claude/skills/#g' "${f}" > "${tmp}"
  if ! cmp -s "${f}" "${tmp}"; then
    mv "${tmp}" "${f}"
    echo "  normalized: ${f#"${SRC}"/}"
  else
    rm -f "${tmp}"
  fi
}

# SKILL.md + reference/*.md only — these are setup/invocation instructions
# read by whichever harness loaded the skill, and since OUR copy lives at
# .claude/skills/impeccable, "wherever this skill lives" always means that
# path here. Deliberately EXCLUDES scripts/hook-admin.mjs: its
# HOOK_MANIFEST_TARGETS table configures hooks for FOUR DIFFERENT tools
# (Claude Code, Codex, Cursor, GitHub Copilot), and each entry's `skillRel`
# intentionally points at THAT tool's own separate convention (e.g. the
# `.agents` provider's `.agents/skills/impeccable` is Codex's own install
# location, not a stray reference to ours) — rewriting it would silently
# break Codex/multi-tool support for users who have both configured.
[[ -f "${IMPECCABLE}/SKILL.md" ]] && rewrite "${IMPECCABLE}/SKILL.md"
if [[ -d "${IMPECCABLE}/reference" ]]; then
  while IFS= read -r -d '' f; do rewrite "${f}"; done \
    < <(find "${IMPECCABLE}/reference" -name '*.md' -print0)
fi

# Scoped to SKILL.md + reference/ only — scripts/hook-admin.mjs intentionally
# keeps its own .agents/skills/ references (see above) and would always show
# up here otherwise. `grep -rl` exits 1 for "no matches" — normal, not an
# error — but under `pipefail` that status propagates through the pipe to
# `wc`/`tr` and would trip `set -e`; `|| true` absorbs the expected case.
remaining="$( { [[ -f "${IMPECCABLE}/SKILL.md" ]] && grep -l '\.agents/skills/' "${IMPECCABLE}/SKILL.md"; [[ -d "${IMPECCABLE}/reference" ]] && grep -rl '\.agents/skills/' "${IMPECCABLE}/reference"; } 2>/dev/null | wc -l | tr -d ' ' || true)"
if [[ "${remaining}" != "0" ]]; then
  echo "warning: ${remaining} file(s) under SKILL.md/reference/ still reference .agents/skills/ — inspect and extend this script's file-type coverage if upstream added a new file type." >&2
fi

echo "Done. Re-run .claude/scripts/verify-skills.sh to refresh skills-lock.json hashes for the changed files."
