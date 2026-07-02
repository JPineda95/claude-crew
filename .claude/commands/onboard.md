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
- **Git**: default/integration branch, existing branch-name patterns from
  `git log`/`git branch`.
- **Architecture**: top-level layout, routing model, where data access lives.
- **Data & compliance signals**: datastore, auth provider, third-party SDKs/
  pixels/email/analytics/payments in the dependency list, personal-data-looking
  columns in the schema, existing policy pages, UI locale from the strings.
- **Tooling**: `.mcp.json`, installed plugins, existing `.claude/` config.
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
4. **Git & integration** — integration branch, branch naming, **autonomous
   commits yes/no** (default no), autonomous deploy yes/no (default no).
5. **Conventions & non-negotiables** — rules a new engineer gets told on day
   one: single-source-of-truth modules, forbidden patterns, testing policy
   (TDD?), style rules beyond the formatter. Offer detected candidates
   (e.g. "all TZ logic goes through X — should I record that as a rule?").
6. **Architecture notes** — confirm your detected map (routing, data flow,
   where the important code lives); ask what a newcomer always gets wrong.
7. **Tooling installed** — confirm detected MCP servers/plugins; ask if any
   others exist that agents may call.
8. **Environment** — required env var **names**, where secrets live, which
   git-ignored files a fresh worktree needs (`.worktreeinclude`).
9. **Data & compliance** — markets/user jurisdictions, personal-data categories
   collected, third parties receiving user data, where legal docs live, minors/
   special-category constraints. Offer what the scan found as the starting list.
10. **Out of scope / known constraints** — what not to touch, decisions already
    made, deliberate tech debt, deadlines/budget.

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
   recommended next step (usually installing tooling from `docs/TOOLING.md`,
   then `/feature`).
