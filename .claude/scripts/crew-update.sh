#!/usr/bin/env bash
#
# crew-update.sh — update THIS project's crew config from the claude-crew repo.
#
# Ships with the crew into every consuming project (.claude/scripts/), so a
# project never needs a claude-crew checkout lying around to stay current. It
# only locates the crew source and hands off to that source's
# scripts/update.sh, which does the real three-way sync against
# .claude/crew-manifest (customized files are kept; new versions land as
# <file>.crew-new).
#
# Source resolution, first match wins:
#   1. $CREW_SOURCE                          — explicit path to a checkout
#   2. "# source:" in .claude/crew-manifest  — the checkout that installed us
#   3. $CREW_REPO, "# remote:" in the manifest, or the public repo — cloned
#      shallow into a temp dir ($CREW_REF selects a branch/tag)
#
# Usage, from anywhere inside the project:
#   .claude/scripts/crew-update.sh
#
set -euo pipefail

DEFAULT_REPO="https://github.com/JPineda95/claude-crew"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$(cd "${here}/../.." && pwd)"
MANIFEST="${PROJECT}/.claude/crew-manifest"

looks_like_crew() {
  [[ -f "$1/scripts/update.sh" && -f "$1/PROJECT.template.md" ]]
}

if [[ ! -f "${MANIFEST}" ]]; then
  origin="$(git -C "${PROJECT}" remote get-url origin 2>/dev/null || true)"
  case "${origin}" in *claude-crew*)
    echo "This looks like the claude-crew source repo itself (origin: ${origin})." >&2
    echo "Update it with 'git pull', not crew-update." >&2
    exit 0 ;;
  esac
  echo "note: no .claude/crew-manifest here — the sync runs in conservative legacy mode." >&2
fi

SRC=""
CLONED=""
# NB: the handler must end with status 0 — a failed `[[ … ]] &&` list here
# becomes the script's exit code even after a successful sync.
cleanup() { if [[ -n "${CLONED}" ]]; then rm -rf "${CLONED}"; fi; }
trap cleanup EXIT

if [[ -n "${CREW_SOURCE:-}" ]]; then
  looks_like_crew "${CREW_SOURCE}" \
    || { echo "error: CREW_SOURCE=${CREW_SOURCE} is not a claude-crew checkout" >&2; exit 1; }
  SRC="${CREW_SOURCE}"
elif [[ -f "${MANIFEST}" ]]; then
  rec="$(sed -n 's/^# source: //p' "${MANIFEST}" | head -1)"
  if [[ -n "${rec}" ]] && looks_like_crew "${rec}"; then
    SRC="${rec}"
  fi
fi

if [[ -n "${SRC}" ]]; then
  if git -C "${SRC}" rev-parse --git-dir >/dev/null 2>&1; then
    branch="$(git -C "${SRC}" branch --show-current 2>/dev/null || true)"
    commit="$(git -C "${SRC}" rev-parse --short HEAD 2>/dev/null || echo '?')"
    echo "Using local crew checkout: ${SRC} (${branch:-detached} @ ${commit})"
    echo "  · not pulling it automatically — 'git -C ${SRC} pull' first if you want newer."
  fi
else
  REPO_URL="${CREW_REPO:-}"
  if [[ -z "${REPO_URL}" && -f "${MANIFEST}" ]]; then
    REPO_URL="$(sed -n 's/^# remote: //p' "${MANIFEST}" | head -1)"
  fi
  [[ -z "${REPO_URL}" ]] && REPO_URL="${DEFAULT_REPO}"
  CLONED="$(mktemp -d "${TMPDIR:-/tmp}/claude-crew.XXXXXX")"
  echo "Fetching the crew from ${REPO_URL}${CREW_REF:+ (ref: ${CREW_REF})} …"
  if [[ -n "${CREW_REF:-}" ]]; then
    git clone --quiet --depth 1 --branch "${CREW_REF}" "${REPO_URL}" "${CLONED}/crew"
  else
    git clone --quiet --depth 1 "${REPO_URL}" "${CLONED}/crew"
  fi
  SRC="${CLONED}/crew"
  looks_like_crew "${SRC}" \
    || { echo "error: ${REPO_URL} doesn't look like a claude-crew repo" >&2; exit 1; }
fi

bash "${SRC}/scripts/update.sh" "${PROJECT}"
