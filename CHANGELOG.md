# Changelog

All notable changes to claude-crew. Follows [Keep a Changelog](https://keepachangelog.com/)
loosely; versions follow SemVer via `.claude-plugin/plugin.json`.

## 2.0.0 — 2026-07-03

### ⚠ Breaking

- **`/feature` no longer runs the build lifecycle.** It now interviews you and
  files a **Story ticket** in the backlog. The build lifecycle moved to
  **`/work`** — `/work <description>` behaves exactly like the old `/feature`,
  with or without a board. On projects without Notion, `/feature` explains
  once and offers the classic build; record `Ticketing: none` in
  `PROJECT.md` §12 to silence it permanently.
  - **Upgraders via `update.sh`:** a pristine `feature.md` is replaced in
    place; a customized one is kept, with the new version landing as
    `feature.md.crew-new` — merge it deliberately (update.sh prints a warning).
  - **Plugin users:** commands are replaced wholesale on update.

### Added

- **Optional Notion kanban ticket layer** (`docs/TICKETS.md` — the charter):
  - **`/board`** — creates the project's Notion section (a summary page from
    `PROJECT.md` + a kanban database with native ticket ids like `KANI-12`);
    doubles as status/repair/sweep when the board exists. On blank repos it
    proposes a starter backlog from `PROJECT.md`; on existing code it creates
    infrastructure only.
  - **`/work`** — the build command: a ticket by id, every Dev Ready ticket in
    parallel worktrees (waves, cross-ticket hot-file pre-flight, serialized
    ship phase, one PR per ticket), or a plain description.
  - **`/bug`**, **`/spike`**, **`/epic`** — interview → complete cards
    (Bug: repro/expected/actual + regression criteria; Spike: timeboxed
    question with findings written back to the card; Epic: architect-assisted
    breakdown into linked child Stories — epics are never workable).
  - Statuses: Backlog → Dev Ready → In Progress → Code Review → Dev Complete →
    In QA → Done. The crew moves cards as work progresses; a merge sweep
    reconciles merged PRs; Backlog→Dev Ready and In QA→Done stay human.
  - `PROJECT.template.md` gains **§12 Ticketing** (board ids, ticket prefix,
    `Max parallel tickets`).
- **Manual testing notes in every PR** — the `How to verify` section now
  carries numbered click-by-click steps (Go to… / Click… / Confirm…),
  generated from acceptance criteria for ticketed work (`docs/WORKFLOW.md` §8).
- **Open-PR policy** for parallel ticket work (`docs/WORKFLOW.md` §8,
  normative): one open crew PR per ticket, a global cap (`Max parallel
  tickets`), and a review-debt gate.
- `docs/WORKTREES.md` §11 — cross-ticket parallelism (waves, ticket cap vs
  agent ceiling, serialized ship phase).
- `docs/TOOLING.md` — Notion MCP entry (orchestrator, optional) with the
  plan-tier and allowlisting caveats.
- `Refs: <TICKET-ID>` commit-trailer convention (`docs/COMMITS.md` §4).
- **Self-updating installs** — `.claude/scripts/crew-update.sh` now ships with
  the crew into every consuming project: run it from inside the project to
  pull the latest crew (resolves the source via the manifest's `# source:` /
  `# remote:` lines, or clones the public repo; `CREW_SOURCE`/`CREW_REPO`/
  `CREW_REF` override), then hands off to the manifest-protected
  `update.sh` sync. Manifests now record the source's git remote.

### Fixed

- **`pre-pr-gate.sh` validated the wrong checkout for worktree-origin PRs**:
  it now honors a leading `cd <dir> &&` and runs the validation gate *and* the
  tests-accompany-code diff check in that directory, and refuses `gh pr create`
  from a checkout sitting on the integration branch.
- **Plugin builds shipped no pre-PR gate**: `build-plugin.sh` now emits the
  PreToolUse hook alongside the Stop hook in `hooks.json`, so plugin installs
  get the same PR blocking as clone/install layouts.

## 1.1.0 and earlier

Pre-changelog. See `git log`.
