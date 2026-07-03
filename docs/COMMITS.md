# Integration, Rebase & Commit Protocol

> How parallel agents integrate work, keep branches current, and write commits.
> Normative: **MUST / SHOULD / MUST NOT** carry RFC-2119 meanings. Companion to
> [WORKTREES.md](./WORKTREES.md).
>
> Technology-agnostic. **the validation gate** = the command your `PROJECT.md`
> declares (tests + lint + typecheck + build). `<integration-branch>` = the
> branch your `PROJECT.md` integrates into (default `dev` — the crew never
> integrates on `main`).

## 1. Integration strategy

**Branch model**
- **Short-lived branches.** A task branch lives hours-to-days, not weeks. Long
  divergence is the single biggest source of painful merges. Integrate early and
  often.
- **One integration target.** Agents integrate into ONE branch — either `main`
  directly (trunk-based) or a shared `dev`/`integration` branch that periodically
  advances to `main`. Declare which in `PROJECT.md`.
- **Trunk-based by default:** branch from the trunk, work small, merge back fast.
  It keeps the integration surface tiny.
- **Stacked branches for dependent work:** when task B builds on unmerged task A,
  branch B off A (`git worktree add -b B <path> A`) and rebase the stack
  bottom-up as A evolves. Keep stacks shallow (2–3 deep).

**Serializing writes**
- **Disjoint file ownership** is the primary conflict-avoidance mechanism
  (WORKTREES.md §7). Assign each agent a non-overlapping module.
- **Hot files** (lockfiles, shared config, route/i18n tables) get a single owner
  per integration cycle or an advisory lock (WORKTREES.md §8).

## 2. Rebase vs. merge

**The policy**
- **Rebase your own feature branch** onto the latest integration tip to stay
  current and produce a clean, linear history before integrating.
- **Merge** (never rebase) when integrating into a **shared/published** branch,
  and whenever the branch you'd rewrite is used by anyone else.

**The Golden Rule of Rebasing**

> **Never rebase commits that exist anywhere outside your own worktree — i.e.
> never rebase commits others have based work on.**

Rebasing rewrites history (new SHAs). If someone else holds the old commits, your
histories diverge and the next sync duplicates commits and spawns ugly conflicts.

- ✅ Rebase a private task branch only one agent owns.
- ❌ Never rebase `main`, `dev`, `release/*`, or any branch someone else has
  pulled or branched from. Integrate those with **merge**.

**Keep a feature branch current (runbook)**

```bash
git fetch origin
# --autostash shelves uncommitted work and reapplies it; --update-refs fixes up
# any stacked branches pointing into this one.
git rebase --autostash --update-refs origin/<integration-branch>
```

Make them defaults so you never forget:

```bash
git config --global rebase.autostash true
git config --global rebase.updateRefs true
git config --global rerere.enabled true   # reuse recorded conflict resolutions
```

**Clean history before a PR (private branch only)**

```bash
git rebase -i origin/<integration-branch>
# pick / squash / fixup / reword / drop / edit → a tidy, atomic series.
```

This rewrites history, so it's allowed **only** on a private, unpublished branch
(Golden Rule). Once pushed and reviewed, do not re-rewrite shared history.

`rerere` (REuse REcorded REsolution) records how you resolved a conflict and
replays it when the identical conflict recurs — a big win for repeated rebases
and for parallel agents hitting the same hot files. Enable it once (above).

## 3. Conflict-resolution runbook

```bash
git fetch origin
git rebase --autostash --update-refs origin/<integration-branch>

# On conflict:
git status                 # see unmerged files
git diff                   # inspect the conflict markers
#   Resolve each file by understanding BOTH sides. If you truly want one side:
#     git checkout --theirs <file>   # the rebased-onto version
#     git checkout --ours   <file>   # your branch's version
#   ...then edit to reconcile the logic.
git add <file> ...
git rebase --continue      # rerere records your resolution
#   Repeat per conflicting commit. To bail out completely:
git rebase --abort

# After a clean rebase, re-run the validation gate before pushing.
# Then push — rebase rewrote your SHAs, so a plain push is rejected:
git push --force-with-lease
```

**Rules during resolution**
- Resolve by understanding both sides, not by reflexively picking one.
- Never resolve by deleting another agent's feature just to make it compile. If
  intent is unclear, **stop and flag it**.
- Re-run the validation gate after resolving — a resolution that compiles can
  still be semantically wrong.

## 4. Commit conventions (Conventional Commits v1.0.0)

**Structure**

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

**Types**

| Type | Use (SemVer impact) |
|---|---|
| `feat` | New feature (MINOR) |
| `fix` | Bug fix (PATCH) |
| `docs` | Documentation only |
| `style` | Formatting/whitespace; no behavior change |
| `refactor` | Neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Add/correct tests |
| `build` | Build system or dependencies |
| `ci` | CI configuration and scripts |
| `chore` | Maintenance not touching src or tests |
| `revert` | Reverts a previous commit |

**Scope** — optional noun for the affected area: `fix(calendar): …`,
`feat(auth): …`. Reuse the module/domain vocabulary the repo already uses.

