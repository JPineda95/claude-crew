---
description: Interview and file a Bug ticket — repro steps, expected vs actual, and regression acceptance criteria.
argument-hint: "<what's broken>"
---

File a Bug ticket on the board per `docs/TICKETS.md`. This command produces a
card, not a fix. **Bug:** $ARGUMENTS

Phases:

1. **Mode check** — read `PROJECT.md` §12 before anything else
   (`docs/TICKETS.md` §9):
   - `Ticketing: notion` **and** the Notion MCP tools respond (match tools by
     name suffix — the server prefix varies per install; never hardcode it) →
     run phases 2–5.
   - `Ticketing: none` (or §12 deleted) → silently switch to the classic
     fallback, with zero mention of ticketing or Notion in your output: offer
     to fix it right now via the ticketless `/work` lifecycle on $ARGUMENTS,
     then stop here.
   - §12 absent (never configured) → explain once, in ≤3 lines: `/bug` now
     files a Bug card on the project board; `/board` sets that board up;
     `Ticketing: none` in `PROJECT.md` §12 silences this note. Offer to fix
     the bug right now via the ticketless `/work` lifecycle instead, and
     suggest recording the choice in §12 so this explanation never repeats.
   - §12 says `notion` but the tools are missing or unreachable → say so
     briefly, point to `docs/TOOLING.md`, and offer the `/work` fallback for
     this run.
2. **Evidence pass, then draft.** Before asking the user anything: scan the
   code, recent commits (`git log`), and any error text in $ARGUMENTS to
   pre-fill draft repro steps, the suspect area (→ Technical Details), and
   severity signals. Then interview only for what's missing — batch 3–6
   questions (use the AskUserQuestion tool when available), presenting
   detected values as defaults to confirm:
   - **Repro steps** — numbered, from a clean state.
   - **Expected vs Actual** — one line each, observable.
   - **Environment** — only if it plausibly matters (browser/OS/data state).
   - **Priority** — framed as user impact ("who is blocked, how badly?"),
     not severity jargon.
   - **Regression acceptance criteria** — the checks that prove the bug is
     gone. These drive `qa-engineer`'s failing regression test when `/work`
     picks the ticket up (`docs/TESTING.md` §3), so each one must be
     externally observable and testable (Definition of Ready,
     `docs/TICKETS.md` §4).
3. **Confirm.** Show the complete card — Name, Category `Bug`, Priority, and
   the body per `docs/TICKETS.md` §2.2's Bug variation: `## Repro steps`,
   `## Expected`, `## Actual`, `## Acceptance Criteria`,
   `## Technical Details`, `## Work Log`. Every section filled or an explicit
   `none`. Iterate until the user approves — the card must be complete enough
   that `/work` can implement the fix later without re-asking.
4. **Create.** With the Notion MCP page-creation tool, add the card to the
   tickets data source (id from `PROJECT.md` §12): properties per
   `docs/TICKETS.md` §2.1 — `Category: Bug`, `Status: Backlog`, `Priority` as
   agreed. Never set `Ticket ID` — Notion assigns it. On failure: try once,
   retry once, then print the finished card as markdown for the human to
   paste — a Notion failure never blocks (`docs/TICKETS.md` §9).
5. **Report & stop.** Give the Ticket ID and card URL. Remind: a human
   triages Backlog → Dev Ready, then `/work <id>` runs the fix. This command
   never fixes the bug, never branches, and never moves the card past
   Backlog.
