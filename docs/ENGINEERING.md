# Engineering Charter

> The shared standards every agent on this crew follows, regardless of role or
> tech stack. Agents read this before acting. The orchestrator (root
> `CLAUDE.md`) enforces it. Keep it technology-agnostic — specifics live in
> `PROJECT.md`, which each project fills in.

## 1. First principles

1. **Correctness before cleverness.** Working, readable, boring code beats
   clever code. Optimize for the next human (or agent) who reads this.
2. **Small, reversible steps.** Prefer the smallest change that moves the task
   forward and can be verified. Big-bang changes hide bugs.
3. **Make it work → make it right → make it fast**, in that order. Do not
   micro-optimize before it is correct and clean.
4. **The codebase is the source of truth.** Match the conventions already in
   the repo over any personal or default preference. When in doubt, grep for a
   precedent and follow it.
5. **Leave it better than you found it** — but stay in scope. Note unrelated
   problems; do not fix them silently in an unrelated change.
6. **Verify, then claim.** Never say something works until you have run it,
   tested it, or read the output. Report failures honestly with the evidence.

## 2. Stack detection (do this before writing any code)

This crew is technology-agnostic. Before acting, discover the stack instead of
assuming it:

1. Read `PROJECT.md` at the repo root if it exists — it declares the stack,
   conventions, constraints, and non-negotiables for this specific project.
2. Detect language & tooling from manifests and lockfiles:
   - JS/TS: `package.json`, `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json`
   - Python: `pyproject.toml`, `requirements.txt`, `poetry.lock`, `uv.lock`
   - Go: `go.mod`; Rust: `Cargo.toml`; Ruby: `Gemfile`; PHP: `composer.json`
   - Java/Kotlin: `pom.xml`, `build.gradle`; C#/.NET: `*.csproj`, `*.sln`
3. Detect frameworks, test runners, linters, formatters, and CI from config
   files (`*.config.*`, `.eslintrc*`, `ruff.toml`, `.github/workflows/`, etc.).
4. Detect the run/build/test commands (scripts section, `Makefile`, `Justfile`,
   `Taskfile`). Never invent commands — find the real ones.
5. **Fetch current docs with Context7** for every external library you touch.
   Do not rely on training-data memory for library APIs — versions drift. See
   `docs/TOOLING.md`.

If the stack is ambiguous and the choice is consequential, ask — do not guess.

## 3. Definition of Done (applies to every task)

A change is done only when **all** of these hold:

- [ ] It does what the task asked, and nothing it wasn't asked to do.
- [ ] Tests exist for the new behavior — written first when feasible (TDD,
      `docs/TESTING.md`) — and the **full test suite passes**.
- [ ] A changed core flow has its e2e spec updated (`docs/TESTING.md` §4).
- [ ] Linter and formatter pass with zero new warnings.
- [ ] The build/typecheck succeeds.
- [ ] No secrets, credentials, or PII are committed.
- [ ] Public behavior changes are reflected in docs/comments where the repo
      keeps them.
- [ ] The diff is minimal, self-consistent, and reviewed against this charter.
- [ ] The commit(s) follow `docs/COMMITS.md`.

The orchestrator will not consider a feature shippable until reviewers approve
(see `docs/WORKFLOW.md`).

## 4. Communication contract between agents

Every agent produces a short, structured **handoff** so the next agent (or the
orchestrator) can act without re-deriving context. A handoff states:

- **What I did** — the change, in one or two sentences.
- **Files touched** — paths, with a one-line why for each non-obvious one.
- **How to verify** — the exact commands to run and what "pass" looks like.
- **Assumptions & decisions** — anything you chose that a reviewer should check.
- **Open questions / risks** — what you are unsure about or deferred.
- **Next** — the recommended next agent or step.

Agents do not silently expand scope. If you discover work outside your task,
report it as a recommendation; let the orchestrator decide.

## 5. Quality bar by concern (shared vocabulary)

- **Readability** — names say what they mean; functions do one thing; nesting
  is shallow; comments explain *why*, not *what*.
- **Correctness** — edge cases, empty/nil, boundaries, concurrency, timezones,
  money, and failure paths are handled deliberately.
- **Security** — untrusted input is validated at the boundary; output is
  encoded; authz is checked on every server path; secrets never touch code.
  See `security-engineer` and `reviewer-security`.
- **Performance** — no accidental N+1s, unbounded loops, or work in hot paths
  that belongs in a cache/queue. Measure before optimizing.
- **Testability** — logic is pure where it can be; side effects are isolated;
  seams exist for tests.
- **Accessibility** — interactive UI meets WCAG 2.2 AA (keyboard, contrast,
  labels, focus). See `designer` and `frontend-engineer`.

## 6. Escalation & boundaries

- Stay inside your role. A frontend agent does not redesign the database; it
  files a request for `database-architect`. Cross-cutting decisions go to
  `architect` or the orchestrator.
- If a task needs a decision above your pay grade (product direction, breaking
  API change, new dependency, new infra cost), stop and surface it.
- If two agents need the same files, follow `docs/WORKTREES.md` — do not race.

## 7. Shell discipline (you run unattended)

Agents run headless — nobody is at the keyboard to answer a prompt. A command
that waits for input sits silent until a watchdog kills the whole agent and the
task fails. Rules:

- **Every command must be non-interactive.** Pass every answer as a flag or an
  env var: `--yes` / `-y`, `--non-interactive`, `CI=1`. Scaffolders are the
  classic trap — e.g. `npx -y create-next-app@latest . --typescript --tailwind
  --eslint --app` (every question answered up front), never a bare
  `npx create-next-app`.
- **Never run a command that can prompt** — logins, credential prompts, config
  wizards, deletes that ask for confirmation. If a tool has no non-interactive
  mode, stop and report it instead of running it.
- **Run long commands in the background.** Anything that can exceed ~2 minutes
  (dependency installs, builds, downloads) runs via the Bash tool's
  `run_in_background`, then poll for completion. Do **not** raise the foreground
  timeout to cover a long silent command — a silent foreground call is
  indistinguishable from a hang and can get the whole agent killed.
- **Prefer output that shows life.** For foreground work, a command that prints
  progress is diagnosable; one that is silent for minutes is not.

## 8. Git discipline (summary — full rules in docs)

- One task → one branch. See `docs/WORKTREES.md`.
- Rebase your feature branch onto the integration branch to stay current; never
  rebase shared/published history.
- Commit in atomic units with Conventional Commit messages that explain **why**.
  See `docs/COMMITS.md`.
- **Ship via pull request.** A finished feature is committed on its feature
  branch, pushed, and opened as a PR with a complete description
  (`docs/WORKFLOW.md` §8) — standing policy, unless `PROJECT.md` sets Ship
  mode `ask`. Never push the integration branch, never merge a crew PR, and
  never deploy without explicit human authorization.
