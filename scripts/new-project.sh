#!/usr/bin/env bash
#
# new-project.sh — start a brand-new project from the crew (Quickstart Option A).
#
# Usage:
#   scripts/new-project.sh /path/to/my-app
#
# Creates the target directory, git-inits it, and runs scripts/install.sh into
# it — so the new project gets its own manifest, crew.env, and .gitignore
# block from the start (never claude-crew's own README/CHANGELOG/LICENSE/
# .claude-plugin/ or build/install/update scripts — install.sh doesn't copy
# those). Prints the next steps (GitHub remote, /onboard) when done.
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-}"

if [[ -z "${DEST}" ]]; then
  echo "usage: scripts/new-project.sh /path/to/my-app" >&2
  exit 1
fi
if [[ -e "${DEST}" ]]; then
  echo "error: ${DEST} already exists — new-project.sh is for a brand-new directory." >&2
  echo "       For an existing project, use scripts/install.sh instead." >&2
  exit 1
fi
command -v git >/dev/null 2>&1 \
  || { echo "error: 'git' is required but not found in PATH." >&2; exit 1; }

mkdir -p "${DEST}"
git -C "${DEST}" init -q
echo "Initialized an empty git repo in ${DEST}"

"${SRC}/scripts/install.sh" "${DEST}"

NAME="$(basename "${DEST}")"
echo
echo "Next:"
echo "  1. cd ${DEST}"
echo "  2. Create a GitHub repo + remote (the ship phase needs one to open PRs):"
echo "       gh repo create ${NAME} --private --source=. --push"
echo "  3. Open the folder in Claude Code and run /onboard."
