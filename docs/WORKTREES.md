# Worktrees — Parallel Agent Git Protocol

> Rules for running multiple agents (or humans) against the same repository at
> once without clobbering each other. Normative: **MUST / SHOULD / MUST NOT**
> carry their RFC-2119 meanings. Companion to [COMMITS.md](./COMMITS.md).
>
> This doc is technology-agnostic. Wherever it says **the validation gate**, run
> the command your `PROJECT.md` declares (tests + lint + typecheck + build).
> Wherever it says `<integration-branch>`, use the branch your `PROJECT.md`
> integrates into (default `main`; some projects use `dev`/`develop`).

## 1. Mental model

A **worktree** is an additional checked-out working directory linked to one
repository. Each worktree has its own working files, its own index, and its own
`HEAD`/branch — but **all worktrees share one `.git` object store and one set of
refs**. That's what makes parallel work cheap: N isolated checkouts, one history.

Two invariants follow:

- **A branch can be checked out in at most one worktree at a time.** Git refuses
  to add a worktree on a branch already checked out elsewhere. Don't fight this —
  it's a safety rail.
- **One agent → one branch → one worktree → one task.** Never point two agents at
  the same branch; never let one worktree span two tasks.

## 2. When to use a worktree (and when not)

- **One agent, sequential work:** you don't need a worktree — a normal branch in
  the main checkout is fine.
- **Two+ agents editing in parallel:** use worktrees (or Claude Code's native
  isolation, §4) so their working files can't collide.
- **A quick read/review at another commit:** a detached worktree is a clean way
  to build/inspect an old state without disturbing your branch.

## 3. Directory layout

Keep worktrees **out of the main working tree** so file watchers, linters, and
`git status` don't see them as noise. Two accepted layouts:

**Sibling directory (recommended default):**

```
~/repos/
├── project/                       # main checkout (<integration-branch>)
└── project-worktrees/
    ├── agent-a--feat-auth/
    ├── agent-b--fix-webhook/
    └── agent-c--refactor-core/
```

**Hidden in-repo directory (MUST be git-ignored):**

```
project/
├── .git/
├── .worktrees/                    # add to .gitignore AND tool-ignore files
│   └── feat-auth/
└── src/
```

**Naming (MUST):** `<agent-id>--<type>-<slug>`, mirroring the branch name
(`agent-b--fix-webhook`). A directory that matches its branch makes
`git worktree list` self-documenting.

## 4. Claude Code native worktree support (preferred)

Claude Code has first-class worktree support — prefer it over manual `git
worktree add` when driving agents.

```bash
# Start an isolated session on its own worktree + branch "feat-auth".
claude --worktree feat-auth
# A second terminal with a different name → a second isolated session.
claude --worktree fix-webhook
```

For **subagents**, request worktree isolation so each parallel agent gets its own
worktree automatically and two agents editing at once cannot collide. In an agent
file this is the `isolation: worktree` frontmatter field; when the orchestrator
spawns agents for genuinely parallel edits it should isolate them this way.

**`.worktreeinclude`:** git-ignored files (e.g. `.env.local`) are **not** copied
into a new worktree by default. List the ones a fresh checkout needs to run — env
files, local certs — in a `.worktreeinclude` at the repo root so Claude Code
seeds them into each new worktree. (See `.worktreeinclude.example` in this repo.)

## 5. Creating a worktree manually

```bash
# New branch + new checkout in one command, based on the integration tip.
git worktree add -b feat-auth ../project-worktrees/agent-a--feat-auth <integration-branch>

# Attach an EXISTING branch (no -b), e.g. to review a PR.
git worktree add ../project-worktrees/review-pr-42 feat-auth

# Detached, throwaway checkout (build/inspect an old commit).
git worktree add --detach ../project-worktrees/spike HEAD

# Inspect.
git worktree list                 # human-readable
git worktree list --porcelain     # machine-readable, for scripts/agents
```

## 6. Gotchas (read before you scale)

| Concern | Rule |
|---|---|
| **Shared `.git`** | Objects and refs are shared. `git gc`/`prune` and history rewrites in one worktree affect all. Coordinate destructive ops. |
| **Same branch twice** | Impossible by design — Git blocks it. |
| **Deps / build caches** | Per-worktree. Each new checkout needs its own dependency install. Do **not** symlink dependency dirs across worktrees — native binaries and lockfile drift will bite. |
| **Env files** | Git-ignored ⇒ not carried over. Use `.worktreeinclude`, copy manually, or symlink a shared read-only env file — never commit secrets to make them travel. |
| **Ports / servers** | Two dev servers on one port collide. Give each worktree a distinct port via its own env. |
| **Lockfiles** | If two agents bump dependencies in parallel, lockfiles conflict at merge. **Serialize dependency changes** — one agent owns the lockfile per integration cycle. |
| **Shared external state** | Worktrees share the machine. Point each agent at its own DB schema/branch or a disposable container to avoid corrupting shared state. |
| **Scale limit** | ~5–10 parallel agents is the practical ceiling; beyond that, integration becomes the bottleneck, not editing. |

## 7. Minimize conflicts by decomposition

Worktrees isolate the *filesystem*, not the *merge*. Overlapping scope still
conflicts. So the orchestrator (and `architect`) MUST:

- **Assign non-overlapping file/module ownership per agent.** Disjoint blast
  radius ⇒ near-zero conflicts. This is the primary defense.
- **Declare "hot files"** touched by multiple tasks (shared config, barrel/index
  files, route manifests, i18n string tables, lockfiles) and **serialize writes**
  to them — see §8.
- **One task per branch.** If a task splits, use stacked branches (see
  [COMMITS.md](./COMMITS.md) §1) rather than widening one branch's scope.

## 8. Hot-file locking (advisory)

Git has no file locking across branches, so for files multiple agents must touch,
use a lightweight advisory lock so writes serialize:

- Maintain `.agent-locks/<path>.lock` (git-ignored) containing the owning agent
  id and a timestamp.
- An agent MUST acquire the lock (create the file) before editing the hot file,
  and release it (delete) immediately after committing that edit.
- If the lock is held, the agent queues or picks different work — it does **not**
  edit the file.
- Locks are advisory and short-lived; a stale lock (older than a few minutes) may
  be reclaimed after the holder is confirmed idle.

The real defense is disjoint ownership (§7); locking is the fallback for genuinely
shared files.

## 9. Cleanup

Deleting a worktree directory by hand is **wrong** — it leaves a dangling admin
entry. Use the porcelain:

```bash
git worktree remove ../project-worktrees/agent-a--feat-auth        # refuses if dirty
git worktree remove --force ../project-worktrees/agent-a--feat-auth # destructive
git branch -d feat-auth        # delete branch after merge (-D to force)
git worktree prune -v          # reconcile metadata after manual deletion/crash
```

**Per-task lifecycle:**

1. `git worktree add -b <branch> <path> <integration-branch>`
2. Install deps / seed env in the new checkout.
3. Work, commit, keep the branch current (rebase — see COMMITS.md §2).
4. Open PR / integrate.
5. `git worktree remove <path>` → `git branch -d <branch>`.
6. Periodically `git worktree prune` to sweep stragglers.

## 10. Quick reference

```bash
git worktree add -b <branch> <path> <base>   # new branch + checkout
git worktree add <path> <branch>             # attach existing branch
git worktree list [--porcelain]              # inspect
git worktree remove [--force] <path>         # tear down
git worktree prune [-v]                      # reconcile metadata
claude --worktree <name>                     # native Claude Code isolation
```
