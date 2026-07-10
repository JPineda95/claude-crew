# Changelog

All notable changes to claude-crew. Follows [Keep a Changelog](https://keepachangelog.com/)
loosely; versions follow SemVer via `.claude-plugin/plugin.json`.

## Unreleased

### Fixed

- **The vendored `impeccable` skill is no longer broken in every install.**
  Its setup instructions and reference docs hardcoded `.agents/skills/`
  paths (upstream's own layout) while this crew vendors it at
  `.claude/skills/`, so its own mandatory setup command failed with
  module-not-found everywhere. `SKILL.md` and `reference/*.md` normalized;
  new `scripts/vendor-skills.sh` re-normalizes them after any future
  `npx skills add/update`. **Not** touched: `scripts/hook-admin.mjs`'s
  multi-tool hook-manifest table, where a `.agents/skills/` entry
  intentionally configures a *different* tool's (Codex) own separate
  installation of the same skill — an earlier pass at this fix incorrectly
  rewrote it too, which would have silently broken multi-tool hook support;
  caught and reverted before landing.
- **Third-party skills redistributed without their licenses.** `impeccable`
  is Apache-2.0, whose §4(a) requires redistributions to include the
  license text; the three MIT-licensed sources require their copyright
  notices preserved. New `THIRD_PARTY_LICENSES.md` carries all four
  upstream license texts verbatim (fetched from each source repo), linked
  from `LICENSE`, the README taste-library table, and `docs/TOOLING.md`.
- **`skills-lock.json` was missing `ui-ux-pro-max`** (the ninth vendored
  skill) and its `computedHash` values were unverifiable — nothing in the
  repo ever read them. Reverse-engineered the real hashing scheme from the
  `skills` CLI's own source (verified byte-for-byte against two existing
  entries before being trusted); new `.claude/scripts/verify-skills.sh`
  recomputes and reports drift for all nine skills, wired into
  `crew-update.sh` so every sync ends with a drift report. The lock is now
  fully accurate against current content (all nine skills verify clean).
- **Plugin installs (Option C) no longer silently degrade.** Every
  agent/command referenced `docs/...` and `PROJECT.template.md` at
  project-root-relative paths that don't exist in a plugin-only install, and
  Claude Code has no mechanism to auto-load a plugin's `CLAUDE.md` as the
  orchestrator — so a plugin user previously got agents whose first
  instruction targeted a nonexistent file and no orchestrator persona at
  all, with nothing in the README saying so. `scripts/build-plugin.sh` now
  rewrites those eight doc references (and `PROJECT.template.md`) in the
  copied agents/commands to `${CLAUDE_PLUGIN_ROOT}/...`, and a new
  **`/crew-init`** command (plugin-only) copies `CLAUDE.md`, `docs/`, and
  `PROJECT.template.md` out of the plugin into the project root. README
  Option C now says plainly what the plugin form does and doesn't give you,
  and that `/plugin marketplace add` from GitHub won't work until `dist/` is
  built locally (it's generated, not committed).
- **`.claude-plugin/marketplace.json`'s plugin-entry version was stale**
  (1.1.0 while `plugin.json` said 2.3.0 — a two-minor drift nobody had
  caught). Fixed, and `build-plugin.sh` now syncs it on every build (only
  the `plugins[].version` field — never the unrelated top-level marketplace
  schema `"version": "1"`) and fails the build if `plugin.json`'s version
  has no matching `CHANGELOG.md` heading.
- **`/crew-update` excluded from the plugin bundle.** Its whole mechanism is
  the clone/copy distribution's manifest-based sync
  (`.claude/crew-manifest`, `.claude/scripts/crew-update.sh`) — neither
  exists in a plugin-only install, which updates via `/plugin update`
  instead. Shipping it there would have been another silent no-op.

### Added

- **`/status`** — a strictly read-only session opener: branch state vs the
  integration branch, open crew PRs against the open-PR policy cap, commits
  awaiting `/deploy`, stale worktrees, whether the validation gate is
  configured, board status (when ticketing is on), and any unfinished
  `/crew-update` merges. Never writes, commits, or runs the gate — only
  looks and reports. Recommended as the session opener in CLAUDE.md.
- **`/crew-update`** — wraps `.claude/scripts/crew-update.sh` (previously
  undiscoverable from inside a session; no consuming project ever ran it) and
  interactively walks any `.crew-new` merge conflicts the sync drops:
  distinguishes add/add collisions (mergeable — proposes a union merge
  keeping both sides) from true edit/edit conflicts (escalates, never
  guesses which side wins), gets explicit approval before writing, and
  flags the CI same-PR sync rule when the gate scripts changed.

### Fixed

- **`allowed-tools` now cover the commands' own preambles.** `ship.md`,
  `deploy.md`, `review.md`, `diagram.md`, and `.claude/settings.json` declared
  exact-match `Bash(git status)` while their `!`-context preambles ran
  compound commands (`git status --short && echo "---" && ...`) — not
  pre-approved by their own frontmatter under default permission mode. Fixed
  to `Bash(git status:*)` everywhere, and split each compound preamble into
  one command per `!` line (dropping the `echo "---"` separators — each part
  is now independently wildcard-covered).
- **`/feature`'s picker description no longer carries dead v2 migration
  history** ("(v2: the build lifecycle moved to /work...)") — a stranger
  installing today never saw v1, so a third of what they see in the command
  picker was noise. Rewritten to present tense; README's matching note
  updated too.
- **Frontmatter quoting normalized** across all 15 command files — `description`
  and `argument-hint` are now consistently double-quoted everywhere (was
  arbitrary: e.g. `epic.md` quoted `description` but not `argument-hint`,
  `bug.md` the reverse).

### Changed

- **`/onboard` defaults to express mode.** The interview previously walked
  the template one section per turn unconditionally — up to 12 round-trips
  even when the silent scan already answered most of it, the top of the
  funnel for a stranger evaluating the boilerplate. It now presents the
  complete pre-filled draft in one message plus a single batched question set
  covering only what a scan can't answer (purpose, core flows, ship mode,
  compliance basics, the validation gate) — target ≤2 turns. The full
  section-by-section walk is still available via `/onboard thorough`, for a
  messy or greenfield repo where batching would guess too much. Also: a
  `PROJECT.md` that's still the unfilled template (all-italics guidance, no
  real values — what Option A's `cp PROJECT.template.md PROJECT.md` leaves
  behind) is now treated as a first run, not update mode.

