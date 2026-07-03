---
description: Interview the user and generate a complete PROJECT.md from PROJECT.template.md — every section filled, nothing invented.
argument-hint: "[optional: anything you already want to tell the crew about the project]"
---

Create (or update) `PROJECT.md` for this repository by interviewing the user,
section by section, until **every section of `PROJECT.template.md` is filled**.
Context the user already provided: $ARGUMENTS

## Ground rules (follow all of them)

1. **Scan before you ask.** Never ask the user something the repo can answer.
2. **Ask about everything else.** Every template section must end up filled —
   with real content, an explicit `none`, or an explicit `TODO(owner)` the user
   chose. Never leave template italics or silently skip a section.
3. **Propose, don't quiz.** For everything you detected, present it as a default
   to confirm ("I detected X — correct?") so the user mostly says yes/no.
4. **Batch questions per section** (3–6 at a time), in template order. Use the
   AskUserQuestion tool when available (with your detected value as the
   recommended option); otherwise a numbered list. One section per turn — don't
   dump 40 questions at once.
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
- An existing `PROJECT.md` → switch to **update mode**: diff it against reality
  and the template, and only interview for what's missing, stale, or new.

## Step 2 — Interview, section by section

Walk the template in order. Per section, confirm detections + ask what can't be
detected:

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
5. **Git & integration** — integration branch, branch naming, **Ship mode**
   (default `pr`: each finished feature is committed on its own branch, pushed,
   and opened as a PR the human merges; `ask` = prepare commits and wait),
   autonomous deploy yes/no (default no).
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
4. Close with the two-line status: which sections carry `TODO`s, and the
   recommended next step (usually installing tooling from `docs/TOOLING.md`;
   then `/tests` if the project has no suite yet — the pre-PR hook blocks PRs
   until the gate exists; then `/board` if the team wants the kanban; then
   `/work` — or `/feature` to file the first ticket).
