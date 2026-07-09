---
description: "Interview the user and generate a complete PROJECT.md from PROJECT.template.md — every section filled, nothing invented."
argument-hint: "[thorough for the full section-by-section interview | optional: anything you already want to tell the crew about the project]"
---

Create (or update) `PROJECT.md` for this repository until **every section of
`PROJECT.template.md` is filled**. If `$ARGUMENTS` starts with the word
`thorough`, run in **thorough mode** (Step 2, section-by-section) and treat
the remainder as context. Otherwise run in **express mode** (the default —
Step 2, one message) and treat all of `$ARGUMENTS` as context the user
already provided.

## Ground rules (follow all of them)

1. **Scan before you ask.** Never ask the user something the repo can answer.
2. **Ask about everything else.** Every template section must end up filled —
   with real content, an explicit `none`, or an explicit `TODO(owner)` the user
   chose. Never leave template italics or silently skip a section.
3. **Propose, don't quiz.** For everything you detected, present it as a default
   to confirm ("I detected X — correct?") so the user mostly says yes/no.
4. **Default to express: one message, ≤2 turns.** See Step 2. Batch only what
   the scan genuinely can't answer; state confident detections as fact rather
   than asking. Fall back to `/onboard thorough` (3–6 questions per section,
   via AskUserQuestion when available, one section per turn) for a messy or
   greenfield repo where batching would guess too much.
5. **Never invent.** Commands come from the repo or the user — not from memory
   of similar projects. Unknown stays `TODO`, not a guess.
6. **Env var names only, never values.** If the user pastes a secret, don't
   write it; record the name and where the value lives.
7. **Keep it short and true.** PROJECT.md is context loaded every session —
   compress prose, cut anything the code already makes obvious, delete the
   template's italic guidance.

## Step 1 — Scan the repo (silently, before any question)

Detect and note, with evidence:
- **Stack**: language/runtime from manifests and lockfiles; frameworks, test
  runner, linter/formatter, CI from config files (charter §2 in
  `docs/ENGINEERING.md`).
- **Commands**: install/dev/test/lint/build/migrations from the scripts section,
  `Makefile`/`Justfile`/`Taskfile`, CI workflows. Candidate validation gate.
- **Testing**: does a suite exist at all? Runner and e2e tool from the deps and
  config; candidate **core flows** from routes/nav/critical paths.
- **Git**: default/integration branch, existing branch-name patterns from
  `git log`/`git branch`.
- **Architecture**: top-level layout, routing model, where data access lives.
- **Data & compliance signals**: datastore, auth provider, third-party SDKs/
  pixels/email/analytics/payments in the dependency list, personal-data-looking
  columns in the schema, existing policy pages, UI locale from the strings.
- **Tooling**: `.mcp.json`, installed plugins, existing `.claude/` config —
  including whether a Notion MCP is connected and whether `PROJECT.md` §12
  already records a ticket board.
- An existing `PROJECT.md` **with real content** → switch to **update mode**:
  diff it against reality and the template, and only interview for what's
  missing, stale, or new.
- An existing `PROJECT.md` that's still the **unfilled template** (guidance
  italics throughout, no real values — e.g. README Option A's
  `cp PROJECT.template.md PROJECT.md`) → treat this as a **first run**
  (express mode below), not an update. Overwrite it; there's nothing to diff
  against.

## Step 2 — Interview

**Express mode (default).** After Step 1's silent scan, in a single message:

1. Present the **complete pre-filled `PROJECT.md` draft** — every section
   written as final content using your detected values (not a question list).
2. Immediately follow it with **one batched question set** (AskUserQuestion
   tool when available) covering only what the scan genuinely can't answer:
   - **Project purpose & #1 priority** — one paragraph: what it does, for
     whom, current stage, and what matters most right now (template §1).
   - **Core flows** — confirm or edit your candidate list of 5–10 journeys
     (template §4).
   - **Ship mode** — `pr` (default) or `ask` (template §5).
   - **Markets / compliance basics** — jurisdictions and personal-data
     categories, only if plausibly relevant; skip the question entirely for a
     project with no user data (template §10).
   - **Validation gate** — confirm the command you detected is safe to run
     unprompted, or correct it (template §3).

   Everything else in the draft is either your detected value stated as fact
   (no question) or an explicit `TODO(owner)` where genuinely unknown — never
   a silent guess. Cover the same ground as the thorough-mode list below,
   just compressed into this one message instead of walked turn by turn.
3. Fold the user's answers into the draft, then proceed straight to Step 3
   for the final review-and-write pass (which shows the completed draft for
   a last look before writing). Two turns total: the draft-plus-questions
   message, then Step 3's confirmation.

**Thorough mode (`/onboard thorough`)** — walk the template section by
section instead, for a messy or greenfield repo where batching would guess
too much. Per section, confirm detections + ask what can't be detected; batch
3–6 questions per section (AskUserQuestion tool when available); one section
per turn:

1. **What this project is** — one paragraph: what it does, for whom, current
   stage (prototype/MVP/production), and the current #1 priority.