- **`frontend-engineer` now loads the taste library.** The nine anti-slop
  design skills were only ever instructed via `designer`'s handoff — a UI
  task routed straight to `frontend-engineer` (which "right-size it" actively
  encourages for small changes) built with no taste guardrails at all, even
  though `build-plugin.sh` claimed the skills were "used by designer +
  frontend-engineer". `frontend-engineer` now always loads `impeccable` for
  UI work and treats a `designer` handoff's named skills as mandatory.
- **`reviewer-security` no longer references a tool it can't invoke.** It was
  instructed to run "the built-in `/security-review` analysis", but its
  allowlist (Read, Grep, Glob, Bash, WebFetch) has no way to call a slash
  command — dead prompt weight that could cause a stall or a false claim.
- **`diagrammer`'s shell-discipline citation pointed at the wrong section**
  (§7, "Escalation & boundaries", after the SOLID renumbering) — fixed to §8.
  The four agents that actually run installs/scaffolds/builds
  (`backend-engineer`, `frontend-engineer`, `devops-engineer`, `qa-engineer`)
  now each carry the shell-discipline reminder directly, rather than relying
  on the orchestrator to inject it into every task prompt.
- **`qa-engineer` no longer hardcodes Cypress** in an otherwise stack-agnostic
  crew — it now defers to the e2e tool declared in `PROJECT.md` §4 (Cypress
  stays the crew *default*, documented in `docs/TESTING.md`), so a project
  standardized on another tool doesn't get contradictory instructions.
- **`reviewer-architecture`'s description no longer collides with
  `reviewer-code-quality`'s** trigger vocabulary ("code-quality", "naming")
  for Claude's automatic subagent selection — retitled to "Architecture &
  design reviewer".

### Changed

- **Model tiers**: `diagrammer` and `database-architect` moved from `opus` to
  `sonnet` — both are implementation/transcription roles (the diagrammer
  documents what exists; the DBA's sibling implementer `backend-engineer` is
  already `sonnet`), not the judgment-heavy design/review work `opus` is
  reserved for. README's roster table gained a one-line tier rationale.
- **`designer` and `security-engineer` gained explicit tool allowlists**
  (previously unset, inheriting Write/Edit despite neither shipping
  production code) — matching the read/research-only pattern `architect`
  already uses; `designer` also gets `Skill` since it must load the taste
  library.
