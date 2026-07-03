# claude-crew

> A cloneable **AI engineering crew** for Claude Code. Fourteen expert subagents
> that behave like a real product team, an orchestrator that knows when to spin
> up each one, and battle-tested protocols for worktrees, rebasing, and commits.
> **Technology-agnostic** — it detects and adapts to whatever stack a project
> uses.

Clone it to start a new project, or drop it into an existing one. The crew reads
one file — `PROJECT.md` — to learn your stack and rules, then builds features
through a design → test → build → review → ship workflow.

---

## The crew

| Agent | Role | Model |
|---|---|---|
| **architect** | Principal engineer / tech lead — design, decomposition, ADRs | opus |
| **designer** | Product & UI/UX design — flows, wireframes, design systems, anti-slop taste library | sonnet |
| **database-architect** | Data modeling, migrations, indexing, access policies (DBA) | opus |
| **backend-engineer** | APIs, business logic, auth, jobs, integrations | sonnet |
| **frontend-engineer** | UI, client state, accessibility, performance | sonnet |
| **qa-engineer** | Test strategy & tests (TDD), verification | sonnet |
| **security-engineer** | Threat modeling & hardening (AppSec) | opus |
| **devops-engineer** | CI/CD, IaC, deploys, config, observability (SRE) | sonnet |
| **copywriter** | UI microcopy, errors, emails, marketing copy | sonnet |
| **seo-aeo-specialist** | Technical SEO + Answer/Generative Engine Optimization | sonnet |
| **data-compliance-officer** | Data map, privacy policy, ToS, cookies/consent, data-subject rights | opus |
| **reviewer-architecture** | Pre-merge gate: structure & maintainability | opus |
| **reviewer-code-quality** | Pre-merge gate: correctness, tests, readability | sonnet |
| **reviewer-security** | Pre-merge gate: OWASP-style vulnerabilities | opus |

The **orchestrator** is the root [`CLAUDE.md`](CLAUDE.md) — a tech-lead persona in
the main thread that delegates to specialists and threads their work together.
Subagents don't spawn subagents; all fan-out is orchestrated from the top.

---

## Quickstart

### Option A — start a new project from the crew
```bash
git clone https://github.com/JPineda95/claude-crew my-app
cd my-app
rm -rf .git && git init            # make it your project's repo
cp PROJECT.template.md PROJECT.md  # then fill it in (stack, commands, rules)
```
Open the folder in Claude Code and start with `/feature <what to build>`.

### Option B — add the crew to an existing project
```bash
/path/to/claude-crew/scripts/install.sh /path/to/your/project

# later, after pulling new crew versions, sync them into the project:
/path/to/claude-crew/scripts/update.sh /path/to/your/project
```
Copies the agents, commands, scripts, skills, docs, and orchestrator into the
target (non-destructively), and seeds `PROJECT.md` from the template.
`update.sh` uses the recorded manifest to update untouched files in place while
protecting anything you customized — your version stays, the new one lands
next to it as `<file>.crew-new` (`settings.json` → `settings.crew.json`) for a
manual merge. `PROJECT.md` is never touched.

### Option C — install as a Claude Code plugin
```bash
scripts/build-plugin.sh                          # assembles dist/claude-crew
# then, inside any project:
/plugin marketplace add /absolute/path/to/claude-crew
/plugin install claude-crew@claude-crew
```

**After any option:** run **`/onboard`** — it scans the repo, interviews you
section by section, and writes a complete `PROJECT.md` (or fill in
[`PROJECT.md`](PROJECT.template.md) by hand). Then install the MCP
servers/plugins you need from [`docs/TOOLING.md`](docs/TOOLING.md), and set your
validation gate in `.claude/scripts/validate.sh` (or the `CLAUDE_VALIDATE_CMD`
env var).

---

## How it works

The orchestrator follows the lifecycle in [`docs/WORKFLOW.md`](docs/WORKFLOW.md):

```
Intake → Design → Plan → Test-first → Build → Verify → Review → Fix → Ship
```

- **Design & Plan** — `architect` produces a design brief and a task list with
  owners, dependencies, and a *hot-file map* (which files multiple tasks touch).
- **Test-first** — `qa-engineer` writes failing tests before implementation.
- **Build** — specialists implement; independent tasks run in parallel, isolated
  in git worktrees when they edit at the same time.
- **Review** — three reviewers run in parallel and return `APPROVE` /
  `REQUEST CHANGES` with severity-tagged findings.
- **Ship** — commits are atomic and message-rich; each feature ships from its own
  branch as a pull request with a complete description. Lint + the full test
  suite (+ e2e smoke) must pass first — a hook physically blocks PR creation
  while the gate is red. You review and merge — the crew never merges its own
  PR, and the next feature waits for that merge. (Set Ship mode `ask` in
  `PROJECT.md` for prepare-and-wait instead.)

Process is **right-sized**: a typo is a one-line edit, not a committee. The full
lifecycle is for changes that span layers or carry real risk.

