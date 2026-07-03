---
description: "Interview and file a Story ticket in the backlog. (v2: the build lifecycle moved to /work — `/work <description>` is the classic ticketless behavior.)"
argument-hint: <what to build>
---

File a **Story** card on the project board per `docs/TICKETS.md`. This command
creates the ticket and stops — implementation happens later, via `/work <id>`,
after a human triages the card to Dev Ready.

**Feature:** $ARGUMENTS

Proceed:

1. **Mode check** — read `PROJECT.md` §12 before anything else:
   - **`Ticketing: notion` and the Notion MCP tools respond** (match tools by
     name *suffix* per `docs/TICKETS.md` §9 — never a hardcoded server prefix)
     → run the ticket flow below.
   - **`Ticketing: none`** (or §12 deleted) → silently run the classic
     fallback: state "running the classic lifecycle — see `/work`", then follow
     `.claude/commands/work.md`'s ticketless mode as if invoked as
     `/work $ARGUMENTS`. Zero Notion mentions, ever.
   - **§12 absent / never configured** → one short explanation (≤3 lines):
     `/feature` now files a ticket; `/board` sets up the board; recording
     `Ticketing: none` in `PROJECT.md` §12 silences this. Offer to run the
     classic fallback right now, and suggest recording the choice. Once `none`
     is recorded, never mention this again.
   - **§12 says `notion` but the tools are missing or unreachable** → say so
     briefly, point to `docs/TOOLING.md`, and offer the classic fallback for
     this run.
2. **Draft first** — seed the card from $ARGUMENTS. Scan the repo and
   `PROJECT.md` and pre-fill everything you can: likely affected areas/files,
   related core flows (`PROJECT.md` §4), a suggested Priority. Then interview
   the user only for what's missing — the bar is the Definition of Ready
   (`docs/TICKETS.md` §4): description (what and why), acceptance criteria as
   testable Given/When/Then, technical details, out of scope, epic link (if
   the user names one, find it on the board by id or title via the read
   ladder, `docs/TICKETS.md` §6), Priority. Present detected values as
   defaults to confirm; batch 3–6 questions (use the AskUserQuestion tool when
   available). The goal: a card so complete `/work` can implement it later
   without re-asking.
3. **Confirm** — show the complete card — title, every body section per
   `docs/TICKETS.md` §2.2, properties — and get a yes or edits before writing
   anything.
4. **Create** — create the page in the board data source (id from `PROJECT.md`
   §12) with the Notion MCP page-creation tool: `Category: Story`,
   `Status: Backlog`, `Priority` as agreed, `Epic` relation if linked. Never
   set `Ticket ID` — Notion assigns it. Body per the `docs/TICKETS.md` §2.2
   template. If the write fails: retry once, then output the finished card as
   markdown for the human to paste — a Notion failure never blocks
   (`docs/TICKETS.md` §9).
5. **Report & stop** — report the Ticket ID and card URL, and remind the user:
   move the card to Dev Ready when you want it built, then run `/work <id>`.
   Then STOP — this command never implements, never creates a branch, and
   never moves a card past Backlog.
