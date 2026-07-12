# Tickets & the Board — Optional Kanban Charter

> How the crew works from a Notion kanban board: card anatomy, statuses, who
> moves what, and how every command degrades when Notion isn't there. Normative:
> **MUST / SHOULD / MUST NOT** carry their RFC-2119 meanings. Companion to
> [WORKFLOW.md](./WORKFLOW.md) (lifecycle & PR spec) and
> [WORKTREES.md](./WORKTREES.md) (parallel execution).
>
> **The board is optional.** Everything in this doc applies only when
> `PROJECT.md` §12 declares `Ticketing: notion`. Without it the crew runs
> exactly as before — `/work <description>` is the full lifecycle, and the
> ticket commands offer setup once, then stay out of the way.
>
> **The board is a mirror, not a lock.** Git and GitHub are the source of truth
> for code state; the board is a best-effort reflection of it. A Notion failure
> MUST NEVER block an engineering step (§9).

## 1. Statuses & who moves what

The board has exactly these seven statuses, in pipeline order:

| Status | Card enters it when | Moved in by |
|---|---|---|
| **Backlog** | Card is created (`/feature`, `/bug`, `/spike`, `/epic`, or `/board` seeding) | Crew |
| **Dev Ready** | A human decides it's next — **the triage gate** | **Human only** |
| **In Progress** | `/work` claims the ticket and starts the lifecycle | Crew |
| **Code Review** | The ticket's PR is opened | Crew |
| **Dev Complete** | The sweep (§8) sees the PR merged — or `/work` finishes a Spike (§5.3) | Crew |
| **In QA** | `/deploy` promotes a release containing the ticket's merge | Crew |
| **Done** | A human verified it | **Human only** |

Rules:

- **Two gates stay human forever:** Backlog → Dev Ready and In QA → Done. The
  crew MUST NOT cross them in either direction.
- **Crew writes are forward-only.** The crew never moves a card backward. If a
  human moved a card backward mid-run, the crew stops work on that ticket and
  reports — it MUST NOT fight the human (§7).
- **Check before write:** every transition re-fetches the card and verifies it
  is in the expected source status; if not, skip the write and report.
- **No production pipeline?** If `PROJECT.md` §5 has no promotion step (or the
  project never runs `/deploy`), the human moves Dev Complete → Done directly;
  In QA is optional.

## 2. Categories & card anatomy

Four categories: **Epic**, **Story**, **Bug**, **Spike**.

- **Epics are never workable.** They group child Stories via the `Epic` ⇄
  `Children` relation. `/work` MUST refuse an Epic id and list its Dev Ready
  children instead. Epic progress is the rollup of its children.
- **Stories and Bugs** ship through the normal lifecycle and end in a PR.
- **Spikes** answer a question inside a timebox and normally end in findings on
  the card, not a PR (§5.3).

### 2.1 Properties (the database schema)

| Property | Type | Written by |
|---|---|---|
| `Name` | title | Ticket commands |
| `Ticket ID` | unique id, e.g. `KANI-12` | **Notion auto-assigns — the crew never sets ids** |
| `Category` | select: `Epic` / `Story` / `Bug` / `Spike` | Ticket commands |
| `Status` | select: the seven statuses of §1 | Per §1 |
| `Priority` | select: `High` / `Medium` / `Low` | Ticket commands (batch `/work` fills waves in Priority order) |
| `PR` | url | `/work` / `/ship` when the PR opens |
| `Branch` | rich text | `/work` when the branch is created |
| `Epic` ⇄ `Children` | self-relation | `/epic`, or `/feature` when linking to an epic |

