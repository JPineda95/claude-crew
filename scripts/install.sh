#!/usr/bin/env bash
#
# install.sh — copy the crew into an existing project.
#
# Usage:
#   scripts/install.sh /path/to/your/project
#
# Copies the agents, commands, scripts, docs, orchestrator CLAUDE.md, and the
# PROJECT template into the target repo. Never overwrites an existing CLAUDE.md
# or PROJECT.md without asking. Idempotent for the .claude/ payload.
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-}"

if [[ -z "${DEST}" ]]; then
  echo "usage: scripts/install.sh /path/to/your/project" >&2
  exit 1
fi
if [[ ! -d "${DEST}" ]]; then
  echo "error: target directory does not exist: ${DEST}" >&2
  exit 1
fi

echo "Installing the crew into: ${DEST}"

mkdir -p "${DEST}/.claude" "${DEST}/docs"
cp -R "${SRC}/.claude/agents"   "${DEST}/.claude/"
cp -R "${SRC}/.claude/commands" "${DEST}/.claude/"
cp -R "${SRC}/.claude/scripts"  "${DEST}/.claude/"
cp -R "${SRC}/docs/." "${DEST}/docs/"

# settings.json — copy only if the target has none (don't clobber project config).
if [[ ! -f "${DEST}/.claude/settings.json" ]]; then
  cp "${SRC}/.claude/settings.json" "${DEST}/.claude/settings.json"
else
  echo "  · kept existing .claude/settings.json (review ${SRC}/.claude/settings.json for the Stop hook)"
fi

# CLAUDE.md — never clobber; drop a reference copy alongside if one exists.
if [[ ! -f "${DEST}/CLAUDE.md" ]]; then
  cp "${SRC}/CLAUDE.md" "${DEST}/CLAUDE.md"
else
  cp "${SRC}/CLAUDE.md" "${DEST}/CLAUDE.crew.md"
  echo "  · existing CLAUDE.md kept; orchestrator saved as CLAUDE.crew.md — merge the two by hand"
fi

# PROJECT.md — seed from the template if absent.
if [[ ! -f "${DEST}/PROJECT.md" ]]; then
  cp "${SRC}/PROJECT.template.md" "${DEST}/PROJECT.md"
  echo "  · created PROJECT.md from the template — FILL IT IN before running the crew"
else
  echo "  · kept existing PROJECT.md"
fi

# Example configs (non-destructive).
cp "${SRC}/.mcp.json.example" "${DEST}/.mcp.json.example"
cp "${SRC}/.worktreeinclude.example" "${DEST}/.worktreeinclude.example"

echo
echo "Done. Next:"
echo "  1. Fill in ${DEST}/PROJECT.md (stack, commands, integration branch, rules)."
echo "  2. Install the MCP servers/plugins you need (see docs/TOOLING.md)."
echo "  3. Set your validation gate in .claude/scripts/validate.sh (or CLAUDE_VALIDATE_CMD)."
