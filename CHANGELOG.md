# Changelog

All notable changes to claude-crew. Follows [Keep a Changelog](https://keepachangelog.com/)
loosely; versions follow SemVer via `.claude-plugin/plugin.json`.

## Unreleased

### Added

- **`.claude/crew.env` — a single, committed source of truth for the gate.**
  Previously the README/install.sh told new users to "set your validation
  gate in `.claude/scripts/validate.sh`", but the pre-PR hook read only the
  `CLAUDE_VALIDATE_CMD` environment variable — so following that instruction
  left every first PR blocked with "no validation gate is configured", and
  editing validate.sh permanently marked it customized (`.crew-new` noise on
  every future update). `.claude/crew.env` fixes both: `install.sh`/`update.sh`
  seed it once (never touched again afterward, like `PROJECT.md`), `/onboard`
  writes the confirmed gate command into it, and both hooks
  (`validate.sh`, `pre-pr-gate.sh`) source it. A value already exported in the
  session/`.claude/settings.local.json` environment still wins, so existing
  installs (e.g. kani) keep working unchanged. README, `PROJECT.template.md`,
  and `docs/TESTING.md` §5/§8 updated to point at it as the single route.
- **Downgrade guard in the updater.** `scripts/update.sh` (and the
  self-updating `.claude/scripts/crew-update.sh`) now refuse to sync when the
  project's installed content is not an ancestor of the ref being synced —
  e.g. a project installed from a newer or dogfooded branch would otherwise be
  silently reverted by a routine sync against an older `main`. Both the
  manifest (`install.sh`/`update.sh`) and the guard's error message record and
  surface the source ref (`# ref:`); pre-2.4 manifests report "unknown"
  instead of guessing. Pass `--allow-downgrade` (either script, any position)
  to bypass deliberately.
- **SOLID & Clean Code are now a first-class standard** (`docs/ENGINEERING.md`
  §6): a new, technology-agnostic charter section spelling out the five SOLID
  principles and a concrete Clean Code checklist (intention-revealing names,
  small single-purpose functions, guard clauses, DRY-without-wrong-abstraction,
  command/query separation, fail-fast, no magic values), plus an "apply without
  dogma" clause (YAGNI, match-the-codebase, severity-scales-with-blast-radius).
- **Enforced at the gate.** `reviewer-architecture` now reviews for SOLID
  violations (God-objects, open/closed switch-ladders, dependency direction) and
  `reviewer-code-quality` for the Clean Code checklist — both citing §6 with
  proportionate severity. The Definition of Done (§3) gains a §6 checkbox, and
  the root `CLAUDE.md` Standards summary names the standard.
- **Applied at authoring time.** `architect`, `backend-engineer`,
  `frontend-engineer`, and `database-architect` each gained a §6 pointer so the
  principles shape the code as it's written, not only when it's reviewed.

### Changed

- Charter sections renumbered after inserting §6: Shell discipline is now §8,
  Git discipline §9. Cross-references updated.

## 2.3.0 — 2026-07-05

### Added

- **`/diagram` — an architecture map you can read.** A new command drives a new
  read-only **`diagrammer`** specialist that reverse-engineers the codebase and
  writes/refreshes **`docs/ARCHITECTURE.md`** with three Mermaid diagram families:
  a **system/component graph** (`flowchart`), a **`sequenceDiagram` per core
  flow** (auth, primary create/checkout path, key jobs — sourced from
  `docs/TESTING.md`'s e2e flow list when present), and a **data-model ERD**
  (`erDiagram`). Answers "what did we build and how is it wired?" after a batch of
  `/work`.
  - **Focused runs.** Maps the whole system by default, or scopes to
    `path:<dir>`, `flow:<name>`, `system`, or `data` (or a free-text hint) — a
    focused run refreshes only the sections it covers.
  - **Zero dependency.** Mermaid is emitted as text and renders natively on
    GitHub, in Obsidian, and in VS Code; images can be exported on demand with
    `npx @mermaid-js/mermaid-cli` without adding a project dependency.
  - **Living doc.** Generated content sits between
    `<!-- crew:diagram:start/end -->` markers so re-runs refresh the diagrams
    without clobbering human-authored sections, and a `Last mapped: <sha>` footer
    makes staleness visible.
  - **Documents, never redesigns.** Read-only on application code (writes only
    `docs/ARCHITECTURE.md`); every node must trace to real code, unresolved
    wiring is marked `TODO: verify` rather than guessed, and architectural smells
    are surfaced as recommendations for `architect`.
  - Roster is now **15 subagents**; `CLAUDE.md`, `README.md`, `docs/WORKFLOW.md`,
    and the plugin manifests updated accordingly.

### Changed

- **`crew-update.sh` now syncs the released line (`main`) by default**, instead
  of whatever branch a local crew checkout happens to be sitting on — so a
  project can never pick up unreleased or open-PR work by accident. It fetches
  and materializes `origin/${CREW_REF:-main}` in a throwaway detached worktree
  (your working tree is never touched), then runs the sync from that. Set
  `CREW_REF` to dogfood a specific branch or tag. Consequence: a crew feature
  reaches your projects only once you've promoted it `dev → main` via `/deploy`.

### Fixed

- **`crew-update.sh` exited 1 after a successful local-source sync.** The `EXIT`
  trap's cleanup ran `[[ -n "${CLONED}" ]] && rm …`; on the common local-checkout
  path `CLONED` is empty, so the `&&` list ended non-zero and — being the last
  command in the trap — became the script's exit code even though the sync
  succeeded (red shell status; any `crew-update && next` wrapper would abort).
  Rewritten as an `if`, which always ends 0 when the test fails. Re-applies the
  fix from `898ddc0`, which was authored on `feat/never-commit-main` but was
  orphaned and never reached `dev`/`main`.

## 2.2.0 — 2026-07-03

### Added

- **CI — the remote twin of the gate** (`docs/TESTING.md` §8): every
  GitHub-hosted project SHOULD re-run the validation gate server-side on every
  PR via a `.github/workflows/gate.yml` workflow, made binding by a required
  branch-protection check on the integration branch. The section carries the
  rules (workflow mirrors `CLAUDE_VALIDATE_CMD` — same-PR sync required; PRs
  to integration AND production branches; no real secrets in the gate job —
  dummy env values for framework builds; e2e smoke at most per PR) and a
  reference workflow. `/tests` now scaffolds the workflow as part of
  bootstrapping (step 6), `PROJECT.md` §4 gains a **CI gate** line, and
  WORKFLOW.md §8 makes a red PR check the crew's to fix before human review.

## 2.1.0 — 2026-07-03

### Changed

- **New hard rule: the crew NEVER commits to `main`** (or the production/
  default branch) — only a human-run `/deploy` moves it. Projects without an
  integration branch separate from it get `dev` created automatically (off the
  default branch, pushed, recorded in `PROJECT.md` §5) the first time the crew
  works there; PRs always target the integration branch, never production.
  `PROJECT.template.md` §5's default integration branch is now `dev`.
  Encoded in CLAUDE.md guardrail 1, ENGINEERING.md §8, WORKFLOW.md §8,
  work.md, ship.md, and the `/onboard` interview.

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