Naming traps (verified against the live Notion MCP schemas — record in the
board's section page too):

- MUST NOT name properties bare `ID` or `URL` (they collide with Notion's
  built-in page fields and require an awkward `userDefined:` prefix on every
  write). Hence `Ticket ID` and `PR`.
- MUST NOT rename `Status` options or add a second status-like property — the
  crew owns this select. If the seven canonical options aren't all present at
  command start, warn and refuse transitions to missing options; never create
  options implicitly.
- Extra human-added columns (e.g. `Assignee` as a people property for teams)
  are fine — commands write only the properties above and MUST tolerate others.

### 2.2 Card body template

Every card body uses these sections; the interview fills each one or writes
`none`:

```markdown
## Description
<what and why>

## Acceptance Criteria
- [ ] Given <context>, when <action>, then <observable outcome>

## Technical Details
<constraints, pointers into the codebase, API/schema notes>

## Out of scope
<what this ticket deliberately does NOT cover — omit the section when none>

## Work Log
_(appended by crew commands — one line per event)_
```

Per-category variations:

- **Bug** replaces *Acceptance Criteria* with three sections — `## Repro steps`
  (numbered), `## Expected` vs `## Actual` — plus an
  `## Acceptance Criteria` whose criteria state how to prove the bug is gone
  (these drive the TDD regression test).
- **Spike** replaces *Acceptance Criteria* with `## Question(s)` (what decision
  this unblocks), a **Timebox** line in the description (e.g. "timebox: half a
  day"), an `## Expected output` line (document / recommendation / prototype
  branch), and an empty `## Findings` section that `/work` fills.
- **Epic** body is: `## Description` (the narrative), `## Definition of done`
  (when is the epic complete), and `## Children` (an ordered list of the child
  stories — Notion also shows the relation, but the ordered list captures
  intended sequence).

### 2.3 The Work Log

The Work Log is the card's **single audit channel** — status moves, branch, PR,
sweep events — and the crew's **resume breadcrumb** (§7). One line per event:

```
- 2026-07-03 — Dev Ready → In Progress (branch feat/KANI-12-user-auth)
- 2026-07-03 — In Progress → Code Review (PR https://github.com/o/r/pull/41)
- 2026-07-04 — swept: PR merged (a1b2c3d)
- 2026-07-04 — skipped by batch /work: acceptance criteria not testable
```

Do not invent other write channels (comments, extra properties): one mechanism,
appended at the end of the body via the Notion page-update tool.

## 3. Creating the board (the `/board` recipe)

`/board` creates a **section page** (summary of `PROJECT.md` §1/§2/§4/§5 + a
"how this board works" legend — never §6–§11: conventions, env, and compliance
details don't belong in a shared workspace) and, inside it, the **tickets
database**:

```sql
CREATE TABLE (
  "Name"      TITLE,
  "Ticket ID" UNIQUE_ID PREFIX '<PREFIX>',
  "Category"  SELECT('Epic':purple, 'Story':blue, 'Bug':red, 'Spike':yellow),
  "Status"    SELECT('Backlog':gray, 'Dev Ready':blue, 'In Progress':yellow,
                     'Code Review':orange, 'Dev Complete':purple,
                     'In QA':pink, 'Done':green),
  "Priority"  SELECT('High':red, 'Medium':yellow, 'Low':gray),
  "PR"        URL,
  "Branch"    RICH_TEXT
)
```

- **Why a select named `Status`, not Notion's native status type:** the Notion
  API cannot create or modify native-status *options*, so a native status
  column would materialize with the wrong defaults and require hand-editing
  before anything works. A select with the seven options is fully automatable,
  and board views group by it identically. (If a human later hand-converts it
  to a native status property, transitions still work — but `/board` can no
  longer repair the options.)
- **Prefix rule:** uppercase the repo name; multi-word (`-`/`_`) → initials
  (`claude-crew` → `CC`), single word → first 4 characters (`kani` → `KANI`);
  clamp to 2–5 chars; the user may override at creation. **Immutable after
  creation** — Notion fixes the unique-id prefix at the database, and branch
  names, resume searches, and PR titles all key on it.
- **Epic relation is a second step** (the data-source id doesn't exist until
  the database is created). Issue **one** ALTER — the DUAL form auto-creates
  the reverse property:

  ```sql
  ADD COLUMN "Epic" RELATION('<data_source_id>', DUAL 'Children' 'children')
  ```
- **Board view:** grouped by `Status`, showing `Ticket ID`, `Category`,
  `Priority`, `Epic`, `PR`. The DDL lists statuses in pipeline order so columns
  render in order; the view DSL cannot order or hide groups, so `/board` ends
  by telling the human the two possible one-time manual touches: drag columns
  into pipeline order if needed, and hide the empty "No Status" column.

## 4. Definition of Ready

A ticket is **Ready** when all four hold:

1. Acceptance criteria are present.
2. Every criterion is **externally observable and testable** (a failing test
   could be written from it — no "make it better").
3. The scope fits **one PR**.
4. The category is not Epic.

Enforcement:

- **At creation:** the ticket-command interviews (§5) MUST NOT produce a card
  that fails 1–3. That's the point of the interview.
- **`/work <id>` (interactive):** a Dev Ready card that fails the check is
  repaired **inline** — interview the human, write the answers back to the
  card, then proceed. The human is present; use them.
- **`/work` batch mode:** failing cards are **skipped** — a Work Log line
  states exactly what's missing, and the run report lists them. The crew MUST
  NOT move the card backward (that crosses the human triage gate) and MUST NOT
  invent acceptance criteria (that fabricates requirements).

Why this gate exists: the card's acceptance criteria become `qa-engineer`'s
failing tests — **one red test per criterion** (`docs/TESTING.md` §3). Vague
criteria produce tests that assert nothing, and the pre-PR gate goes green with
false confidence.

## 5. Working a ticket

### 5.1 Identity & git conventions

- The **ticket id is the key; the slug is cosmetic.** Branch:
  `<type>/<ID>-<slug>` (`feat/KANI-12-user-invites`; `fix/` for Bugs). Before
  creating a branch, search by id — `git branch --list "*<ID>-*"` and
  `git ls-remote --heads origin "*<ID>-*"` — any hit means **resume that
  branch**, whatever its slug.
- **PR title** stays Conventional-Commit shaped with the id as a suffix:
  `feat: add user invites (KANI-12)`. MUST NOT `#`-prefix a ticket id anywhere
  (GitHub autolinks `#12` to the wrong issue).
- **PR body** carries a `Ticket:` line with the card URL, and the manual
  testing notes required by `WORKFLOW.md` §8 — **generated from the acceptance
  criteria, never a raw card dump** (cards may hold internal details; PRs can
  be public).
- **Commit trailer:** `Refs: KANI-12` (bare id — `docs/COMMITS.md` §4).

### 5.2 Status writes along the lifecycle

| Moment | Board write |
|---|---|
| Ticket claimed | `Status: In Progress` + Work Log line with the branch; `Branch` property set |
| PR opened | `Status: Code Review`, `PR` property + Work Log line |
| PR merged | Sweep (§8) sets `Dev Complete` |
| Release promoted | `/deploy` sets `In QA` for cards whose merge is in the promoted range |

### 5.3 Spikes

A Spike ends in **answers, not features**: `/work` appends findings under the
card's `## Findings` section, then moves the card **In Progress → Dev Complete
directly** — the single documented exception to the pipeline (nothing to code
review; `/deploy` never moves Spikes to In QA). If the findings imply follow-up
work, `/work` offers to draft the Story cards (via the `/feature` flow) but
never creates them silently. A Spike opens a PR only when its output is
genuinely a prototype branch the human should look at.

## 6. Reading the board (the ladder)

Notion's query tools — SQL **and** view queries — currently require a paid
plan tier (verified 2026-07; the ladder handles either case if tiers change),
and a plain fetch of the database returns its *schema*, not its rows (verified
live). The crew MUST NOT depend on any single rung. Every read walks this
ladder:

1. **Try SQL** (`query-data-sources`) against the stored `collection://` id.
   On any error mentioning plans, Notion AI, or upgrades — fall through, don't
   retry.
2. **Try the view query** (`query-database-view`) on the Board view URL. Same
   plan gate, same fall-through.
3. **Scoped search + fetch** — works on every plan. Search *within the data
   source* (pass the stored `collection://` id as the search scope) for what
   you need: the status name (`"Dev Ready"`) for a listing, the ticket id
   (`"KANI-12"`) for one card. Then **fetch each hit page** — the fetched
   properties (`Status`, `Category`, `Ticket ID`, `PR`, `Branch`) and body are
   authoritative; search highlights are not. Search is semantic, not
   exhaustive: for listings, also search the ticket prefix and merge the hits,
   and if the board plausibly holds more active cards than came back, say so
   in the report — never claim completeness the read can't guarantee.
4. **Everything failed →** the board is unreachable; proceed per §9.

Rungs 1–3 use the same stored id — the ladder needs no extra config.

## 7. Claiming, resuming & racing

- **Claim check:** immediately before Dev Ready → In Progress, re-fetch the
  card. Already In Progress? Look for the Work Log breadcrumb:
  - Breadcrumb branch exists (local or remote) → **resume** it: reattach the
    worktree, continue from the evidence (commits, test state). Never silently
    restart finished work.
  - No branch → the claim is stale. Offer the human: reset to Dev Ready (with a
    Work Log line) or start fresh.
- The local/remote **branch search by id (§5.1) works even when Notion is
  down** — it is the claim check of last resort.
- Notion has no transactions. Fetch-verify-update is the best approximation;
  same-direction races (two sweeps) are idempotent and harmless.
- A human dragging a card backward mid-run wins: the crew stops that ticket's
  pipeline, leaves git state intact, and reports.

## 8. The merge sweep

The crew never merges its own PRs, so a merged PR is invisible until the next
board-touching command runs. The **sweep** reconciles:

```
1. Read cards in Code Review (ladder §6). Cap at 20.
2. For each card with a PR url: gh pr view <url> --json state,mergedAt
   - MERGED → Status: Dev Complete + Work Log "swept: PR merged (<sha>)"
   - CLOSED (unmerged) → leave the card; report ("PR closed unmerged — move
     the card back or close it")
   - gh error → skip, count, report the count at the end
3. Code Review cards with an empty PR → report, don't touch.
```

- **Hosts:** start of `/work` (any mode), start of `/deploy`, and `/board`
  status mode. **Nowhere else** — `/plan`, `/review`, `/harden`, `/comply`,
  `/diagram` are read-only and MUST NOT write to the board.
- **Forward-only, single-edge, idempotent:** the sweep moves cards along
  exactly one edge (Code Review → Dev Complete), only from the expected source
  status. It never advances a card a human demoted, and a merged-then-reverted
  PR is human territory (drag the card back; the precondition keeps it there).
- After a sweep detects merges while other ticket PRs are open, instruct a
  rebase pass on the remaining open ticket branches
  (`git rebase --autostash origin/<integration-branch>` + gate re-run +
  `--force-with-lease`, per `docs/COMMITS.md`).

## 9. Degradation contract — never block engineering

1. **Two gates decide the mode.** Config gate: `PROJECT.md` §12 exists and
   isn't `none`. Tool gate: Notion MCP tools are available — match them by
   name *suffix* (`…notion-fetch`, `…notion-create-pages`…); the server prefix
   varies per install, so commands MUST reference tools by function, never by
   full name.
2. **Every Notion write: try once, retry once, move on.** Collect failures;
   end the run with "board out of sync — the next sweep reconciles". The sweep
   rebuilds board state from git/GitHub truth (branch, PR, merge SHA) — that is
   the recovery mechanism; there is no sync ledger.
3. **Card deleted or unfindable mid-flight:** finish the engineering work,
   ship the PR, report ("KANI-12 disappeared from the board; PR shipped
   anyway").
4. **Batch creation** (seeding, epic children) uses the batch create tool
   (≤100 pages/call). If it returns an async task, poll until done **before**
   reporting card ids. On throttling: wait ~30s, retry once, then output the
   remaining cards as a markdown table for the human to paste — never loop.
5. **Permission prompts stall unattended runs:** `/board` reminds the user to
   allowlist their Notion MCP server's tools in `.claude/settings.local.json`
   before batch `/work` (the exact tool prefix is install-specific, so this is
   a user step, not shipped config). The worktree ship command
   (`cd <worktree> && gh pr create …`) may need the same treatment — bare
   `gh pr create` rules don't match the `cd`-prefixed compound.
6. **Resolving ticketing mode (ticket-creation commands: `/feature`, `/bug`,
   `/spike`, `/epic`).** The two gates from rule 1, applied at the top of each
   command, in order:
   - **`Ticketing: notion` and the tools respond** → run the command's ticket
     flow.
   - **`Ticketing: none`** (or §12 deleted) → silently run the command's
     classic fallback — zero mention of ticketing or Notion, ever.
   - **§12 absent / never configured** → a one-time explanation, ≤3 lines:
     what this command does, that `/board` sets the board up, and that
     recording `Ticketing: none` in `PROJECT.md` §12 silences the note for
     good. Offer the classic fallback for this run; once `none` is recorded,
     never repeat the explanation.
   - **§12 says `notion` but the tools are missing/unreachable** → say so
     briefly, point to `docs/TOOLING.md`, and offer the classic fallback for
     this run.

   Each command's classic fallback:

   | Command | Classic fallback |
   |---|---|
   | `/feature` | `.claude/commands/work.md`'s ticketless mode, as if invoked as `/work <input>` |
   | `/bug` | The ticketless `/work` lifecycle on the bug description |
   | `/epic` | `/plan` (architect design brief + execution plan, no cards) |
   | `/spike` | `/plan` (an architect investigation without a card) |

## 10. Non-goals

Decided, not open for re-litigation:

1. **No daemons, webhooks, cron, or CI jobs.** The sweep is opportunistic and
   in-session; board staleness between sessions is accepted by design.
2. **No bidirectional live sync.** Git/GitHub is truth; the board reflects it.
3. **No SQL-mode dependence** — the ladder (§6) always has a fetch path.
4. **No sprint/estimate/velocity mechanics, no assignee sync, no mirroring of
   PR review threads into cards.**
5. **Human gates stay human:** Backlog → Dev Ready, In QA → Done, PR merges.
   Epics are never workable.
6. **One repo ⇄ one board section.** No cross-repo boards, no Jira/Linear
   import tooling.
7. **No runtime code.** The ticket layer is prompt files + this charter; the
   only shell involved is the crew's existing hooks.