### Slash commands
| Command | Does |
|---|---|
| `/onboard` | Interview you + scan the repo to generate a complete `PROJECT.md` |
| `/feature <desc>` | Run the full crew workflow end-to-end |
| `/plan <desc>` | Have `architect` design & plan without implementing |
| `/review [base]` | Run the three reviewers in parallel on the current diff |
| `/harden [target]` | Threat-model + security-review a change or area |
| `/comply [target]` | Data-compliance audit + generate privacy policy, ToS, cookie-banner spec |
| `/tests [focus]` | Bootstrap or backfill the test suite — audit gaps by risk, then unit/integration/Cypress e2e for the core flows |
| `/ship [context]` | Commit the work, push the feature branch, and open a PR for review |
| `/deploy [context]` | Merge the integration branch into the production branch and push — the human-authorized deploy step |

---

## The taste library (anti-slop design)

`.claude/skills/` ships nine curated design skills so the crew's UIs don't look
AI-generated. The `designer` agent is **required** to load them before visual
work, and names the relevant ones in every handoff so polish survives
implementation:

| Skill(s) | What it brings | Source |
|---|---|---|
| `impeccable` | Design vocabulary, 23 design commands, 45 deterministic slop-detection rules | [impeccable.style](https://impeccable.style/) |
| `design-taste-frontend`, `high-end-visual-design`, `minimalist-ui`, `redesign-existing-projects` | Brief inference, premium visual standards, editorial minimalism, audit-first redesigns | [tasteskill.dev](https://www.tasteskill.dev/) |
| `emil-design-eng`, `review-animations`, `animation-vocabulary` | Emil Kowalski's UI-polish philosophy, a hard craft bar for motion, precise animation naming | [emilkowal.ski](https://emilkowal.ski/) |
| `ui-ux-pro-max` | Reference database: 67 styles, 96 palettes, 57 font pairings | [nextlevelbuilder.io](https://ui-ux-pro-max-skill.nextlevelbuilder.io/) |

Update commands for each source live in [`docs/TOOLING.md`](docs/TOOLING.md).

---

## The protocols

- **[docs/ENGINEERING.md](docs/ENGINEERING.md)** — the shared charter: principles,
  stack detection, Definition of Done, and the handoff format every agent uses.
- **[docs/WORKFLOW.md](docs/WORKFLOW.md)** — when to spin up each agent, how to
  parallelize, and how to right-size the process.
- **[docs/TESTING.md](docs/TESTING.md)** — the testing charter: tests as the
  executable spec, TDD with red evidence, Cypress e2e for core flows, and the
  pre-PR gate that blocks untested PRs.
- **[docs/WORKTREES.md](docs/WORKTREES.md)** — running many agents in parallel
  without collisions: worktrees, disjoint file ownership, hot-file locking,
  cleanup. Uses Claude Code's native `--worktree` / `isolation: worktree`.
- **[docs/COMMITS.md](docs/COMMITS.md)** — integration strategy, the Golden Rule
  of rebasing, a conflict-resolution runbook, Conventional Commits, and hard
  safety rules for agents committing.
- **[docs/TOOLING.md](docs/TOOLING.md)** — the MCP servers, plugins, and skills to
  install per role, with verified install commands.

---

## Repository layout

```
claude-crew/
├── CLAUDE.md                  # the orchestrator (engineering manager)
├── PROJECT.template.md        # copy → PROJECT.md, fill per project
├── README.md
├── .claude/
│   ├── agents/                # the 14 specialist subagents
│   ├── commands/              # /onboard /feature /plan /review /harden /comply /ship /tests /deploy
│   ├── skills/                # the taste library — 9 anti-slop design skills
│   ├── scripts/               # validate.sh (Stop gate) + pre-pr-gate.sh (blocks red PRs)
│   └── settings.json          # permissions + quality-gate hooks
├── .claude-plugin/            # plugin.json + marketplace.json (Option C)
├── docs/                      # ENGINEERING, WORKFLOW, TESTING, WORKTREES, COMMITS, TOOLING
├── scripts/
│   ├── install.sh             # copy the crew into an existing project
│   ├── update.sh              # pull crew updates into an installed project
│   └── build-plugin.sh        # assemble the plugin form into dist/
├── .mcp.json.example          # copy → .mcp.json, keep only what you use
└── .worktreeinclude.example   # git-ignored files to seed into new worktrees
```

---

## Customizing

- **Model tiers** — each agent's `model:` (opus/sonnet/haiku/inherit) is set for a
  sensible cost/quality balance. Change per your budget; `inherit` follows the
  session model.
- **Add specialists** — drop a new `.claude/agents/<role>.md` (e.g. a
  language-specific expert). Pull ready-made ones from the marketplaces in
  `docs/TOOLING.md` (e.g. `wshobson/agents`).
- **Permissions & gates** — tune `.claude/settings.json` (what's auto-allowed vs.
  asked) and flip the validation gate to blocking once your suite is green.
- **Per-project rules** — everything stack- or policy-specific lives in
  `PROJECT.md`, never in the agents. That's what keeps the crew reusable.

---

## Design principles

1. **Technology-agnostic.** Agents detect the stack from the repo and fetch
   current docs (Context7); they never hardcode a framework.
2. **One source of project truth.** `PROJECT.md` is the only file you edit per
   project; the crew adapts around it.
3. **Verify, then claim.** Nothing is "done" until the gate is green and it's been
   run — reported honestly, with evidence.
4. **Human holds the wheel on irreversible actions.** Commits, pushes, deploys,
   and production changes need explicit authorization by default.

MIT licensed. Built to grow — fork it and make the crew yours.
