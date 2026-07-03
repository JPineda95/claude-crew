---
description: "Implement work — a ticket by id, every Dev Ready ticket in parallel, or a plain description (the classic full lifecycle)."
argument-hint: "[ticket id | what to build]"
---

Orchestrate the work below through the crew workflow in `docs/WORKFLOW.md`. You
are the orchestrator — delegate; don't do it all yourself.

**Input:** $ARGUMENTS

## Mode resolution (do this first)

Read `PROJECT.md` — §5 for the integration branch and naming, §12 for the
ticketing config (prefix, data source id, Max parallel tickets). Pick the mode
deterministically from the input above:

1. First token matches `^<PREFIX>-[0-9]+$` (prefix from §12) → **Ticket mode**.
   Any trailing text is scoping context for that ticket — restate it.
2. No arguments and §12 says `Ticketing: notion` → **Batch mode**.
3. Anything else → **Ticketless mode**, with the input as the request.
4. No arguments and no ticketing → ask what to build.

Always restate the chosen interpretation in one line ("Working ticket KANI-12,
scoped to …" / "Batch: all Dev Ready tickets" / "Ticketless: <request>"). On a
ticketed project (§12 `notion`), run the merge sweep (`docs/TICKETS.md` §8)
right after mode resolution — **whatever the mode** — so merged PRs reconcile
before new work starts. If ticket or batch mode is chosen but the Notion MCP
tools are missing or every rung of the read ladder fails (`docs/TICKETS.md`
§6), say so briefly, point to `docs/TOOLING.md`, and offer ticketless mode for
this run — a board failure never blocks engineering (`docs/TICKETS.md` §9).

## Ticketless mode — the classic lifecycle

**Task:** the request from the input above.

1. **Intake** — Read `PROJECT.md`. Restate the request in one or two sentences
   and note any assumption. Check for an open ticketless crew PR from a
   previous run (`gh pr list`) — ticketless work keeps the classic serial rule
   (one open ticketless crew PR at a time); if one is still awaiting review,
   STOP: the next task starts only after it is merged or explicitly closed. If
   something genuinely ambiguous would change the outcome, ask now; otherwise
   proceed.
2. **Branch** — sync `<integration-branch>`, then create this task's branch off
   it (`<type>/<slug>` per `PROJECT.md` naming). All work lands on this branch;
   parallel task worktrees branch off it and merge back into it per
   `docs/WORKTREES.md`.
3. **Design & Plan** — Spawn `architect` for a design brief and an execution
   plan (task list with owners, dependencies, hot-file map). Pull in `designer`,
   `database-architect`, and/or `security-engineer` if needed — and
   `data-compliance-officer` if it collects new personal data, sets
   cookies/tracking, or sends user data to a new third party.
4. **Test-first** — Spawn `qa-engineer` to write failing tests for the
   acceptance criteria before implementation (`docs/TESTING.md` §3), including
   the e2e spec when a core flow changes. Require red evidence in its handoff.
   Skipping only for changes with nothing testable — record the justification
   for the PR's Testing section.
5. **Build** — Delegate each planned task to its owning specialist.
   Disjoint-file tasks in parallel (spawn in one turn); serialize on hot files;
   isolate parallel editors in worktrees per `docs/WORKTREES.md`.
6. **Verify** — `qa-engineer` runs the full suite plus the e2e smoke set for
   touched core flows; confirm the validation gate is green. Do not claim
   success without running it.
7. **Review** — Spawn `reviewer-architecture`, `reviewer-code-quality`, and
   (for security-relevant changes) `reviewer-security` in parallel.
8. **Fix & iterate** — Fix every CRITICAL, weigh WARNING/SUGGESTION, re-run the
   gate, re-review if needed (cap ~3 rounds).
9. **Ship** — when reviewers approve: re-run the pre-PR gate, write atomic
   commits per `docs/COMMITS.md`, push the branch, open a PR against
   `<integration-branch>` per `docs/WORKFLOW.md` §8 with gate results in its
   Testing section; the PR's "How to verify" section carries numbered manual
   testing notes (Go to… / Click… / Confirm…). Summarize what was built, review
   verdicts, exact verify commands, PR URL.
10. **Stop at the PR.** Never merge; the human reviews. Address PR comments
    with follow-up commits.

## Ticket mode — `/work <ID>`

Board reads walk the ladder (`docs/TICKETS.md` §6); board writes follow §5.2
and are check-before-write (§1). Refer to Notion tools by function — names vary
per install. In this order:

1. **Sweep** — if not already run at mode resolution (`docs/TICKETS.md` §8).
2. **Resolve the card** — ladder (§6). Card unfindable → report it and offer to
   run ticketless from a human-supplied description.
3. **Guards** —
   - Category **Epic** → refuse — Epics are never workable (§2). List its Dev
     Ready children and stop.
   - Status **In Progress** → resume semantics (§7): search branches by id per
     §5.1 (`git branch --list "*<ID>-*"` + `git ls-remote --heads origin
     "*<ID>-*"`). A breadcrumb branch exists → resume it, whatever its slug —
     reattach the worktree and continue from the evidence. No branch → stale
     claim: ask the human (reset to Dev Ready with a Work Log line, or start
     fresh).
   - Any status other than Dev Ready / In Progress → stop and say why — the
     triage gate (Backlog → Dev Ready) is human-only (§1).
4. **Definition of Ready** — check §4. A failing card is repaired **inline**:
   interview the human (batch 3–6 questions, AskUserQuestion when available,
   propose-then-confirm), write the answers back to the card, then proceed.
   Never invent acceptance criteria.
5. **Claim** — Status → In Progress, set the `Branch` property, append the Work
   Log line (§5.2). Create branch `<type>/<ID>-<slug>` off
   `<integration-branch>` (`feat/` for Stories, `fix/` for Bugs — §5.1).
6. **Lifecycle** — run ticketless phases 3–8 with the card as the task
   statement. The card's acceptance criteria **are** the acceptance criteria:
   `qa-engineer` writes one red test per criterion (`docs/TESTING.md` §3).
7. **Ship** — re-run the pre-PR gate and open the PR **from the ticket branch's
   checkout** (`cd <worktree> && gh pr create` when in a worktree — the gate
   hook validates that checkout). PR title stays Conventional with the id as a
   suffix — `feat: add user invites (KANI-12)` — never `#`-prefixed. PR body: a
   `Ticket:` line with the card URL, plus testing notes **generated from the
   acceptance criteria** — never a raw card dump (§5.1).
8. **Card** — Status → Code Review, set the `PR` property, append the Work Log
   line. Report the ticket id and PR URL, then stop — the human reviews and
   merges.

**Spike path** (§5.3): a Spike ends in answers, not features. Respect the
card's Timebox line; investigate; append findings under the card's
`## Findings`; move the card In Progress → **Dev Complete** directly. No PR
unless the output is genuinely a prototype branch the human should look at. If
the findings imply follow-up work, **offer** to draft Story cards — never
create them silently.

## Batch mode — `/work` with no arguments

1. **Sweep** — if not already run at mode resolution (`docs/TICKETS.md` §8).
2. **Read the queue** — all Dev Ready cards minus Epics (ladder §6), ordered by
   Priority.
3. **Definition-of-Ready screen** — cards failing §4 are **skipped**: append a
   Work Log line naming exactly what's missing. Never demote a card, never
   invent acceptance criteria (§4).
4. **Pre-flight** — spawn `architect` **once** over all surviving tickets:
   per-ticket predicted file footprint, a cross-ticket hot-file map, clusters
   (overlapping footprints — shared lockfiles, migrations, i18n tables are the
   usual hints), and a recommended merge order.
5. **Wave plan** — waves of at most **Max parallel tickets** (`PROJECT.md` §12,
   default 3 — the cap counts tickets, not agents). Clusters serialize
   internally: the next clustered ticket starts only after the previous one's
   PR **merges**. Present the plan and get confirmation before executing.
6. **Execute** — each ticket = its own branch + its own worktree
   (`docs/WORKTREES.md`); claim, lifecycle, and board writes per ticket-mode
   steps 5–8. Build phases run in parallel across the wave. **The ship phase is
   serialized** — one ticket at a time: rebase onto fresh
   `origin/<integration-branch>`, run the gate, open the PR, then the next.
   Each PR's Risks section notes the recommended merge order ("merge after
   #N").
7. **Mid-run merges** — when the sweep (or a mid-run check) sees a merge,
   instruct a rebase pass on the remaining open ticket branches
   (`docs/TICKETS.md` §8).
8. **Report** — a table: ticket / branch / PR / board status / skipped + why.

## Open-PR policy

**Open-PR policy (ticketed work):** at most one open crew PR per ticket (the
ticket id is the key), and never more open crew ticket-PRs than **Max parallel
tickets** (`PROJECT.md` §12, default 3). Crew PRs are identified by their
head-branch pattern `<type>/<PREFIX>-<n>-*` via
`gh pr list --json headRefName`. Do not start new ticket work while any open
crew PR has unaddressed human change requests. Ticketless work keeps the
classic rule: one open crew PR at a time. Ticketless crew PRs are recognized by the `Crew review` section in
their body (`gh pr list --json headRefName,body`).

## Right-sizing & degradation

Right-size it: small changes collapse phases sensibly — but never skip tests
for anything with logic, and never skip security review when the change touches
auth, money, PII, uploads, or external input.

The board is a mirror, not a lock. Every Notion write: try once, retry once,
move on; a card that disappears mid-flight doesn't stop the PR. A board failure
never blocks an engineering step (`docs/TICKETS.md` §9) — collect the failures
and end the run with "board out of sync — the next sweep reconciles".
