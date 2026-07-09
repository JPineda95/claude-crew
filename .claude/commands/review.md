---
description: "Run the three code reviewers in parallel on the current diff."
argument-hint: "[optional: base branch, defaults to the integration branch]"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(shasum:*)
---

Review the current changes through the crew's review gate.

Current state of the working tree:

!`git status --short`

!`git diff HEAD --stat`

!`git log --oneline -10`

Determine the **review base**: `$ARGUMENTS` if given, otherwise the integration
branch declared in `PROJECT.md` (fall back to the repo's default branch). The
scope under review is everything since the base — committed
(`git diff <base>...HEAD`) **plus** uncommitted work (`git diff HEAD`).

**Tree-integrity check.** The three reviewers are read-only by instruction, but
their tool allowlists include `Bash`, which prose alone can't stop from writing.
Before spawning them, capture a fingerprint of the working tree:
`git status --porcelain | shasum -a 256` and `git diff HEAD | shasum -a 256`.
After they return, recompute both. If either changed, the report below MUST
open with a loud warning ("a reviewer modified the working tree during this
review — findings below are suspect; do not trust them without re-verifying")
naming which command's before/after diverged, before presenting anything else.

Spawn these reviewers **in parallel** (one turn, multiple Task calls), each on
that scope, telling each the exact base to diff against:

- `reviewer-architecture` — structure, patterns, maintainability, design fit
- `reviewer-code-quality` — correctness, edge cases, tests, readability
- `reviewer-security` — OWASP-style vulnerabilities and secret exposure

Collect their verdicts. Then present a consolidated report:

1. Overall verdict: **APPROVE** only if all three approve; otherwise **REQUEST
   CHANGES**.
2. Findings grouped by severity (CRITICAL → WARNING → SUGGESTION → NIT), each with
   `file:line`, the concrete problem, why it matters, and a suggested fix. Merge
   duplicates that more than one reviewer flagged.
3. A recommended fix order, and which specialist owns each fix.

Do not modify code — this is a read-only gate. If the user wants the CRITICALs
fixed, route each to its owning specialist afterward.
