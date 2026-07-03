#!/usr/bin/env bash
#
# update.sh — pull the latest crew configuration into a project that already
# has claude-crew installed.
#
# Usage:
#   scripts/update.sh /path/to/your/project
#   cd /path/to/your/project && /path/to/claude-crew/scripts/update.sh
#
# Uses the manifest written by install.sh (.claude/crew-manifest) to decide,
# per file, without ever silently clobbering local work:
#   ↑ untouched since install/update  → updated in place
#   ✎ customized in the project      → kept; new version saved next to it as
#     <file>.crew-new (CLAUDE.md → CLAUDE.crew.md, settings.json →
#     settings.crew.json) for a manual merge
#   + added upstream                 → copied in
#   − deleted upstream               → removed only if untouched locally
#
# PROJECT.md is never touched. Installs that predate the manifest are updated
# conservatively: nothing is deleted, and every differing file gets a
# .crew-new instead of an in-place update.
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-}"
MANIFEST_REL=".claude/crew-manifest"

if [[ -z "${DEST}" ]]; then
  if [[ -f "./${MANIFEST_REL}" || -d "./.claude/agents" ]]; then
    DEST="$(pwd)"
  else
    echo "usage: scripts/update.sh /path/to/your/project" >&2
    echo "(or run it with no argument from inside an installed project)" >&2
    exit 1
  fi
fi
if [[ ! -d "${DEST}/.claude/agents" ]]; then
  echo "error: ${DEST} doesn't look like a crew install (no .claude/agents) — run scripts/install.sh first" >&2
  exit 1
fi
DEST="$(cd "${DEST}" && pwd)"
MANIFEST="${DEST}/${MANIFEST_REL}"

PAYLOAD_DIRS=".claude/agents .claude/commands .claude/scripts .claude/skills docs"

hash_of() { shasum -a 256 "$1" | awk '{print $1}'; }

old_hash() {  # rel-path → hash recorded at last install/update ("" if none)
  [[ -f "${MANIFEST}" ]] || return 0
  awk -v p="$1" '$1 !~ /^#/ && $2 == p { print $1; exit }' "${MANIFEST}"
}

UPDATED=0; ADDED=0; CUSTOM=0; DELETED=0; UPTODATE=0; KEPT=0
CREW_NEW_FILES=""

three_way() {  # $1 = rel path, $2 = optional merge-copy name (default $1.crew-new)
  local rel="$1" guard="${2:-$1.crew-new}"
  local sf="${SRC}/${rel}" df="${DEST}/${rel}" sh dh oh
  sh="$(hash_of "${sf}")"
  oh="$(old_hash "${rel}")"
  if [[ ! -f "${df}" ]]; then
    mkdir -p "$(dirname "${df}")"
    cp "${sf}" "${df}"
    ADDED=$((ADDED + 1)); echo "  + ${rel}"
    return 0
  fi
  dh="$(hash_of "${df}")"
  if [[ "${dh}" == "${sh}" ]]; then
    UPTODATE=$((UPTODATE + 1)); return 0
  fi
  if [[ -n "${oh}" && "${dh}" == "${oh}" ]]; then
    cp "${sf}" "${df}"
    UPDATED=$((UPDATED + 1)); echo "  ↑ ${rel}"
  elif [[ -n "${oh}" && "${sh}" == "${oh}" ]]; then
    # Customized locally, but upstream hasn't changed since the last update —
    # nothing new to merge; stay quiet.
    UPTODATE=$((UPTODATE + 1))
  else
    cp "${sf}" "${DEST}/${guard}"
    CUSTOM=$((CUSTOM + 1)); CREW_NEW_FILES="${CREW_NEW_FILES}  ${guard}\n"
    echo "  ✎ ${rel} — local changes kept; new version at ${guard}"
  fi
}

echo "Updating the crew in: ${DEST}"
echo "From: ${SRC} ($(git -C "${SRC}" rev-parse --short HEAD 2>/dev/null || echo 'not a git checkout'))"

# What changed upstream since the last update (best effort).
if [[ -f "${MANIFEST}" ]]; then
  OLD_COMMIT="$(awk -F': ' '/^# commit: /{print $2; exit}' "${MANIFEST}")"
  if [[ -n "${OLD_COMMIT}" && "${OLD_COMMIT}" != "unknown" ]] \
    && git -C "${SRC}" rev-parse --verify --quiet "${OLD_COMMIT}" >/dev/null 2>&1; then
    echo
    echo "Upstream changes since your last update (${OLD_COMMIT}):"
    git -C "${SRC}" log --oneline "${OLD_COMMIT}..HEAD" | sed 's/^/  /' || true
  fi
