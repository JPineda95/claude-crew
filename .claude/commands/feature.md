---
description: Run the full crew workflow to design, build, test, and review a feature.
argument-hint: <what to build>
---

Orchestrate the feature described below through the crew workflow in
`docs/WORKFLOW.md`. You are the orchestrator — delegate; don't do it all yourself.

**Feature:** $ARGUMENTS

Proceed:

1. **Intake** — Read `PROJECT.md`. Restate the request in one or two sentences and
   note any assumption. If something genuinely ambiguous would change the
   outcome, ask now; otherwise proceed.
2. **Design & Plan** — Spawn `architect` to produce a design brief and an
   execution plan (task list with owners, dependencies, and a hot-file map). Pull
   in `designer`, `database-architect`, and/or `security-engineer` if the feature
   needs them — and `data-compliance-officer` if it collects new personal data,
   sets cookies/tracking, or sends user data to a new third party.
3. **Test-first** — Spawn `qa-engineer` to write failing tests for the acceptance
   criteria before implementation.
4. **Build** — Delegate each planned task to its owning specialist. Run tasks
   with disjoint files in parallel (spawn in one turn); serialize on hot files;
   isolate parallel editors in worktrees per `docs/WORKTREES.md`.
5. **Verify** — Have `qa-engineer` run the full suite; confirm the validation
   gate is green. Do not claim success without running it.
6. **Review** — Spawn `reviewer-architecture`, `reviewer-code-quality`, and (for
   security-relevant changes) `reviewer-security` in parallel.
7. **Fix & iterate** — Fix every CRITICAL, weigh WARNING/SUGGESTION, re-run the
   gate, re-review if needed (cap ~3 rounds).
8. **Report** — Summarize what was built, the review verdicts, and the exact
   commands to verify. Then STOP and ask before committing (unless `PROJECT.md`
   opts into autonomous commits). Do not push or deploy without authorization.

Right-size it: if this is a small change, collapse phases sensibly — but never
skip tests for anything with logic, and never skip security review when the
change touches auth, money, PII, uploads, or external input.
