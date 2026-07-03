# Testing Charter

> Tests are the crew's executable specification — the documentation that never
> lies and the gate that keeps agents from breaking what already works. An AI
> crew moves fast and forgets between sessions; the suite is what remembers.
> Normative: **MUST / SHOULD / MUST NOT** carry RFC-2119 meanings.
> Technology-agnostic: the runner, e2e tool, and exact commands are declared in
> `PROJECT.md` §4 (Testing). `qa-engineer` owns this charter's enforcement.

## 1. The role of tests

- **Specification.** Acceptance criteria live as tests, not prose. If a
  behavior matters, a test asserts it; if no test asserts it, the crew may
  break it without noticing.
- **The gate.** Work is never "done because the agent says so" — it is done
  when the suite proves it. Reviewers and the pre-PR gate treat a red or
  missing suite as a stop, not a warning.
- **Documentation.** A newcomer — human or agent — learns what the system
  promises by reading the tests. Write them to be read.

## 2. The pyramid (budget by layer)

| Layer | How many | What they cover | Speed |
|---|---|---|---|
| Unit | Most | Pure logic, edge cases, failure modes — exhaustively | ms |
| Integration | Some | Real seams: DB queries, API handlers, auth flows | ms–s |
| E2E (core flows) | Few (≈5–10 specs) | The user journeys that must never break | s–min |

Test **behavior, not implementation** — assert on observable outputs and
effects so tests survive refactors. Craft details (determinism, structure,
what to probe) live in the `qa-engineer` spec.

## 3. TDD protocol (the default)

TDD is the default for **anything with logic** — new features, bug fixes,
behavior changes:

1. **Red** — `qa-engineer` turns the acceptance criteria into failing tests
   and MUST include the failing run's output in its handoff (**red
   evidence** — a test that has never failed proves nothing).
2. **Green** — the implementer writes the minimum code to pass and runs the
   affected tests before handing off.
3. **Refactor** — clean up with the suite green; the suite is the safety net.

**Exemptions are narrow**: pure copy, docs, comments, formatting, or config
with no behavioral effect. An exemption MUST be stated in the PR's Testing
section ("Tests: none — <reason>"), never silent. Every bug fix ships with a
regression test that fails without the fix — no exceptions.

**Ticketed work** ([TICKETS.md](./TICKETS.md)): the card's acceptance criteria
ARE the acceptance criteria — **one red test per criterion**. Criteria too
vague to fail a test fail the Definition of Ready (TICKETS.md §4) and get
repaired or skipped before any code is written. For Bugs, the card's
regression criteria drive the mandatory failing regression test.

## 4. Core flows & e2e

`PROJECT.md` §4 lists the project's **core flows** — the ≈5–10 user journeys
whose breakage is an incident (sign-up, the money path, the product's central
loop). The registry rules:

- **Every core flow has an e2e spec.** No spec → the flow is unprotected →
  writing it is the next work item (`/tests`).
- A feature that adds or changes a core flow updates the registry AND its
  spec **in the same PR**. `qa-engineer` keeps both current.

**Default e2e tool for web UIs: Cypress** (a project already standardized on
another tool declares it in `PROJECT.md` and these rules apply unchanged):

- Specs live in `cypress/e2e/`, one spec per core flow, named after the flow.
- Select by dedicated attribute (`data-cy="…"`), never by CSS class or copy —
  styles and text change; test contracts shouldn't. `frontend-engineer` adds
  the attributes as part of building UI.
- Seed state through APIs or `cy.task()`, not by clicking through the UI.
  Each spec creates and cleans its own data and runs independently.
- No fixed sleeps — `cy.wait(3000)` is a flake generator. Wait on intercepted
  requests (`cy.intercept`) or on visible assertions.
- Keep a **smoke subset** (tag or spec list, declared in `PROJECT.md`) fast
  enough to run before every PR; the full e2e set can run on a schedule.

Projects without a browser UI (CLI, library, API-only) keep the same registry
rules with whatever top-level harness fits — a CLI runner, an API client suite.
"No e2e layer" is legitimate only when `PROJECT.md` §4 says so explicitly and
the core flows are covered at the integration layer instead.

## 5. Where the gates run

| When | What runs | Enforced by |
|---|---|---|
| During build | Tests affected by the change | Each specialist (charter DoD) |
| Verify phase | Full suite + e2e smoke for touched core flows | `qa-engineer` |
| **Before any PR** | **Lint + full suite (+ e2e smoke when configured)** | `.claude/scripts/pre-pr-gate.sh` — a PreToolUse hook that **blocks `gh pr create`** while red or unconfigured |
| End of any coding turn | The validation gate | `.claude/scripts/validate.sh` (Stop hook) |

Configure once per project (in `.claude/settings.local.json` under `env`, or
exported in the environment):

- `CLAUDE_VALIDATE_CMD` — lint + full test suite (+ typecheck/build), e.g.
  `npm run lint && npm run test`.
- `CLAUDE_E2E_SMOKE_CMD` — optional but recommended once Cypress exists, e.g.
  `npx cypress run --spec "cypress/e2e/smoke/**"`.
- `CLAUDE_INTEGRATION_BRANCH` — only when auto-detection isn't enough: unset,
  the hook prefers `dev` when the repo has one (the crew never integrates on
  `main`), else `main` (it diffs against this branch for the
  tests-accompany-logic check).

The pre-PR hook also refuses a PR whose diff **changes code without touching a
single test file**. For the narrow exemptions of §3, retry as
`PR_GATE_ALLOW_NO_TESTS=1 gh pr create …` — the override MUST be justified in
the PR's Testing section. (`PR_GATE_SKIP=1` skips the whole gate but only works
from the human's environment — agents can't set it inline.)

**Worktrees:** the pre-PR hook honors a leading `cd <dir> &&` and runs the gate
and the diff check **in that directory** — so open ticket PRs as
`cd <worktree> && gh pr create …` (WORKTREES.md §11). Without a `cd` prefix it
refuses to run from a checkout sitting on the integration branch. Known
limitation: the Stop-hook gate (`validate.sh`) checks only the session's main
checkout — with all edits in ticket worktrees it no-ops; the pre-PR gate is the
enforcement point that matters.

## 6. Projects with no tests yet

An empty suite is the crew's first work item, not a permanent state. Run
`/tests`: it audits what exists, ranks the gaps by risk (core flows first,
then the auth/money/data seams, then hairy logic), scaffolds the runner and
Cypress where missing, wires the gate commands above, and ships the suite
through the normal PR flow. Until the gate is configured, the pre-PR hook
blocks all PRs — configure it in the same PR that bootstraps the suite.

## 7. Flake policy

A flaky test is a broken test. Quarantine it the day it flakes (skip **with**
a tracking TODO naming an owner), then fix or delete it within the week.
Never re-run a suite until it happens to pass and call that green — fix the
cause. Determinism rules (fake time and randomness, isolated state) are in
the `qa-engineer` spec.
