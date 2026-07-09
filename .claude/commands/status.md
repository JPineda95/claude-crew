---
description: "Read-only session-opener: branch state, open crew PRs, commits awaiting /deploy, stale worktrees, and whether the validation gate is configured."
allowed-tools: Bash(git fetch:*), Bash(git status:*), Bash(git branch:*), Bash(git log:*), Bash(git worktree:*), Bash(gh pr list:*), Read, Grep, Glob
---

Report the crew's current state — strictly **read-only**. Never write, commit,
push, merge, sweep the board, or run the validation gate; only look and
report. Degrade gracefully wherever a signal is unavailable (no `PROJECT.md`,
no remote, no `gh`, board unreachable) — report "unknown"/"unreachable" for
that one line and keep going; never fail the whole report over one missing
signal.

Gather, in order:

1. **Branch state.** `git fetch origin --quiet` (skip silently if there's no
   remote configured), then report the current branch (`git branch
   --show-current`). If `PROJECT.md` doesn't exist yet, stop right here —
   report just the branch name, say `PROJECT.md` is missing, suggest
   `/onboard`, and skip every step below (they all key off `PROJECT.md`).
   Otherwise continue: report the branch's ahead/behind count against the
   integration branch (`PROJECT.md` §5).
2. **Open crew PRs vs the open-PR policy.** `gh pr list --json
   headRefName,body,url,title` (report "gh unavailable" if the command
   fails). Identify crew PRs per `docs/WORKFLOW.md` §8: ticketed work by
   head-branch pattern `<type>/<PREFIX>-<n>-*` (prefix from `PROJECT.md`
   §12 when ticketing is on), ticketless work by a `Crew review` section in
   the PR body. Report the count against the policy — one open PR per
   ticket capped by Max parallel tickets; ticketless = one open PR at a
   time — and flag it plainly if the count currently violates that.
3. **Commits awaiting `/deploy`.** If `PROJECT.md` §5 names a production
   branch distinct from the integration branch: `git log
   origin/<production>..origin/<integration> --oneline`, report the count
   ("N commits awaiting /deploy") or "up to date". Same branch or no
   production branch configured → "no promotion step configured for this
   project".
4. **Stale worktrees.** `git worktree list` — for each non-primary entry,
   check whether its branch is merged into the integration branch
   (`git branch --merged origin/<integration-branch>`). Flag unmerged ones
   as "still in progress"; flag any whose branch no longer exists as
   "orphaned — safe to `git worktree remove`" (report only, never remove it
   yourself).
5. **Validation gate configured?** Read `.claude/crew.env` with the **Read
   tool only** — never source or execute it, and never run the gate itself.
   Report whether `CLAUDE_VALIDATE_CMD` has a non-empty default there, or is
   exported in the current session environment.
6. **Board status** — only when `PROJECT.md` §12 says `Ticketing: notion`.
   Read-only: report card counts per status via the read ladder
   (`docs/TICKETS.md` §6). If the Notion tools are unavailable or every
   rung fails, report "board unreachable" and move on — this never blocks
   the rest of the report.
7. **Unfinished crew-update merges.** Look for `*.crew-new`, `CLAUDE.crew.md`,
   and `settings.crew.json` in the repo root and `.claude/`. Any hits →
   report them and suggest `/crew-update` to finish merging.

Present all of this as one compact table or tight bullet list — this command
exists to be skimmed in five seconds at the start of a session, not read
like a report. Close with whichever of these is most relevant, if any: a
suggestion to run `/crew-update` (stray merge files found), `/tests` (no
gate configured), or nothing extra if everything above is clean.
