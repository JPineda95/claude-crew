---
description: "Interview, break an initiative into child Stories, and file the Epic + children in the backlog."
argument-hint: <the initiative>
---

File an Epic and its child Stories on the board, per `docs/TICKETS.md`. This
command creates cards only — it never implements, never branches, never moves a
card past Backlog.

**Initiative:** $ARGUMENTS

Proceed:

1. **Mode check** — read `PROJECT.md` §12 first.
   - **`Ticketing: notion`** and the Notion MCP tools respond (match tools by
     name *suffix*, never a hardcoded prefix — `docs/TICKETS.md` §9) → run the
     flow below.
   - **`Ticketing: none`** (or §12 deleted) → silently run the classic
     fallback: suggest `/plan` (architect design brief + execution plan, no
     cards) and offer to run it now on $ARGUMENTS. No mention of ticketing or
     boards — ever.
   - **§12 absent / never configured** → explain once, in ≤3 lines: this
     command files an Epic + child Stories on a Notion board; `/board` sets
     the board up; `Ticketing: none` in `PROJECT.md` §12 silences this notice.
     Offer to proceed with the classic fallback right now, and suggest
     recording the choice. Never repeat this once `none` is recorded.
   - **§12 says `notion` but the tools are missing or unreachable** → say so
     briefly, point to `docs/TOOLING.md`, and offer the classic fallback for
     this run. A Notion failure never blocks the work (`docs/TICKETS.md` §9).
2. **Interview the initiative** — draft-first: scan the repo and `PROJECT.md`,
   pre-fill everything you can, and present detected values as defaults to
   confirm. Batch 3–6 questions (AskUserQuestion tool when available), covering:
   the narrative (what and why), the definition of done for the whole epic,
   constraints, and a rough Priority. Propose, don't quiz.
3. **Breakdown** — spawn `architect` to propose the child-story decomposition:
   each child a one-PR-sized Story with draft Given/When/Then acceptance
   criteria meeting the Definition of Ready (`docs/TICKETS.md` §4), plus an
   intended order. Iterate with the user until the list is right — merge,
   split, or drop children as directed. The user may decline the breakdown
   entirely and park the epic card alone.
4. **Confirm** — show the full Epic card (body per `docs/TICKETS.md` §2.2:
   `## Description`, `## Definition of done`, `## Children` as an ordered
   list) and every child Story card. Get an explicit yes before creating
   anything.
5. **Create** — two steps, because the epic's page id must exist before the
   relation can point at it:
   1. Create the Epic with the Notion MCP page-creation tool as a page in the
      tickets data source (id from `PROJECT.md` §12) — `Category: Epic`,
      `Status: Backlog`, the agreed Priority. Notion assigns the Ticket ID.
   2. Batch-create all children in **one** call with the batch page-creation
      tool — `Category: Story`, `Status: Backlog`, each child's `Epic`
      relation set to the epic's page. If the call returns an async task,
      poll it until done before reporting ids (`docs/TICKETS.md` §9 rule 4).
      If setting the relation at create time fails, fall back to two
      known-good steps: create the children, then set each `Epic` relation
      via the page-update tool.

   Every write: try once, retry once, move on — on persistent failure, output
   the remaining cards as a markdown table for the human to paste
   (`docs/TICKETS.md` §9).
6. **Report & stop** — report the Epic's Ticket ID, each child's Ticket ID,
   and all card URLs. Restate: **Epics are never workable** — `/work` runs the
   children, and the epic's progress is their rollup (`docs/TICKETS.md` §2).
   Remind the user that a human triages the children Backlog → Dev Ready, and
   then `/work` picks them up. Then STOP — no implementation, no branches, no
   status moves.
