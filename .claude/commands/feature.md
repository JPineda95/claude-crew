---
description: Run the full crew workflow to design, build, test, and review a feature.
argument-hint: <what to build>
---

Orchestrate the feature described below through the crew workflow in
`docs/WORKFLOW.md`. You are the orchestrator — delegate; don't do it all yourself.

**Feature:** $ARGUMENTS

Proceed:

1. **Intake** — Read `PROJECT.md`. Restate the request in one or two sentences and
   note any assumption. Check for an open crew PR from a previous feature
   (`gh pr list`) — if one is still awaiting review, STOP and tell the user:
   the next feature starts only after it is merged or explicitly closed. If
   something genuinely ambiguous would change the outcome, ask now; otherwise
   proceed.
2. **Branch** — sync `<integration-branch>`, then create this feature's branch
   off it (`<type>/<slug>` per `PROJECT.md` naming, e.g. `feat/user-invites`).
   All work for the feature lands on this branch; parallel task worktrees
   branch off it and merge back into it per `docs/WORKTREES.md`.
3. **Design & Plan** — Spawn `architect` to produce a design brief and an
   execution plan (task list with owners, dependencies, and a hot-file map). Pull
   in `designer`, `database-architect`, and/or `security-engineer` if the feature
   needs them — and `data-compliance-officer` if it collects new personal data,
   sets cookies/tracking, or sends user data to a new third party.
4. **Test-first** — Spawn `qa-engineer` to write failing tests for the acceptance
   criteria before implementation (`docs/TESTING.md` §3), including the e2e spec
   when the feature adds or changes a core flow. Require **red evidence** (the
   failing run output) in its handoff. Skipping is allowed only for changes with
   nothing testable — record the justification for the PR's Testing section.
5. **Build** — Delegate each planned task to its owning specialist. Run tasks
   with disjoint files in parallel (spawn in one turn); serialize on hot files;
   isolate parallel editors in worktrees per `docs/WORKTREES.md`.
6. **Verify** — Have `qa-engineer` run the full suite plus the e2e smoke set for
   any touched core flow; confirm the validation gate is green. Do not claim
   success without running it.
7. **Review** — Spawn `reviewer-architecture`, `reviewer-code-quality`, and (for
   security-relevant changes) `reviewer-security` in parallel.
8. **Fix & iterate** — Fix every CRITICAL, weigh WARNING/SUGGESTION, re-run the
   gate, re-review if needed (cap ~3 rounds).
9. **Ship** — when reviewers approve: re-run the pre-PR gate (lint + full suite
   + e2e smoke — the `pre-pr-gate.sh` hook blocks `gh pr create` while it's
   red), write atomic commits per `docs/COMMITS.md`, push the feature branch,
   and open a PR against `<integration-branch>` following the description spec
   in `docs/WORKFLOW.md` §8, with the gate results in its Testing section.
   Summarize what was built, the review verdicts, the exact commands to verify,
   and the PR URL.
10. **Stop at the PR.** Never merge it and do not start new feature work — the
    human reviews. Address their PR comments with follow-up commits on this same
    branch (fix, re-run the gate, push). The next `/feature` begins only after
    this PR is merged.

Right-size it: if this is a small change, collapse phases sensibly — but never
skip tests for anything with logic, and never skip security review when the
change touches auth, money, PII, uploads, or external input.