else
  echo
  echo "⚠ no ${MANIFEST_REL} found (install predates it) — conservative mode:"
  echo "  nothing is deleted, and every file that differs gets a .crew-new copy."
fi
echo

# 1. The .claude/ + docs payload.
while IFS= read -r rel; do
  three_way "${rel}"
done < <(cd "${SRC}" && find ${PAYLOAD_DIRS} -type f ! -name '.DS_Store' | LC_ALL=C sort)

# 2. Files the crew stopped shipping: remove only pristine copies.
if [[ -f "${MANIFEST}" ]]; then
  while read -r oh rel; do
    case "${oh}" in \#* | "") continue ;; esac
    case "${rel}" in
      .claude/agents/* | .claude/commands/* | .claude/scripts/* | .claude/skills/* | docs/*) ;;
      *) continue ;;
    esac
    [[ -f "${SRC}/${rel}" ]] && continue
    [[ -f "${DEST}/${rel}" ]] || continue
    if [[ "$(hash_of "${DEST}/${rel}")" == "${oh}" ]]; then
      rm "${DEST}/${rel}"
      DELETED=$((DELETED + 1)); echo "  − ${rel} (removed upstream)"
    else
      KEPT=$((KEPT + 1))
      echo "  ! ${rel} was removed upstream but has local changes — kept"
    fi
  done < "${MANIFEST}"
fi

# 3. Example configs (safe to update like payload).
three_way ".mcp.json.example"
three_way ".worktreeinclude.example"

# 4. Guarded files — same three-way logic, friendlier merge-copy names.
three_way "CLAUDE.md" "CLAUDE.crew.md"
three_way ".claude/settings.json" ".claude/settings.crew.json"
[[ -f "${SRC}/skills-lock.json" ]] && three_way "skills-lock.json"

# 5. PROJECT.template.md is never installed — but if it changed upstream, the
#    project's PROJECT.md may be missing new sections.
TPL_OLD="$(old_hash "PROJECT.template.md")"
if [[ -n "${TPL_OLD}" && "${TPL_OLD}" != "$(hash_of "${SRC}/PROJECT.template.md")" ]]; then
  echo "  ✎ PROJECT.template.md changed upstream — run /onboard (update mode) so PROJECT.md gains the new sections"
fi

# 6. Refresh the manifest to the state just shipped.
COMMIT="$(git -C "${SRC}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
{
  echo "# claude-crew manifest — written by install.sh/update.sh; do not edit by hand."
  echo "# source: ${SRC}"
  echo "# commit: ${COMMIT}"
  echo "# date: $(date +%Y-%m-%d)"
  (cd "${SRC}" && find ${PAYLOAD_DIRS} -type f ! -name '.DS_Store' | LC_ALL=C sort) | while IFS= read -r rel; do
    echo "$(hash_of "${SRC}/${rel}")  ${rel}"
  done
  for rel in CLAUDE.md .claude/settings.json skills-lock.json PROJECT.template.md .mcp.json.example .worktreeinclude.example; do
    [[ -f "${SRC}/${rel}" ]] && echo "$(hash_of "${SRC}/${rel}")  ${rel}"
  done
} > "${MANIFEST}"

echo
echo "Done: ${UPDATED} updated, ${ADDED} added, ${DELETED} removed, ${UPTODATE} already current, ${CUSTOM} kept with a merge copy, ${KEPT} kept despite upstream removal."
if [[ "${CUSTOM}" -gt 0 ]]; then
  echo
  echo "Merge these by hand, then delete the copies:"
  printf "%b" "${CREW_NEW_FILES}"
  case "${CREW_NEW_FILES}" in *settings.crew.json*)
    echo "  (settings.crew.json likely carries new hooks/permissions — e.g. the pre-PR test gate)" ;;
  esac
  # Substring-matches the printed guard path (".claude/commands/feature.md.crew-new"),
  # not the source-relative path — keep in sync with three_way's guard naming.
  case "${CREW_NEW_FILES}" in *commands/feature.md*)
    echo "  (NOTE: /feature was repurposed upstream in v2 — it now files a Story ticket; /work runs the build lifecycle. Merge feature.md.crew-new deliberately.)" ;;
  esac
fi
