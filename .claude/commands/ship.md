---
description: Commit the current work, push the feature branch, and open a PR for human review.
argument-hint: "[optional context or issue reference]"
allowed-tools: Bash(git status), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(gh pr list:*)
---

Ship the current work per `docs/COMMITS.md` and `docs/WORKFLOW.md` §8. Extra
context: $ARGUMENTS

Working tree:

!`git status --short && echo "---" && git diff --stat`

Steps:

1. **Gate first.** Run the validation gate (lint + full test suite + typecheck/
   build per `PROJECT.md`) and the e2e smoke set when configured. If anything is
   red, stop and report — do not commit broken code. If the diff changes code
   but touches no tests, stop and route to `qa-engineer` first
   (`docs/TESTING.md` §3) — the pre-PR hook will refuse the PR anyway.
2. **Confirm the branch.** If on the integration/default branch, create the
   feature branch first (`<type>/<slug>` per `PROJECT.md` naming). Never commit
   to the integration branch directly — and NEVER to `main`/the production
   branch. The PR targets `<integration-branch>` only; if `PROJECT.md` §5
   names none separate from production, create `dev` off the default branch,
   push it, record it in §5, and target that.
3. **Ticket linkage.** If the branch name carries a ticket id
   (`<type>/<PREFIX>-<n>-…`, prefix from `PROJECT.md` §12), this is ticketed
   work (`docs/TICKETS.md` §5): use `Refs: <ID>` commit trailers, suffix the PR
   title with the id — `feat: … (KANI-12)` — and give the PR a `Ticket:` line
   plus manual testing notes generated from the card's acceptance criteria
   (`docs/WORKFLOW.md` §8).
4. **Group into atomic commits.** Split the diff into logical, self-contained
   commits (one concern each). For each, write a Conventional Commit message with
   a body that explains **why** — the reasoning and trade-offs, not a restatement
   of the diff. Add `Refs:`/`Closes:` and a `Co-authored-by:` trailer.
5. **Ship.** In Ship mode `pr` (the default): commit, push the feature branch,
   and open a PR against `<integration-branch>` with the description spec from
   `docs/WORKFLOW.md` §8 — from the branch's own checkout (in a worktree:
   `cd <worktree> && gh pr create`). Report the PR URL and stop — the human
   reviews and merges. If `PROJECT.md` sets Ship mode `ask`: show the proposed
   commit split and full messages instead, and wait for approval before running
   `git commit` / `git push`.
6. **Update the card (ticketed work, best-effort).** After the PR opens: set
   the card's Status to Code Review and its `PR` property, and append a Work
   Log line (`docs/TICKETS.md` §5.2). A failed board write never blocks or
   reverts the ship — report it and move on (§9).
7. **Never merge your own PR.** Deploying always requires explicit human
   authorization.
8. Never force-push a shared branch; `--force-with-lease` only, on your own branch.
