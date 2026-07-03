---
description: Bootstrap or backfill the test suite — audit the gaps by risk, then build unit/integration/e2e coverage for the core flows.
argument-hint: "[optional focus: a module, a flow, or blank for a full audit]"
---

Build out this project's test suite per `docs/TESTING.md`. You are the
orchestrator — delegate the work to `qa-engineer`. Focus: $ARGUMENTS

Proceed:

1. **Read the testing contract.** `PROJECT.md` §4 (Testing): runner, e2e tool,
   core flows, TDD policy. If the section is missing or empty, run a short
   interview first (runner and e2e tool — default Cypress for web UIs — plus
   the 5–10 core flows) and write the answers back into `PROJECT.md`.
2. **Audit** — spawn `qa-engineer` to inventory what exists: test files, what
   they actually assert, which core flows have e2e specs, and which of the
   risky seams (auth, money, data mutations, external input) are untested.
   Output: a gap list ranked by risk.
3. **Plan** — an ordered backlog, presented for confirmation before building:
   1. Runner / Cypress scaffolding, if missing (config, folder layout, a
      passing example spec, `data-cy` conventions).
   2. An e2e smoke spec for **every core flow** with none.
   3. Integration tests for the risky seams from the audit.
   4. Unit tests for the hairiest logic (boundaries, failure paths).
   5. Wire the gates: the validation-gate command and e2e smoke command in
      `PROJECT.md` §3–4, and `CLAUDE_VALIDATE_CMD` / `CLAUDE_E2E_SMOKE_CMD`
      in `.claude/settings.local.json` env so `validate.sh` and
      `pre-pr-gate.sh` enforce them.
4. **Build** — delegate waves to `qa-engineer` (parallelize where files are
   disjoint, worktrees per `docs/WORKTREES.md`). Every new test must fail if
   the behavior it protects breaks — spot-check by mutation (temporarily break
   the code, watch the test go red, restore).
5. **Verify & ship** — full gate green, then ship per Ship mode: feature
   branch, atomic commits, PR whose description shows coverage before → after
   and the core-flow registry status.

A tests-only branch is exempt from the "tests accompany logic" hook check by
nature — it IS the tests.
