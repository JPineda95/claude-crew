#!/usr/bin/env bash
#
# build-plugin.sh — assemble the Claude Code plugin form of the crew into dist/.
#
# The canonical source of truth is `.claude/` (clone-first layout). Claude Code
# plugins, however, expect components at the plugin root (agents/, commands/,
# hooks/). This script generates that layout from the canonical files so you can
# install the crew as a plugin instead of copying files.
#
# Usage:
#   scripts/build-plugin.sh
#   # then, in any project:
#   /plugin marketplace add /absolute/path/to/claude-crew
#   /plugin install claude-crew@claude-crew
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${SRC}/dist/claude-crew"

rm -rf "${OUT}"
mkdir -p "${OUT}/.claude-plugin" "${OUT}/agents" "${OUT}/commands" "${OUT}/hooks" "${OUT}/scripts"

cp "${SRC}/.claude-plugin/plugin.json" "${OUT}/.claude-plugin/plugin.json"
cp "${SRC}/.claude/agents/"*.md   "${OUT}/agents/"
cp "${SRC}/.claude/commands/"*.md "${OUT}/commands/"
cp "${SRC}/.claude/scripts/"*     "${OUT}/scripts/" 2>/dev/null || true

# Design/anti-slop skills travel with the plugin (used by designer + frontend-engineer).
if [ -d "${SRC}/.claude/skills" ]; then
    mkdir -p "${OUT}/skills"
    cp -R "${SRC}/.claude/skills/." "${OUT}/skills/"
fi

# The crew's docs travel with the plugin so agents can read them.
mkdir -p "${OUT}/docs"
cp "${SRC}/docs/"*.md "${OUT}/docs/"
cp "${SRC}/CLAUDE.md" "${OUT}/CLAUDE.md"
cp "${SRC}/PROJECT.template.md" "${OUT}/PROJECT.template.md"

# Stop-hook that runs the validation gate, as plugin hook config.
cat > "${OUT}/hooks/hooks.json" <<'JSON'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
            "timeout": 600,
            "statusMessage": "Running the validation gate…"
          }
        ]
      }
    ]
  }
}
JSON

echo "Built plugin at: ${OUT}"
echo "Install it with:"
echo "  /plugin marketplace add ${SRC}"
echo "  /plugin install claude-crew@claude-crew"