2. **Stack** — confirm detected language/framework/datastore/styling/auth/
   hosting; ask for key third-party services (payments, email, analytics) and
   the **primary UI locale** (copy gets written natively in it).
3. **Commands** — confirm each detected command by name; ask which combination
   is the **validation gate** and whether it's safe to run unprompted.
4. **Testing** — confirm the detected runner and e2e tool (default e2e for web
   UIs: Cypress); elicit the **core flows** — the 5–10 journeys that must never
   break — proposing candidates from the routes you scanned; TDD policy
   (default: failing tests first for anything with logic); which commands
   become the validation gate and e2e smoke, wired per `docs/TESTING.md` §5.
   If the project has no tests, say so plainly and plan `/tests` as the first
   work item.
5. **Git & integration** — integration branch (default `dev` — NEVER the
   production/default branch; if the repo only has `main`, offer to create
   `dev` off it now, or record that the crew will on its first run), branch
   naming, **Ship mode** (default `pr`: each finished feature is committed on
   its own branch, pushed, and opened as a PR the human merges; `ask` =
   prepare commits and wait), autonomous deploy yes/no (default no).
6. **Conventions & non-negotiables** — rules a new engineer gets told on day
   one: single-source-of-truth modules, forbidden patterns, style rules beyond
   the formatter. Offer detected candidates (e.g. "all TZ logic goes through
   X — should I record that as a rule?").
7. **Architecture notes** — confirm your detected map (routing, data flow,
   where the important code lives); ask what a newcomer always gets wrong.
8. **Tooling installed** — confirm detected MCP servers/plugins; ask if any
   others exist that agents may call.
9. **Environment** — required env var **names**, where secrets live, which
   git-ignored files a fresh worktree needs (`.worktreeinclude`).
10. **Data & compliance** — markets/user jurisdictions, personal-data categories
    collected, third parties receiving user data, where legal docs live, minors/
    special-category constraints. Offer what the scan found as the starting list.
11. **Out of scope / known constraints** — what not to touch, decisions already
    made, deliberate tech debt, deadlines/budget.
12. **Ticketing** — does the team want the optional Notion kanban
    (`docs/TICKETS.md`)? Default `none`. If yes, record `Ticketing: none` for
    now anyway and point at `/board` — onboarding never creates Notion
    artifacts; `/board` does, and it fills in the §12 identifiers itself.

If an answer contradicts the code (e.g. user names a command that doesn't
exist), say so and resolve it now — don't record either version silently.

## Step 3 — Draft, review, write

1. Assemble the full `PROJECT.md` following the template's structure, guidance
   italics removed, every section filled (content, `none`, or agreed `TODO`).
2. Show the complete draft and ask for corrections.
3. On approval, write `PROJECT.md` to the repo root. Do **not** commit — remind
   the user it's git-ignored by the boilerplate's `.gitignore` by default, and
   ask whether they want that (shared teams usually commit it; solo repos with
   private details often don't).
4. Write the confirmed validation gate into `.claude/crew.env` — the file the
   gate hooks actually read (`.claude/scripts/validate.sh`,
   `.claude/scripts/pre-pr-gate.sh`). If `.claude/crew.env` already exists
   (install.sh/update.sh seed it), edit its `CLAUDE_VALIDATE_CMD` line in
   place; if it's somehow missing, create it with this exact content — this
   repo has no `templates/` directory to copy from, so write it verbatim,
   substituting the confirmed commands for the empty defaults:
   ```bash
   # claude-crew project knobs — commit this file with your repo.
   # install.sh (and update.sh) seed it once if absent; NEITHER ever manages it
   # again afterward (like PROJECT.md) — your edits always survive a sync.
   #
   # ':=' means: if a value is already exported in the calling shell/session
   # environment, that value wins and this default is never applied.
   #
   # This is the SINGLE source of truth the crew's hooks read
   # (.claude/scripts/validate.sh, .claude/scripts/pre-pr-gate.sh) — set your
   # real values here, or run /onboard to have it done for you.

   : "${CLAUDE_VALIDATE_CMD:=<confirmed validation gate command>}"
   : "${CLAUDE_E2E_SMOKE_CMD:=<confirmed e2e smoke command, or leave empty>}"
   : "${CLAUDE_INTEGRATION_BRANCH:=<PROJECT.md §5 integration branch>}"
   : "${BLOCK_ON_FAILURE:=}"           # 1 = Stop-hook gate blocks the agent on red

   export CLAUDE_VALIDATE_CMD CLAUDE_E2E_SMOKE_CMD CLAUDE_INTEGRATION_BRANCH BLOCK_ON_FAILURE
   ```
   Leave `BLOCK_ON_FAILURE` empty by default (non-blocking until the user opts
   in) unless they ask for it on.
5. Close with the two-line status: which sections carry `TODO`s, and the
   recommended next step (usually installing tooling from `docs/TOOLING.md`;
   then `/tests` if the project has no suite yet — the pre-PR hook blocks PRs
   until the gate exists; then `/board` if the team wants the kanban; then
   `/work` — or `/feature` to file the first ticket).
