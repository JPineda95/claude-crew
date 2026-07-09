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

# Sync the marketplace's plugin-entry version to plugin.json — never touch
# the top-level marketplace schema version ("version": "1", a different
# field). Fails the build if plugin.json's version has no matching
# CHANGELOG.md entry, so a version bump can't ship undocumented.
python3 - "${SRC}" <<'PYEOF'
import json, sys, pathlib

src = pathlib.Path(sys.argv[1])
plugin = json.loads((src / ".claude-plugin/plugin.json").read_text())
version = plugin["version"]

changelog = (src / "CHANGELOG.md").read_text()
if f"## {version}" not in changelog:
    print(f"error: plugin.json version {version} has no '## {version}' heading in "
          f"CHANGELOG.md — cut a changelog entry before building.", file=sys.stderr)
    sys.exit(1)

mkt_path = src / ".claude-plugin/marketplace.json"
mkt = json.loads(mkt_path.read_text())
changed = False
for p in mkt.get("plugins", []):
    if p.get("name") == plugin["name"] and p.get("version") != version:
        p["version"] = version
        changed = True
if changed:
    mkt_path.write_text(json.dumps(mkt, indent=2) + "\n")
    print(f"  synced .claude-plugin/marketplace.json plugin version -> {version}")
PYEOF

rm -rf "${OUT}"
mkdir -p "${OUT}/.claude-plugin" "${OUT}/agents" "${OUT}/commands" "${OUT}/hooks" "${OUT}/scripts"

cp "${SRC}/.claude-plugin/plugin.json" "${OUT}/.claude-plugin/plugin.json"
cp "${SRC}/.claude/agents/"*.md   "${OUT}/agents/"
cp "${SRC}/.claude/scripts/"*     "${OUT}/scripts/" 2>/dev/null || true

# /crew-update doesn't apply to plugin installs: its whole mechanism is the
# clone/copy distribution's manifest-based sync (.claude/crew-manifest,
# .claude/scripts/crew-update.sh) — neither exists in a plugin-only install,
# which updates via `/plugin update` instead. Ship every other command.
for f in "${SRC}/.claude/commands/"*.md; do
  base="$(basename "${f}")"
  [[ "${base}" == "crew-update.md" ]] && continue
  cp "${f}" "${OUT}/commands/"
done

# Plugin installs have no project root — docs/ and PROJECT.template.md live
# under ${CLAUDE_PLUGIN_ROOT} instead (see /crew-init below, which copies
# them OUT to the project root; their references there stay project-relative
# and correct). Rewrite the copied agents'/commands' references to these
# eight files so they resolve inside a plugin-only install. Portable (no
# `sed -i` flag differences): write to a temp file, then move it back.
# Deliberately enumerated, not a blanket `docs/` substitution.
rewrite_doc_refs() {
  local f="$1" tmp
  tmp="$(mktemp)"
  sed \
    -e 's#docs/ENGINEERING\.md#${CLAUDE_PLUGIN_ROOT}/docs/ENGINEERING.md#g' \
    -e 's#docs/WORKFLOW\.md#${CLAUDE_PLUGIN_ROOT}/docs/WORKFLOW.md#g' \
    -e 's#docs/TESTING\.md#${CLAUDE_PLUGIN_ROOT}/docs/TESTING.md#g' \
    -e 's#docs/TICKETS\.md#${CLAUDE_PLUGIN_ROOT}/docs/TICKETS.md#g' \
    -e 's#docs/WORKTREES\.md#${CLAUDE_PLUGIN_ROOT}/docs/WORKTREES.md#g' \
    -e 's#docs/COMMITS\.md#${CLAUDE_PLUGIN_ROOT}/docs/COMMITS.md#g' \
    -e 's#docs/TOOLING\.md#${CLAUDE_PLUGIN_ROOT}/docs/TOOLING.md#g' \
    -e 's#PROJECT\.template\.md#${CLAUDE_PLUGIN_ROOT}/PROJECT.template.md#g' \
    "${f}" > "${tmp}"
  mv "${tmp}" "${f}"
}
for f in "${OUT}/agents/"*.md "${OUT}/commands/"*.md; do
  rewrite_doc_refs "${f}"
done

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

# templates/crew.env — the gate config template, so the plugin form can seed it too.
mkdir -p "${OUT}/templates"
cp "${SRC}/templates/crew.env" "${OUT}/templates/crew.env"

# /crew-init — plugin-only command, not part of the canonical .claude/commands/
# (a clone/copy install already has CLAUDE.md, docs/, and PROJECT.template.md
# at the project root; only a plugin install is missing them). Copies those
# three out of ${CLAUDE_PLUGIN_ROOT} into the project root, non-destructively.
cat > "${OUT}/commands/crew-init.md" <<'MD'
---
description: "Copy the orchestrator (CLAUDE.md), docs/, and PROJECT.template.md from the plugin into this project — run once after installing claude-crew as a plugin."
allowed-tools: Read, Write, Glob
---

Plugin installs ship only commands/agents/hooks/skills — Claude Code has no
mechanism to auto-load a plugin's `CLAUDE.md` as the orchestrator persona,
and every agent/command references `docs/...` and `PROJECT.template.md` at
project-root-relative paths that don't exist yet in a plugin-only install.
This command copies what's missing from `${CLAUDE_PLUGIN_ROOT}` into the
current project root, non-destructively:

1. **`CLAUDE.md`** — never overwrite. If the project already has one, write
   the plugin's copy alongside as `CLAUDE.crew.md` and tell the user to
   merge the two by hand (matching `scripts/install.sh`'s behavior in the
   clone/copy distribution).
2. **`docs/*.md`** — copy any file that doesn't already exist at the
   project's `docs/`; never overwrite one that does.
3. **`PROJECT.template.md`** — copy to the project root if it's not already
   there.

Report what was copied and what was skipped because it already existed.
Close by telling the user to run `/onboard` next — it needs
`PROJECT.template.md` present to work from, and the agents need
`docs/ENGINEERING.md` and friends present to read.
MD

# Hooks as plugin config: the pre-PR gate (blocks `gh pr create` until the
# validation gate is green — same guardrail the clone-first layout gets from
# .claude/settings.json) and the Stop-hook validation gate.
cat > "${OUT}/hooks/hooks.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/pre-pr-gate.sh",
            "timeout": 900,
            "statusMessage": "Pre-PR gate: lint + tests (+ e2e smoke)…"
          }
        ]
      }
    ],
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