- **`/review` now fingerprints the working tree** before and after spawning
  the three reviewers (`git status --porcelain` + `git diff HEAD`, hashed) —
  their "read-only" claim was enforced only by prose despite carrying `Bash`
  in their allowlist; a divergence now surfaces as a loud warning in the
  report instead of silently trusting suspect findings.

- **`docs/COMMITS.md` §1 no longer contradicts the crew's hardest guardrail.**
  It previously said agents may integrate into "either `main` directly
  (trunk-based) or a shared `dev`/`integration` branch" — normative text an
  agent is told to read before committing, directly contradicting CLAUDE.md
  guardrail 1 ("NEVER commit to `main`"), `docs/ENGINEERING.md` §9, and
  `docs/WORKFLOW.md` §8. Rewritten to state the one-integration-branch model
  unambiguously.
- **`docs/TESTING.md` §8's hermeticity citation now resolves.** It cited "§2 —
  mocks, no live services" for a rule §2 never stated (its integration row
  said "Real seams", readable as a real database). §2 now states the rule
  directly.

### Changed

- **Deduplicated normative text that had already drifted once.** The open-PR
  policy existed verbatim in `docs/WORKFLOW.md` §8, `CLAUDE.md`, `work.md`,
  and README — even though §8 already declared itself normative and
  superseding. All four now point at §8 with a one-line summary instead of
  a copy. `docs/WORKFLOW.md`'s roster table dropped its `Model` column
  (agent frontmatter is the source of truth; README's overview table is
  kept, sourced from the same frontmatter). `docs/TICKETS.md` §9 gained a
  canonical ticketing-mode-resolution ladder; `/feature`, `/bug`, `/epic`,
  and `/spike` each shrank their ~16-line "Mode check" step to a pointer at
  it plus their one command-specific fallback.
- **`CLAUDE.md`'s "read first" obligation is no longer uniformly
  every-session.** `PROJECT.md` still is; `docs/ENGINEERING.md` is now "before
  the first task that changes code" — the Guardrails section already covers
  the always-on rules, so a one-line question doesn't need the full charter
  loaded first.

### Added

- **`install.sh` now delegates to `update.sh` on an existing install** instead
  of silently clobbering customized agents/commands/scripts (it used to
  `cp -R` unconditionally, overwriting same-named files with no warning — an
  easy mistake since both scripts take the same argument). A manifest-less
  `.claude/agents` (a pre-manifest or clone-based install) aborts with a
  pointer at `update.sh`'s conservative legacy mode instead of guessing.
- **Both installers seed a managed `.gitignore` block** for Claude Code /
  crew machine-local state (`settings.local.json`, `.claude/projects/`,
  worktrees, agent memory, vendored-skill `__pycache__`) — idempotent, and
  now also backfilled by `update.sh` for installs that predate this. A real
  consuming repo had leaked a Claude Code auto-memory file into git before
  this existed.
- **Force-push guard in the pre-PR hook.** `.claude/scripts/pre-pr-gate.sh` now
  unconditionally blocks a bare `git push --force`/`-f` on any Bash call — not
  just PR creation, since this hook fires on every one — citing CLAUDE.md
  guardrail 2. `--force-with-lease` stays allowed. `.claude/settings.json`'s
  deny rules were deliberately left as exact-match strings rather than given
  `:*` wildcards: those match as string prefixes, so `git push --force:*`
  would also deny the sanctioned `--force-with-lease` and `rm -rf /:*` would
  deny routine `rm -rf /tmp/...` cleanup — the hook is the real enforcement
  point here.

### Fixed

- **Pre-PR gate no longer false-positives on the phrase "gh pr create"
  appearing in a quoted string** (e.g. `git commit -m "before gh pr create"`)
  — it now requires an actual invocation (a command segment whose first word
  is literally `gh`), splitting the command on `&&`/`||`/`;`/`|` first.
  Demonstrated live during development: a diagnostic command that merely
  mentioned the phrase was previously blocked.
- **Pre-PR gate fails open (with a warning) instead of misparsing the raw
  hook JSON as the command** when neither `jq` nor `python3` is available —
  previously this silently mis-triggered both checks on worktree PRs.
- **`install.sh`/`update.sh` no longer die mid-copy** on systems with
  `sha256sum` but no `shasum` (most non-macOS Linux) — both now check upfront
  (before any file is copied) and use whichever is available.
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
