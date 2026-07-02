---
description: Run the three code reviewers in parallel on the current diff.
argument-hint: "[optional: base branch, defaults to the integration branch]"
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status), Bash(git branch:*)
---

Review the current changes through the crew's review gate.

Current state of the working tree:

!`git status --short; echo "---"; git diff HEAD --stat; echo "---"; git log --oneline -10`

Determine the **review base**: `$ARGUMENTS` if given, otherwise the integration
branch declared in `PROJECT.md` (fall back to the repo's default branch). The
scope under review is everything since the base — committed
(`git diff <base>...HEAD`) **plus** uncommitted work (`git diff HEAD`).

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
