#!/usr/bin/env bash
#
# verify-skills.sh — recompute each vendored skill's hash and diff against
# skills-lock.json's computedHash. Informational: always exits 0.
#
# Hashing scheme reverse-engineered from the `skills` CLI (vercel-labs/skills,
# npm package `skills`) source, verified byte-for-byte against this repo's own
# skills-lock.json entries for animation-vocabulary (single-file) and
# review-animations (multi-file) before being trusted here:
#   - Single-file skill (skill dir contains exactly one file): sha256 of the
#     literal bytes "SKILL.md" followed by the file's raw content.
#   - Multi-file skill: walk every file in the skill dir (skip .git/,
#     node_modules/), sort by relative path, and for each file feed its
#     relative path then its raw content into one running sha256.
#
# Usage:
#   .claude/scripts/verify-skills.sh
#
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCK="${SRC}/skills-lock.json"
SKILLS_DIR="${SRC}/.claude/skills"

if [[ ! -f "${LOCK}" ]]; then
  echo "no skills-lock.json — nothing to verify." >&2
  exit 0
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 not found — skipping skill verification." >&2; exit 0; }

python3 - "${LOCK}" "${SKILLS_DIR}" <<'PYEOF'
import hashlib
import json
import os
import sys

lock_path, skills_dir = sys.argv[1], sys.argv[2]

def single_file_hash(path):
    h = hashlib.sha256()
    h.update(b"SKILL.md")
    with open(path, "rb") as f:
        h.update(f.read())
    return h.hexdigest()

def folder_hash(base_dir):
    files = []
    for root, dirs, filenames in os.walk(base_dir):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules")]
        for fn in filenames:
            full = os.path.join(root, fn)
            rel = os.path.relpath(full, base_dir).replace(os.sep, "/")
            with open(full, "rb") as f:
                files.append((rel, f.read()))
    files.sort(key=lambda x: x[0])
    h = hashlib.sha256()
    for rel, content in files:
        h.update(rel.encode())
        h.update(content)
    return h.hexdigest()

with open(lock_path) as f:
    lock = json.load(f)

changed, missing, clean, unverifiable = [], [], [], []

for name, entry in sorted(lock.get("skills", {}).items()):
    skill_dir = os.path.join(skills_dir, name)
    expected = entry.get("computedHash")
    if not os.path.isdir(skill_dir):
        missing.append(name)
        continue
    if not expected:
        unverifiable.append((name, "no computedHash in lock"))
        continue

    file_count = sum(1 for root, dirs, fns in os.walk(skill_dir) for fn in fns)

    if file_count == 1:
        skill_md = os.path.join(skill_dir, "SKILL.md")
        if not os.path.isfile(skill_md):
            unverifiable.append((name, "single file present but it isn't SKILL.md"))
            continue
        actual = single_file_hash(skill_md)
    else:
        actual = folder_hash(skill_dir)

    if actual == expected:
        clean.append(name)
    else:
        changed.append(name)

print(f"skills-lock.json check: {len(clean)} clean, {len(changed)} changed, "
      f"{len(missing)} missing, {len(unverifiable)} unverifiable")
if clean:
    print("  clean:        " + ", ".join(clean))
if changed:
    print("  CHANGED:      " + ", ".join(changed) + "  (re-run `npx skills update` or investigate manually)")
if missing:
    print("  MISSING:      " + ", ".join(missing) + "  (in lock but not on disk)")
if unverifiable:
    for n, reason in unverifiable:
        print(f"  unverifiable: {n} ({reason})")

# Skills vendored but absent from the lock entirely.
if os.path.isdir(skills_dir):
    on_disk = {d for d in os.listdir(skills_dir) if os.path.isdir(os.path.join(skills_dir, d))}
    unmanaged = sorted(on_disk - set(lock.get("skills", {}).keys()))
    if unmanaged:
        print("  unmanaged:    " + ", ".join(unmanaged) + "  (vendored but not in skills-lock.json)")
PYEOF
exit 0