**Breaking changes** — use both when it matters:
- `!` before the colon: `feat(api)!: drop v1 booking endpoint`
- a footer: `BREAKING CHANGE: <what broke and how to migrate>` (`BREAKING CHANGE`
  MUST be uppercase). Either triggers a MAJOR bump regardless of type.

**What makes a high-quality commit**
- **Explain WHY, not what.** The diff shows *what* changed; the body is for the
  reasoning, trade-offs, and context the next reader (or agent) needs.
- **Imperative mood** in the subject: "add", "fix", "remove" — reads as "if
  applied, this commit will …".
- **Wrap the body at 72 columns**; subject ≤ 50–72 chars.
- **Atomic commits:** one logical change per commit; it builds and passes the gate
  on its own and can be reverted in isolation.
- **Reference issues** in a footer: `Refs: #123`, `Closes: #123`. For ticketed
  work ([TICKETS.md](./TICKETS.md)) reference the card as `Refs: KANI-12` —
  the bare ticket id, **never** `#`-prefixed (`#12` autolinks to an unrelated
  GitHub issue). Keep `Refs: #n` for actual GitHub issues.
- **Blank line** between subject and body, and before footers.

**Template**

```
<type>(<scope>): <imperative summary, ≤72 chars>

Why this change is needed and what problem it solves. Describe the previous
behavior and why it was wrong or insufficient. Wrap at 72 columns. Focus on
intent and trade-offs, not a restatement of the diff.

Note side effects, migrations, or follow-ups.

Refs: #<issue>
BREAKING CHANGE: <only if applicable — what breaks and how to migrate>
Co-authored-by: Name <email>
```

**Examples**

```
fix(webhook): verify calendar sync signature before processing

The webhook route trusted the payload without verifying the provider's
signature, so a forged request could trigger a sync and overwrite state.
Verify the signature against the channel token and reject mismatches with
401 before any write.

Refs: #482
```

```
feat(availability)!: make availability per-location instead of global

Multi-location professionals shared one weekly grid, which produced
double-bookings across sites. Move availability under location_id and
filter the booking query by the location being booked.

BREAKING CHANGE: availability rows now require a location_id. Run the
availability_location migration to backfill existing rows to the primary
location.

Refs: #501
```

```
refactor(timezone): route all conversions through the timezone service

Conversion logic was duplicated in three places with subtly different DST
handling, causing off-by-one-hour reminders near transitions. Centralize so
the stored timezone is the single source of truth.

Refs: #467
```

## 5. Safety rules for agents committing

These are **hard constraints**. An agent that cannot satisfy them stops and
reports rather than proceeding.

1. **Ship through the PR gate.** Commit on your own feature/task branch — never
   the integration branch (if on it, branch first). At feature completion, push
   the feature branch and open a PR (WORKFLOW.md §8); that is standing policy
   unless `PROJECT.md` sets Ship mode `ask`. Merging the PR is the human's
   call — never merge your own.
2. **Verify before commit.** Run **the validation gate** and commit only when it
   passes. Never commit code that fails tests or lint.
3. **Never force-push a shared/published branch.** `main`, `dev`, `release/*`, or
   any branch another agent branched from are off-limits to force-push, full stop.
4. **`--force-with-lease` only, and only on your own branch.**
   ```bash
   git push --force-with-lease                     # aborts if the remote moved
   git push --force-with-lease --force-if-includes # also requires you saw its latest
   ```
   Plain `git push --force` is **banned** — it silently discards others' commits.
5. **Do not rewrite pushed/shared history.** Once pushed and possibly held by
   others, a branch's history is frozen: add commits or `git revert`; do not
   amend/rebase what's published.
6. **Never commit secrets.** No `.env`, keys, or tokens. If a secret must reach a
   worktree, use `.worktreeinclude` or a manual copy — not a commit.
7. **Signed commits** (`git commit -S`) are OPTIONAL but recommended where the
   team enforces verified commits.
8. **Attribution trailers** for agent-authored commits — add a trailer for every
   contributor so authorship is auditable, e.g.:
   ```
   Co-authored-by: Claude <noreply@anthropic.com>
   ```

## 6. Quick reference

```bash
# Stay current
git fetch origin
git rebase --autostash --update-refs origin/<integration-branch>

# Clean history (private branch only)
git rebase -i origin/<integration-branch>

# Conflicts: resolve → git add → git rebase --continue   (git rebase --abort to bail)

# Validate then push (own branch only; never plain --force)
#   <run the validation gate>
git push --force-with-lease

# One-time config
git config --global rebase.autostash true
git config --global rebase.updateRefs true
git config --global rerere.enabled true
```

## Sources

- Conventional Commits v1.0.0 — https://www.conventionalcommits.org/en/v1.0.0/
- Atlassian, Merging vs. Rebasing & the Golden Rule — https://www.atlassian.com/git/tutorials/merging-vs-rebasing
- git-rebase (autostash, update-refs, rerere) — https://git-scm.com/docs/git-rebase
- git-worktree — https://git-scm.com/docs/git-worktree
- Force push safely (`--force-with-lease`/`--force-if-includes`) — https://adamj.eu/tech/2023/10/31/git-force-push-safely/
- Claude Code — Common workflows (worktrees, subagents) — https://code.claude.com/docs/en/common-workflows
