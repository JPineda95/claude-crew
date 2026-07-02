# Workflow — How the Crew Operates

> The playbook the **orchestrator** (root `CLAUDE.md`, running in the main
> thread) follows to route work to the right specialist at the right time. The
> orchestrator delegates; specialists execute in their own context and report
> back. Subagents do not spawn subagents — all fan-out is driven from the main
> thread.

## The roster at a glance

| Agent | Role | Model | Spin up when… |
|---|---|---|---|
| `architect` | Principal / tech lead | opus | A non-trivial feature/refactor needs design & decomposition first |
| `designer` | Product & UI/UX design | sonnet | A feature needs a flow, screen, or design-system decision |
| `database-architect` | Data modeling / DBA | opus | Schema, migrations, indexing, RLS, or query performance |
| `backend-engineer` | Server / APIs / logic | sonnet | Endpoints, business logic, auth, jobs, integrations |
| `frontend-engineer` | UI implementation | sonnet | Components, pages, client state, what the user sees |
| `qa-engineer` | Test strategy / SDET | sonnet | Before impl (write failing tests) and after (verify) |
| `security-engineer` | AppSec (design/harden) | opus | Anything touching auth, money, PII, uploads, external input |
| `devops-engineer` | Platform / CI/CD / SRE | sonnet | Build, deploy, infra, config, observability |
| `copywriter` | UX writing / copy | sonnet | UI text, errors, emails, marketing/landing copy |
| `seo-aeo-specialist` | SEO / AEO | sonnet | Public, indexable pages; discoverability; structured data |
| `data-compliance-officer` | Data protection / privacy | opus | New personal-data collection, cookies/tracking, third-party processors, launch prep |
| `reviewer-architecture` | Design review gate | opus | Before merge — structure, patterns, maintainability |
| `reviewer-code-quality` | Correctness review gate | sonnet | Before merge — bugs, tests, readability |
| `reviewer-security` | Security review gate | opus | Before merge — esp. security-relevant diffs |

## The default lifecycle

Not every task needs every phase. Scale the process to the risk (see "Right-
sizing" below). The full path for a substantial feature:

```
0. Intake        orchestrator clarifies the request, reads PROJECT.md
1. Design        architect → (designer, database-architect, security-engineer as needed)
2. Plan          architect produces the task list, owners, dependencies, hot files
3. Test-first    qa-engineer writes failing tests (red)
4. Build         specialists implement in parallel where files are disjoint (green)
5. Verify        qa-engineer runs the suite; agents self-verify (run the app/tests)
6. Review        reviewer-architecture + reviewer-code-quality + reviewer-security (parallel)
7. Fix & iterate address CRITICAL/WARNING findings; re-review (max ~3 rounds)
8. Ship          orchestrator prepares commits; human authorizes; devops deploys
```

### 0. Intake

The orchestrator restates the request, resolves obvious ambiguity, and reads
`PROJECT.md`. If the task is trivial (typo, config tweak, one-line fix), skip to
a direct edit + verify — don't convene the whole crew. If the request itself is
ambiguous in a way that changes the outcome, ask before building.

### 1. Design

Spin up `architect` for any feature that spans more than one file or introduces a
new pattern. The architect pulls in, as the problem requires:
- `designer` when there's a UI flow or visual decision,
- `database-architect` when data structures change,
- `security-engineer` when the surface touches auth/money/PII/uploads/external
  input,
- `data-compliance-officer` when the feature collects new personal data, sets
  cookies/tracking, or sends user data to a new third party.

Output: a Technical Design Brief (see the `architect` spec). For small changes,
this is a few lines; for big ones, a real design with alternatives.

### 2. Plan

The architect's brief ends with an **execution plan**: an ordered task list, each
task tagged with its owning agent, its inputs/outputs, its dependencies, and a
**hot-file map** (files multiple tasks touch). The orchestrator uses this to
decide what runs in parallel and what must serialize (see "Parallelization").

### 3. Test-first (red)

Spin up `qa-engineer` to translate acceptance criteria into failing tests
**before** implementation. Confirm they fail for the right reason. This is the
default per the TDD workflow; skip only for changes with no testable logic.

### 4. Build (green)

Delegate each task to its owning specialist. Typical ordering by dependency:
`database-architect` (schema/contract) → `backend-engineer` (logic/API) →
`frontend-engineer` (UI) with `designer`/`copywriter`/`seo-aeo-specialist`
feeding specs and content. Independent tasks with disjoint files run in parallel
(see below). Each specialist writes the minimum code to make the tests pass and
follows the Engineering Charter.

### 5. Verify

Each agent self-verifies (runs the tests/app for its change). Then `qa-engineer`
runs the full suite and does exploratory/e2e checks on the critical path. Nothing
proceeds on an unverified claim — run it and read the output.

### 6. Review (the gate)

Spin up the reviewers **in parallel**:
- `reviewer-architecture` — structure, patterns, maintainability, design fit
- `reviewer-code-quality` — correctness, edge cases, tests, readability
- `reviewer-security` — always for security-relevant diffs; recommended for all

Each returns `APPROVE` or `REQUEST CHANGES` with severity-tagged findings.

### 7. Fix & iterate

Address every **CRITICAL** immediately; weigh **WARNING**/ **SUGGESTION**. Route
each finding back to the owning specialist. Re-run the validation gate. If fixes
introduce new issues, re-review — cap at ~3 rounds, then escalate to the human.

### 8. Ship

Only when: all reviewers `APPROVE`, the validation gate is green, and commits
follow [COMMITS.md](./COMMITS.md). The orchestrator prepares atomic commits and
**waits for explicit human authorization** to commit/push unless `PROJECT.md`
opts into autonomous commits. `devops-engineer` handles the deploy and rollback
plan.

## Parallelization & worktrees

- **Parallel when files are disjoint.** If `architect`'s hot-file map shows two
  tasks don't touch the same files, run them concurrently — spawn both agents in
  one turn. For genuinely concurrent *edits*, isolate each agent in its own
  worktree (`isolation: worktree`, or `claude --worktree`) per
  [WORKTREES.md](./WORKTREES.md).
- **Serialize on hot files.** Tasks that share a file (config, barrel/index,
  lockfile, i18n table) run one at a time, or one agent owns that file — use the
  advisory lock convention (WORKTREES.md §8).
- **Reviews always parallelize** — the three reviewers are read-only and never
  conflict.
- **Integrate frequently** to keep branches short-lived (COMMITS.md §1).

## Right-sizing the process

| Change | Process |
|---|---|
| Typo, comment, config value, one-line fix | Direct edit → run gate → done. No crew. |
| Small, localized feature/bugfix with logic | qa-engineer (test) → one specialist → one or two reviewers |
| Substantial feature across layers | Full lifecycle (design → plan → test → build → verify → review → ship) |
| Anything touching auth/money/PII/uploads | Add `security-engineer` at design and `reviewer-security` at the gate — non-negotiable |
| Public, indexable pages | Add `seo-aeo-specialist` and `copywriter` |
| New personal-data collection, cookies/analytics, new data-receiving third party, public launch | Add `data-compliance-officer` (data map + artifacts + gap check) |

Use judgment. The process exists to catch expensive mistakes, not to add ceremony
to cheap ones.

## Handoffs

Every agent ends with the structured handoff from the Engineering Charter
(`docs/ENGINEERING.md` §4): what it did, files touched, how to verify, decisions,
open questions, and the recommended next step. The orchestrator threads these
handoffs together — it is the only component that holds the whole picture.
