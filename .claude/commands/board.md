---
description: Create (or check and repair) the project's Notion section — a summary page plus the kanban ticket board. Optional; the crew runs fine without it.
argument-hint: "[board name — defaults to the repo name]"
---

Create — or, if one exists, check and repair — this project's Notion section
per `docs/TICKETS.md` §3. Board name (optional): $ARGUMENTS

Ground rules:

- Notion MCP tool names vary per install — match them by name *suffix* and
  call them by function (the search tool, the fetch tool, the database-create
  tool…), never by a hardcoded prefixed name (`docs/TICKETS.md` §9).
- The board is optional and a mirror, not a lock. This command sets it up;
  no engineering step ever blocks on it (`docs/TICKETS.md` §9).

Phases:

1. **Preflight.** Verify the Notion MCP tools respond — attempt a real call
   (the search tool is cheapest). Missing or unreachable ⇒ stop and point to
   the Notion row in `docs/TOOLING.md`. Then verify `PROJECT.md` exists with
   §1 filled — the section page is built from it. Missing or empty ⇒ stop:
   run `/onboard` first.

2. **Existing board ⇒ status mode.** If `PROJECT.md` §12 already records a
   data source id, fetch it. It resolves ⇒ **never create a second board**
   (`docs/TICKETS.md` §10) — run status mode instead, then stop:
   - Report card counts per Status (read ladder, `docs/TICKETS.md` §6).
   - Run the merge sweep (`docs/TICKETS.md` §8).
   - Verify the board view and the summary page content still exist; if
     either is gone, offer to repair it via the Notion tools.
   - If `PROJECT.md` §1/§2/§4/§5 changed materially since creation, offer to
     refresh the summary.
   - Verify the seven `Status` options still match `docs/TICKETS.md` §1; on a
     mismatch, warn per §2.1 — never create options implicitly.

   The stored id does NOT resolve ⇒ one search by board name. Found ⇒ offer
   to fix §12 with the real ids. Not found ⇒ ask: re-create the board, or
   stay ticketless (`Ticketing: none`)?

3. **Interview — one batch.** Draft first: detect everything, present it as
   defaults, confirm in a single round (use the AskUserQuestion tool when
   available):
   - **Board name:** $ARGUMENTS if given, else the repo directory name.
   - **Location:** search Notion for plausible parent pages and propose the
     best match; the fallback is workspace-level private — tell the user they
     can move the section later (ids stay stable).
   - **Ticket prefix:** derive per `docs/TICKETS.md` §3; the user may
     override; warn that it is **immutable after creation**.

4. **Create.** Follow the recipe in `docs/TICKETS.md` §3, in this order:
   1. The **section page** — `PROJECT.md` §1 verbatim, §2 in one line, §4 as
      the core-flow list, §5 branches, then the "how this board works" legend
      from `docs/TICKETS.md` §1. **Never §6–§11.**
   2. The **tickets database** inside it, with the §3 DDL (prefix
      substituted).
   3. The **single self-relation ALTER** (`Epic` ⇄ `Children`).
   4. The **board view** grouped by `Status`.

   End by telling the user the two one-time manual touches: drag the columns
   into pipeline order if needed, and hide the empty "No Status" column. Then
   probe the SQL query tool once against the new data source (informational
   only — the read ladder self-discovers per run, `docs/TICKETS.md` §6) and
   report which rung this workspace supports: "SQL queries available" or
   "plan-gated — the crew will use scoped search + fetch".

5. **Seed cards — blank repos only.** Decide whether the repo already has
   product code: list tracked + untracked files and match them against the
   code-extension regex `.claude/scripts/pre-pr-gate.sh` uses (read `CODE_RE`
   from the script — don't restate it), ignoring `.claude/`, `docs/`,
   `scripts/`, and root config files. **Always confirm the verdict with the
   user.**
   - Existing code ⇒ infrastructure only: create zero cards and say so —
     tickets for a live codebase come from `/feature`, `/bug`, `/spike`,
     `/epic`.
   - Blank ⇒ propose an initial Backlog derived from `PROJECT.md`:
     - one card per §4 core flow — a flow implying several stories becomes an
       **Epic + children**, otherwise one **Story**; seed acceptance criteria
       from the flow itself;
     - a scaffold/CI Story (validation gate green on an empty suite);
     - a test-harness Story (ties to `/tests`);
     - a legal-pages Story if §10 declares markets or personal data.

     Present the proposal as a table — Category / Title / AC summary / Epic —
     for the user to edit and approve, then batch-create per
     `docs/TICKETS.md` §9 rule 4 (poll async tasks before reporting ids).
     Every card lands in **Backlog** — the human triage gate applies to
     generated cards too. Target ~8–20 cards; fewer is fine.

6. **Record & report.** Write `PROJECT.md` §12 with every field: `Ticketing:
   notion`, section page URL, tickets database URL, data source id, ticket
   prefix, status property, max parallel tickets. If the project's
   `PROJECT.md` predates §12, append the section from `PROJECT.template.md`
   first. Then report: page URL, database URL, prefix, cards created. Close
   with three reminders:
   1. Allowlist your Notion MCP server's tools in
      `.claude/settings.local.json` before running batch `/work`
      (`docs/TICKETS.md` §9 rule 5).
   2. **Backlog → Dev Ready is yours** — the crew never crosses the triage
      gate (`docs/TICKETS.md` §1).
   3. Then `/work`.
