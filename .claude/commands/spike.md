---
description: "Interview and file a Spike ticket — a timeboxed question to answer before committing to build."
argument-hint: "<what to investigate>"
---

File a **Spike** ticket — a timeboxed investigation that ends in answers, not
features — per `docs/TICKETS.md`. Topic: $ARGUMENTS

1. **Mode check.** Resolve ticketing mode per `docs/TICKETS.md` §9. This
   command's classic fallback: `/plan` — an architect investigation without a
   card — on $ARGUMENTS.

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
