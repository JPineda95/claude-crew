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
| `diagrammer` | Architecture cartographer | opus | After building — (re)draw `docs/ARCHITECTURE.md`: component graph, core-flow sequences, ERD |
| `reviewer-architecture` | Design review gate | opus | Before merge — structure, patterns, maintainability |
| `reviewer-code-quality` | Correctness review gate | sonnet | Before merge — bugs, tests, readability |
| `reviewer-security` | Security review gate | opus | Before merge — esp. security-relevant diffs |

## The default lifecycle

**`/work` drives this lifecycle** — with a plain description (classic mode), a
ticket id, or across every Dev Ready ticket on the board
([TICKETS.md](./TICKETS.md)). `/feature`, `/bug`, `/spike`, and `/epic` *file
tickets*; they don't build.

Not every task needs every phase. Scale the process to the risk (see "Right-
sizing" below). The full path for a substantial feature:

```
0. Intake        orchestrator clarifies the request, reads PROJECT.md
1. Design        architect → (designer, database-architect, security-engineer as needed)
2. Plan          architect produces the task list, owners, dependencies, hot files
3. Test-first    qa-engineer writes failing tests (red)
4. Build         specialists implement in parallel where files are disjoint (green)
5. Verify        qa-engineer runs the full suite + e2e smoke; agents self-verify
6. Review        reviewer-architecture + reviewer-code-quality + reviewer-security (parallel)
7. Fix & iterate address CRITICAL/WARNING findings; re-review (max ~3 rounds)
8. Ship          gate green (lint + tests + e2e smoke) → commit, push, PR; human reviews & merges
9. Deploy        human runs /deploy → gate re-run → integration branch merged into production
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
**before** implementation ([TESTING.md](./TESTING.md) §3), including the e2e
spec when the feature adds or changes a core flow. Confirm they fail for the
right reason and capture the failing output as **red evidence** in the handoff.
TDD is the default for anything with logic; exemptions are narrow (pure
copy/docs/config) and MUST be recorded in the PR's Testing section — the
pre-PR hook refuses code changes that touch no tests.

### 4. Build (green)

Delegate each task to its owning specialist. Typical ordering by dependency:
`database-architect` (schema/contract) → `backend-engineer` (logic/API) →
`frontend-engineer` (UI) with `designer`/`copywriter`/`seo-aeo-specialist`
feeding specs and content. Independent tasks with disjoint files run in parallel
(see below). Each specialist writes the minimum code to make the tests pass and
follows the Engineering Charter.

### 5. Verify

Each agent self-verifies (runs the tests/app for its change). Then `qa-engineer`
runs the full suite plus the e2e smoke set for any touched core flow
([TESTING.md](./TESTING.md) §4–5), and does exploratory checks on the critical
path. Nothing proceeds on an unverified claim — run it and read the output; the
summary feeds the PR's Testing section.

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
follow [COMMITS.md](./COMMITS.md). Then the orchestrator ships — this is
standing policy, no per-feature authorization needed (`PROJECT.md` can set
**Ship mode: `ask`** to revert to prepare-and-wait):

1. **Run the pre-PR gate fresh**: lint + the full test suite, plus the e2e
   smoke set when configured ([TESTING.md](./TESTING.md) §5). This is also
   enforced deterministically — the `.claude/scripts/pre-pr-gate.sh` hook
   blocks `gh pr create` while the gate is red or unconfigured, or when the
   diff changes code without touching a single test.
2. Write atomic commits on the feature branch per [COMMITS.md](./COMMITS.md).
3. Push the feature branch — never the integration branch.
4. Open a PR against `<integration-branch>` with `gh pr create` (title in
   Conventional Commit style; for ticketed work append the ticket id as a
   suffix — `feat: add user invites (KANI-12)` — never `#`-prefixed, which
   GitHub would autolink to the wrong issue). Open it **from the branch's own
   checkout** — in a ticket worktree that means `cd <worktree> && gh pr create`
   so the pre-PR hook validates the right code. If `gh` is missing or
   unauthenticated, push, then hand the human the compare URL plus the
   description text.
5. Report the PR URL. When the CI gate is wired
   ([TESTING.md](./TESTING.md) §8), watch the PR's check: a red check is the
   crew's to fix on the feature branch before the human reviews. Then stop.

**The PR description** must let the reviewer judge the change without
re-deriving context:

- **Summary** — what the feature does and why, 2–4 sentences, user-visible
  behavior first.
- **Ticket** — for ticketed work: the ticket id and card URL
  ([TICKETS.md](./TICKETS.md) §5).
- **Changes** — grouped by area (schema / API / UI / tests / infra), one line
  each; call out key design decisions and any deviation from the design brief.
