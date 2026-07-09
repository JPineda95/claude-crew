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
- [ ] It honors the design principles in §6 (SOLID & Clean Code), proportionate
      to its scope — no new God-objects, dead abstractions, swallowed errors,
      magic values, or duplication the diff could have avoided.
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

## 6. Design principles: SOLID & Clean Code

Correctness and readability (§1, §5) are the floor. This section is the shared
standard for *how the code is shaped* — every agent applies it, every reviewer
cites it by name, and the Definition of Done (§3) requires it. It is
technology-agnostic: the same rules govern a React component, a domain service,
a SQL migration, or a shell script.

### SOLID

- **Single Responsibility** — a module, class, or function has one reason to
  change. If you can only describe what it does using "and", split it. A
  function does one thing, at one level of abstraction.
- **Open/Closed** — extend behavior by adding code, not by editing stable code
  in place. A `switch`/`if-else` ladder that every new case must reopen is the
  classic violation; prefer polymorphism, a strategy map, or a new
  implementation of an interface.
- **Liskov Substitution** — a subtype must work anywhere its base type does,
  with no surprises: no overrides that throw "not supported", silently narrow
  accepted inputs, or weaken a guarantee callers rely on.
- **Interface Segregation** — keep interfaces small and client-specific. Don't
  force a caller to depend on methods it never uses; split fat interfaces into
  role-based ones.
- **Dependency Inversion** — depend on abstractions, not concretions. High-level
  policy must not import low-level I/O (db, HTTP, clock, filesystem) directly;
  inject it behind an interface so the core stays pure, swappable, and testable
  (this is the same seam §5 calls testability and the `architect` calls "push
  I/O to the edges").

### Clean Code

- **Names reveal intent.** No cryptic abbreviations, no `data`/`tmp`/`mgr`, no
  type encodings in names. A name is wrong if it needs a comment to say what it
  holds.
- **Small functions, few parameters.** Short, focused, one level of abstraction.
  Prefer ≤3 parameters; bundle more into a named value object. No boolean flag
  argument that forks the body — split it into two functions.
- **Guard clauses over deep nesting.** Return early; keep the happy path
  unindented. Nesting past ~3 levels is a smell to refactor, not to comment.
- **No duplication (DRY) — but no wrong abstraction.** Extract genuinely shared
  logic; do **not** merge two things that only look alike today. Duplication is
  cheaper than the wrong abstraction.
- **Command/Query separation.** A function either *does* something or *answers*
  something — not both. No surprising side effects behind a getter.
- **Fail fast, never swallow.** Validate at the boundary; raise or return
  meaningful errors; never catch-and-ignore to make a symptom disappear.
- **No magic values.** Name every constant; no unexplained number or string
  sitting in a condition or calculation.
- **Comments explain *why*, not *what*** (§5). Delete commented-out code and
  redundant narration — they rot and mislead.

### Applying it without dogma

These principles serve correctness and changeability; they are not a checklist to
maximize. Apply judgment:

- **YAGNI beats speculative abstraction** (`architect`). Introduce an interface,
  a layer, or a pattern when there is a *real, present* reason — a second
  implementation exists, a boundary is truly crossed, a test needs a seam — not
  to pre-satisfy a principle. A lone single-use interface with one
  implementation is usually noise.
- **Match the codebase first** (§1.4). A locally consistent pattern beats a "more
  SOLID" one imported in isolation. Refactor toward these principles
  incrementally and in scope (§1.5) — don't rewrite a working module to score
  points.
- **Severity scales with blast radius.** A God-object in the domain core is a
  CRITICAL; an over-long function in a leaf utility is a SUGGESTION. Reviewers
  weight findings accordingly.

## 7. Escalation & boundaries

- Stay inside your role. A frontend agent does not redesign the database; it
  files a request for `database-architect`. Cross-cutting decisions go to
  `architect` or the orchestrator.
- If a task needs a decision above your pay grade (product direction, breaking
  API change, new dependency, new infra cost), stop and surface it.
- If two agents need the same files, follow `docs/WORKTREES.md` — do not race.

## 8. Shell discipline (you run unattended)

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

## 9. Git discipline (summary — full rules in docs)

- One task → one branch. See `docs/WORKTREES.md`.
- **NEVER commit to `main`** (or the production/default branch) — only a
  human-run `/deploy` moves it. No integration branch separate from it?
  Create `dev` off it, push it, record it in `PROJECT.md` §5, and work off
  `dev`.
- Rebase your feature branch onto the integration branch to stay current; never
  rebase shared/published history.
- Commit in atomic units with Conventional Commit messages that explain **why**.
  See `docs/COMMITS.md`.
- **Ship via pull request.** A finished feature is committed on its feature
  branch, pushed, and opened as a PR with a complete description
  (`docs/WORKFLOW.md` §8) — standing policy, unless `PROJECT.md` sets Ship
  mode `ask`. Never push the integration branch, never merge a crew PR, and
  never deploy without explicit human authorization.
