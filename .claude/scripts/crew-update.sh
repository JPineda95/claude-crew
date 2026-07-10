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
#   3. $CREW_REPO, "# remote:" in the manifest, or the public repo — cloned shallow
#
# Whichever it resolves, it syncs the RELEASED ref: origin/main by default, or
# $CREW_REF to dogfood a branch/tag. A local checkout is read through a throwaway
# detached worktree of that ref — so the branch you happen to have checked out
# (and any in-progress / open-PR work on it) is never synced into a project.
#
# Usage, from anywhere inside the project:
#   .claude/scripts/crew-update.sh [--allow-downgrade]
#
# --allow-downgrade forwards to update.sh's downgrade guard, which otherwise
# refuses to sync when the installed content is not an ancestor of REF (e.g.
# this project was installed from a newer/dogfooded branch).
#
set -euo pipefail

DEFAULT_REPO="https://github.com/JPineda95/claude-crew"

ALLOW_DOWNGRADE=0
for arg in "$@"; do
  case "${arg}" in
    --allow-downgrade) ALLOW_DOWNGRADE=1 ;;
  esac
done

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

# The released ref to sync. Default to main so a project never picks up
# unreleased or open-PR work; CREW_REF dogfoods a specific branch/tag instead.
REF="${CREW_REF:-main}"

SRC=""        # crew source handed to update.sh (a materialized ref, never a work tree)
SRC_REPO=""   # the local git checkout we materialize REF from (needed for cleanup)
WORKTREE=""   # throwaway detached worktree of REF
WT_PARENT=""  # its temp parent dir
CLONED=""     # throwaway shallow clone (used only when there's no local checkout)
# NB: this EXIT-trap handler must end with status 0 — a failed `[[ … ]] &&` list
# here becomes the script's exit code even after a successful sync (the trap runs
# on EXIT, so its last status wins). Keep the trailing `return 0`.
cleanup() {
  if [[ -n "${WORKTREE}" && -n "${SRC_REPO}" ]]; then
    git -C "${SRC_REPO}" worktree remove --force "${WORKTREE}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${WT_PARENT}" ]]; then rm -rf "${WT_PARENT}"; fi
  if [[ -n "${CLONED}" ]]; then rm -rf "${CLONED}"; fi
  return 0
}
trap cleanup EXIT

# Locate a local checkout to materialize REF from (explicit, then the manifest).
LOCAL_SRC=""
if [[ -n "${CREW_SOURCE:-}" ]]; then
  looks_like_crew "${CREW_SOURCE}" \
    || { echo "error: CREW_SOURCE=${CREW_SOURCE} is not a claude-crew checkout" >&2; exit 1; }
  LOCAL_SRC="${CREW_SOURCE}"
elif [[ -f "${MANIFEST}" ]]; then
  rec="$(sed -n 's/^# source: //p' "${MANIFEST}" | head -1)"
  if [[ -n "${rec}" ]] && looks_like_crew "${rec}"; then
    LOCAL_SRC="${rec}"
  fi
fi

if [[ -n "${LOCAL_SRC}" ]] && git -C "${LOCAL_SRC}" rev-parse --git-dir >/dev/null 2>&1; then
  # Local git checkout → materialize REF in a throwaway detached worktree, so we
  # sync REF's content (not whatever branch is checked out) without touching the
  # user's working tree.
  SRC_REPO="${LOCAL_SRC}"
  git -C "${SRC_REPO}" fetch --quiet origin "${REF}" >/dev/null 2>&1 || true
  PICK="origin/${REF}"
  git -C "${SRC_REPO}" rev-parse --verify --quiet "${PICK}" >/dev/null 2>&1 || PICK="${REF}"
  git -C "${SRC_REPO}" rev-parse --verify --quiet "${PICK}" >/dev/null 2>&1 \
    || { echo "error: can't resolve '${REF}' in ${SRC_REPO} — fetch it, or set CREW_REF to an existing ref." >&2; exit 1; }
  WT_PARENT="$(mktemp -d "${TMPDIR:-/tmp}/claude-crew-wt.XXXXXX")"
  WORKTREE="${WT_PARENT}/${REF//\//-}"
  git -C "${SRC_REPO}" worktree add --quiet --detach "${WORKTREE}" "${PICK}" >/dev/null 2>&1 \
    || { echo "error: couldn't check out '${PICK}' from ${SRC_REPO} (stale worktree? try 'git -C ${SRC_REPO} worktree prune')." >&2; exit 1; }
  echo "Using crew source: ${SRC_REPO} @ ${PICK} ($(git -C "${WORKTREE}" rev-parse --short HEAD)) — released line."
  SRC="${WORKTREE}"
elif [[ -n "${LOCAL_SRC}" ]]; then
  # A source path that isn't a git checkout — use it as-is.
  SRC="${LOCAL_SRC}"
else
  # No local checkout → shallow-clone REF.
  REPO_URL="${CREW_REPO:-}"
  if [[ -z "${REPO_URL}" && -f "${MANIFEST}" ]]; then
    REPO_URL="$(sed -n 's/^# remote: //p' "${MANIFEST}" | head -1)"
  fi
  [[ -z "${REPO_URL}" ]] && REPO_URL="${DEFAULT_REPO}"
  CLONED="$(mktemp -d "${TMPDIR:-/tmp}/claude-crew.XXXXXX")"
  echo "Fetching the crew (${REF}) from ${REPO_URL} …"
  git clone --quiet --depth 1 --branch "${REF}" "${REPO_URL}" "${CLONED}/crew"
  SRC="${CLONED}/crew"
fi

looks_like_crew "${SRC}" \
  || { echo "error: resolved crew source ${SRC} doesn't look like a claude-crew repo" >&2; exit 1; }

# CREW_SYNCED_REF tells update.sh's manifest writer the real ref name — SRC
# may be a detached worktree (HEAD is unreadable as a ref there otherwise).
export CREW_SYNCED_REF="${REF}"
if [[ "${ALLOW_DOWNGRADE}" -eq 1 ]]; then
  bash "${SRC}/scripts/update.sh" "${PROJECT}" --allow-downgrade
else
  bash "${SRC}/scripts/update.sh" "${PROJECT}"
fi

# update.sh records "# source: <the crew source it ran from>". When we
# materialized a ref in a throwaway worktree, that path is about to be deleted —
# rewrite the manifest to the durable checkout so the next sync finds it again.
# (Self-contained here so it holds regardless of the synced update.sh version.)
if [[ -n "${SRC_REPO}" && -f "${MANIFEST}" ]]; then
  tmp="$(mktemp)"
  if sed "s|^# source: .*|# source: ${SRC_REPO}|" "${MANIFEST}" > "${tmp}"; then
    mv "${tmp}" "${MANIFEST}"
  else
    rm -f "${tmp}"
  fi
fi

# Report any vendored-skill drift now that the sync (which may have touched
# .claude/skills/) is done. Informational only — never blocks.
if [[ -f "${PROJECT}/.claude/scripts/verify-skills.sh" ]]; then
  bash "${PROJECT}/.claude/scripts/verify-skills.sh" || true
fi