- **How to verify** — exact commands, plus **numbered manual testing notes** a
  human can follow click-by-click:

  ```
  1. Go to <url or screen>
  2. Click <button X> / submit <form>
  3. Confirm <observable outcome>
  ```

  For ticketed work, *generate* these from the card's acceptance criteria —
  one sequence per criterion — never paste the raw card (cards may hold
  internal details; PRs can be public).
- **Testing** — what is covered, the gate + e2e smoke results (paste the
  summary), and anything deliberately untested **with the reason** (TDD
  exemptions and `PR_GATE_ALLOW_NO_TESTS` overrides are justified here).
- **Crew review** — reviewer verdicts and rounds; any unresolved WARNINGs with
  the reasoning for shipping anyway.
- **Risks & follow-ups** — migrations, env/config changes, rollback notes,
  known limitations.

**The PR is the gate.** The human reviews and merges; the crew never merges its
own PR. Address review comments with follow-up commits on the same branch
(re-run the gate before pushing). `devops-engineer` handles the deploy and
rollback plan — deploys always require explicit authorization.

**PRs never target `main` (or the production branch).** Work integrates into
`<integration-branch>` only; a human-run `/deploy` (§9) is the sole path into
production. If `PROJECT.md` §5 names no integration branch separate from the
default branch, the crew creates `dev` off it first, pushes it, and records it
in §5.

**Open-PR policy (ticketed work):** at most one open crew PR per ticket (the
ticket id is the key), and never more open crew ticket-PRs than **Max parallel
tickets** (`PROJECT.md` §12, default 3). Crew PRs are identified by their
head-branch pattern `<type>/<PREFIX>-<n>-*` via `gh pr list --json headRefName`.
Do not start new ticket work while any open crew PR has unaddressed human
change requests. Ticketless work keeps the classic rule: one open crew PR at a
time. Ticketless crew PRs are recognized by the `Crew review` section in
their body (`gh pr list --json headRefName,body`).

This section is normative — it supersedes any older "one feature → one open PR"
phrasing elsewhere.

### 9. Deploy

Projects that separate an integration branch from a production branch (e.g.
`dev` → `main`, both set in `PROJECT.md` §5) promote with **`/deploy`**: it
re-runs the validation gate on the integration branch, merges it into the
production branch with `--no-ff`, and pushes — whatever pipeline watches the
production branch takes it from there. The human running `/deploy` is the
explicit authorization that deploys require; the crew never promotes on its own
initiative. If the production branch is protected against direct pushes, the
command opens a release PR instead. When the two branches are the same, there
is no promotion step and `/deploy` is a no-op. On ticketed projects, `/deploy`
also advances the board: cards whose merge is in the promoted release move
Dev Complete → In QA ([TICKETS.md](./TICKETS.md) §1).

### 10. Tickets & the board (optional)

Projects can put a Notion kanban in front of this lifecycle —
[TICKETS.md](./TICKETS.md) is the charter. In short: `/board` creates the
board; `/feature`, `/bug`, `/spike`, `/epic` interview you and file complete
cards in **Backlog**; a human moves cards to **Dev Ready** (the triage gate);
`/work <id>` or batch `/work` runs the lifecycle above per ticket, moving the
card In Progress → Code Review as it goes; a merge sweep and `/deploy` advance
merged work; the human closes the loop at In QA → Done. Without a board,
nothing changes: `/work <description>` is the whole classic flow.

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
- **Across tickets** (batch `/work`): waves, a cross-ticket hot-file pre-flight,
  and a serialized ship phase — see WORKTREES.md §11.

## Right-sizing the process

| Change | Process |
|---|---|
| Typo, comment, config value, one-line fix | Direct edit → run gate → done. No crew. |
| Small, localized feature/bugfix with logic | qa-engineer (test) → one specialist → one or two reviewers |
| Substantial feature across layers | Full lifecycle (design → plan → test → build → verify → review → ship) |
| Anything touching auth/money/PII/uploads | Add `security-engineer` at design and `reviewer-security` at the gate — non-negotiable |
| Public, indexable pages | Add `seo-aeo-specialist` and `copywriter` |
| New personal-data collection, cookies/analytics, new data-receiving third party, public launch | Add `data-compliance-officer` (data map + artifacts + gap check) |
| Lost track of what was built / how it's wired | Run `/diagram` — `diagrammer` maps it into `docs/ARCHITECTURE.md` (read-only on code) |

Use judgment. The process exists to catch expensive mistakes, not to add ceremony
to cheap ones.

## Handoffs

Every agent ends with the structured handoff from the Engineering Charter
(`docs/ENGINEERING.md` §4): what it did, files touched, how to verify, decisions,
open questions, and the recommended next step. The orchestrator threads these
handoffs together — it is the only component that holds the whole picture.
