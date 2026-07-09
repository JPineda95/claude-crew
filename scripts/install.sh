#!/usr/bin/env bash
#
# install.sh — copy the crew into an existing project.
#
# Usage:
#   scripts/install.sh /path/to/your/project
#
# Copies the agents, commands, scripts, skills, docs, orchestrator CLAUDE.md,
# and the PROJECT template into the target repo. Never overwrites an existing
# CLAUDE.md or PROJECT.md without asking. Idempotent for the .claude/ payload.
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

# Re-running install.sh over an existing install would silently overwrite
# every customized agent/command/script (cp -R clobbers same-named files) —
# delegate to update.sh instead, which protects customizations with the
# three-way manifest sync.
if [[ -f "${DEST}/.claude/crew-manifest" ]]; then
  echo "already installed (found ${DEST}/.claude/crew-manifest) — running scripts/update.sh instead"
  exec "${SRC}/scripts/update.sh" "${DEST}"
fi
if [[ -d "${DEST}/.claude/agents" ]]; then
  echo "error: ${DEST} looks like a crew install without a manifest (a pre-manifest or" >&2
  echo "clone-based install) — use scripts/update.sh instead (it runs in conservative" >&2
  echo "legacy mode for installs like this: nothing deleted, differing files get a" >&2
  echo ".crew-new copy)." >&2
  exit 1
fi

sha256() {  # portable sha256: shasum (macOS/BSD) or sha256sum (most Linux)
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

command -v git >/dev/null 2>&1 \
  || { echo "error: 'git' is required but not found in PATH." >&2; exit 1; }
command -v shasum >/dev/null 2>&1 || command -v sha256sum >/dev/null 2>&1 \
  || { echo "error: neither 'shasum' nor 'sha256sum' found in PATH — needed to write the manifest." >&2; exit 1; }

echo "Installing the crew into: ${DEST}"

mkdir -p "${DEST}/.claude" "${DEST}/docs"
cp -R "${SRC}/.claude/agents"   "${DEST}/.claude/"
cp -R "${SRC}/.claude/commands" "${DEST}/.claude/"
cp -R "${SRC}/.claude/scripts"  "${DEST}/.claude/"
cp -R "${SRC}/.claude/skills"   "${DEST}/.claude/"
cp -R "${SRC}/docs/." "${DEST}/docs/"

# skills-lock.json — lets `npx skills update` refresh the taste library in the
# target repo. Don't clobber a lock the target already manages.
if [[ ! -f "${DEST}/skills-lock.json" ]]; then
  cp "${SRC}/skills-lock.json" "${DEST}/skills-lock.json"
elif ! cmp -s "${SRC}/skills-lock.json" "${DEST}/skills-lock.json"; then
  echo "  · kept existing skills-lock.json — merge ${SRC}/skills-lock.json by hand if you want 'npx skills update' to track the crew's design skills"
fi

# settings.json — copy only if the target has none (don't clobber project config).
if [[ ! -f "${DEST}/.claude/settings.json" ]]; then
  cp "${SRC}/.claude/settings.json" "${DEST}/.claude/settings.json"
else
  echo "  · kept existing .claude/settings.json (review ${SRC}/.claude/settings.json for the Stop + pre-PR gate hooks)"
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

# .claude/crew.env — the gate's single source of truth (CLAUDE_VALIDATE_CMD
# etc). Seeded once if absent; update.sh NEVER manages it afterward (like
# PROJECT.md), so it stays out of the manifest too.
if [[ ! -f "${DEST}/.claude/crew.env" ]]; then
  cp "${SRC}/templates/crew.env" "${DEST}/.claude/crew.env"
  echo "  · created .claude/crew.env — set your validation gate there (or run /onboard)"
else
  echo "  · kept existing .claude/crew.env"
fi

# Example configs (non-destructive).
cp "${SRC}/.mcp.json.example" "${DEST}/.mcp.json.example"
cp "${SRC}/.worktreeinclude.example" "${DEST}/.worktreeinclude.example"

# .gitignore — seed a managed block covering Claude Code / crew local state,
# so machine-local files don't get committed by accident (this happened for
# real: a Claude Code auto-memory file ended up tracked in a consuming repo).
# Idempotent: skipped if the marker is already present.
GITIGNORE="${DEST}/.gitignore"
if [[ ! -f "${GITIGNORE}" ]] || ! grep -q '^# --- claude-crew (managed block) ---$' "${GITIGNORE}"; then
  {
    echo ""
    echo "# --- claude-crew (managed block) ---"
    echo ".claude/settings.local.json"
    echo ".claude/launch.json"
    echo ".claude/projects/"
    echo ".claude/agent-memory-local/"
    echo ".agent-locks/"
    echo ".worktrees/"
    echo ".claude/skills/**/__pycache__/"
    echo "# --- end claude-crew ---"
  } >> "${GITIGNORE}"
  echo "  · added a managed block to .gitignore (Claude Code local state, crew worktrees)"
fi

# Manifest — records what was shipped (file hashes + source commit) so that
# scripts/update.sh can later update untouched files in place and protect
# customized ones. Commit it with the rest of .claude/.
COMMIT="$(git -C "${SRC}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
REMOTE="$(git -C "${SRC}" remote get-url origin 2>/dev/null || true)"
REF="$(git -C "${SRC}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
[[ "${REF}" == "HEAD" ]] && REF="unknown"
{
  echo "# claude-crew manifest — written by install.sh/update.sh; do not edit by hand."
  echo "# source: ${SRC}"
  [[ -n "${REMOTE}" ]] && echo "# remote: ${REMOTE}"
  echo "# commit: ${COMMIT}"
  echo "# ref: ${REF}"
  echo "# date: $(date +%Y-%m-%d)"
  (cd "${SRC}" && find .claude/agents .claude/commands .claude/scripts .claude/skills docs -type f ! -name '.DS_Store' | LC_ALL=C sort) | while IFS= read -r rel; do
    echo "$(sha256 "${SRC}/${rel}")  ${rel}"
  done
  for rel in CLAUDE.md .claude/settings.json skills-lock.json PROJECT.template.md .mcp.json.example .worktreeinclude.example; do
    [[ -f "${SRC}/${rel}" ]] && echo "$(shasum -a 256 "${SRC}/${rel}" | awk '{print $1}')  ${rel}"
  done
} > "${DEST}/.claude/crew-manifest"

echo
echo "Done. Next:"
echo "  1. Fill in ${DEST}/PROJECT.md (stack, commands, integration branch, rules)."
echo "  2. Install the MCP servers/plugins you need (see docs/TOOLING.md)."
echo "  3. Set your validation gate in .claude/crew.env (or run /onboard)."
echo "  4. Later, pull crew updates from inside the project: .claude/scripts/crew-update.sh"
echo "     (it finds this checkout via the manifest, or clones the repo if it's gone)"
