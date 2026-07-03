---
description: Interview and file a Spike ticket — a timeboxed question to answer before committing to build.
argument-hint: "<what to investigate>"
---

File a **Spike** ticket — a timeboxed investigation that ends in answers, not
features — per `docs/TICKETS.md`. Topic: $ARGUMENTS

1. **Mode check.** Read `PROJECT.md` §12 before anything else:
   - **`Ticketing: notion`** and the Notion MCP tools respond (match tools by
     name suffix per `docs/TICKETS.md` §9 — never by hardcoded prefix) →
     continue with step 2.
   - **`Ticketing: none`** (or §12 deleted) → silently run the classic
     fallback: suggest `/plan` — an architect investigation without a card —
     and offer to run it now on $ARGUMENTS. Zero Notion mentions.
   - **§12 absent** (never configured) → explain once, in ≤3 lines: `/spike`
     files a Spike card on a Notion board; `/board` sets the board up;
     `Ticketing: none` in `PROJECT.md` §12 silences this. Offer the classic
     fallback right now, and suggest recording the choice so this note never
     repeats.
   - **§12 says `notion` but the tools are missing/unreachable** → say so
     briefly, point to `docs/TOOLING.md`, and offer the classic fallback for
     this run.

2. **Draft first.** From $ARGUMENTS and a quick repo scan, pre-fill everything
   you can before asking anything:
   - **Question(s)** — decision-shaped ("which X should we use for Y", "is Z
     feasible under constraint W"), never open-ended research.
   - **What decision** each answer unblocks.
   - **Timebox** — propose one (default: half a day).
   - **Expected output** — recommendation on the card / comparison table /
     throwaway prototype branch.

   Interview for the rest: present detected values as defaults, batch 3–6
   questions max (use the AskUserQuestion tool when available),
   propose-then-confirm. The card must meet the Definition of Ready
   (`docs/TICKETS.md` §4) — complete enough that `/work` can execute it later
   without re-asking.

3. **Confirm.** Show the full card before creating: title, Priority, and the
   body per the Spike variation of `docs/TICKETS.md` §2.2 — `## Description`
   with the timebox line, `## Question(s)`, `## Expected output`,
   `## Technical Details`, an empty `## Findings`, `## Work Log`. Set the
   expectation explicitly: when `/work` executes a Spike it ends in findings
   on the card and normally **no PR** (`docs/TICKETS.md` §5.3).

4. **Create.** On approval, create one page in the tickets database (data
   source id from `PROJECT.md` §12) via the Notion MCP page-creation tool,
   properties per `docs/TICKETS.md` §2.1: `Category: Spike`,
   `Status: Backlog`, `Priority` as agreed. Notion auto-assigns the Ticket ID
   — never set it. Try once, retry once; on failure output the card as
   markdown for the human to paste — a Notion failure never blocks
   (`docs/TICKETS.md` §9).

5. **Report & stop.** Report the Ticket ID and card URL. Remind the user that
   a human triages Backlog → Dev Ready (`docs/TICKETS.md` §1), and `/work <id>`
   runs the spike from there. Then stop — `/spike` never investigates, never
   implements, never branches, and never moves a card past Backlog.
