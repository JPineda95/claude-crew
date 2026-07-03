# PROJECT.md

> Copy this file to `PROJECT.md` and fill it in for the specific project. This is
> the one place the crew learns your stack and rules — the agents read it before
> acting. Delete the guidance in *italics* as you go. Keep it short and true;
> stale context is worse than none.

## 1. What this project is
*One paragraph: what the product does, who it's for, and the current stage
(prototype / MVP / production).*

## 2. Stack
*The crew detects most of this from the code, but stating it removes guesswork.*

- **Language(s) & runtime:**
- **Framework(s):**
- **Datastore:**
- **Styling / UI library:**
- **Auth:**
- **Hosting / platform:**
- **Key third-party services:** *(payments, email, analytics, etc.)*
- **Primary language/locale of the UI:** *(e.g. Spanish — write user-facing copy
  natively in this language)*

## 3. Commands
*The real commands — the crew must never invent these.*

- **Install:** `…`
- **Dev server:** `…`
- **Validation gate (run before every commit):** `…` *(e.g. `npm run check`, or
  `test && lint && typecheck && build` — this is what "the validation gate" means
  throughout `docs/`)*
- **Test:** `…`
- **Lint / format:** `…`
- **Build / typecheck:** `…`
- **Migrations (up/down):** `…`

## 4. Testing
*`docs/TESTING.md` governs how the crew writes and runs tests; this section
declares this project's specifics. The pre-PR hook blocks every PR until the
gate commands below exist and pass.*

- **Unit/integration runner & command:** `…` *(e.g. Vitest — `npm run test`)*
- **E2E tool & command:** `…` *(default for web UIs: Cypress — `npx cypress run`;
  CLI/API projects use the equivalent top-level harness, or state `none —
  covered at integration layer` explicitly)*
- **E2E smoke subset (runs before every PR):** `…` *(e.g.
  `npx cypress run --spec "cypress/e2e/smoke/**"`)*
- **CI gate:** `…` *(e.g. GitHub Actions — `.github/workflows/gate.yml` re-runs
  the validation gate on every PR, required check on the integration branch;
  `none yet` until wired — `docs/TESTING.md` §8)*
- **Core flows** *(the ≈5–10 user journeys that must never break — each one gets
  an e2e spec, kept current by `qa-engineer`)*:
  1. *e.g. sign up → onboard → land on dashboard*
  2. *e.g. search → book → confirmation email*
- **TDD policy:** `default` *(failing tests first for anything with logic —
  `docs/TESTING.md` §3)*
- **Coverage focus:** *(optional: a floor %, or the hotspots that must stay covered)*
- **Test data & env:** *(how e2e seeds/cleans data; test DB/URL; secrets source)*

## 5. Git & integration
- **Integration branch** *(what `<integration-branch>` means in the docs —
  never the production branch: the crew NEVER commits to `main`. If the repo
  only has `main`, the crew creates `dev` off it on first run, pushes it, and
  records it here)*: `dev`
- **Production branch** *(what `/deploy` merges the integration branch into —
  only a human-run `/deploy` ever moves it)*: `main`
- **Branch naming:** `<type>/<slug>` *(e.g. `feat/per-location-availability`)*
- **Ship mode:** `pr` *(default: each finished unit of work is committed on its
  own branch, pushed, and opened as a PR — the human reviews and merges. How
  many crew PRs may be open at once is the open-PR policy, `docs/WORKFLOW.md`
  §8. Set to `ask` to have the crew prepare commits and wait for approval
  instead. Deploys always need authorization.)*
- **Autonomous deploy?** `no`

## 6. Conventions & non-negotiables
*Project-specific rules that override defaults. Examples:*
- *Code style specifics (indent, quotes) beyond what the formatter enforces.*
- *"All timezone logic flows through `src/lib/timezone-service.ts`."*
- *"Server actions only — no REST layer."*
- *"RLS on every table; users access only their own rows."*

## 7. Architecture notes
*A few sentences or a small map: routing model, data-flow pattern, where the
important code lives. Enough that `architect` and reviewers orient fast.*

## 8. Tooling installed
*Which MCP servers / plugins from `docs/TOOLING.md` this project uses, so agents
know what tools they can call.*
- *e.g. Supabase MCP (read-only), Playwright MCP, Context7, security-guidance.*

## 9. Environment
*Required env vars (names only — never values). Where secrets live. Which
git-ignored files a fresh worktree needs (mirror these in `.worktreeinclude`).*

## 10. Data & compliance
*What `data-compliance-officer` needs to know. The applicable law follows your
users, not your company address.*

- **Markets / user jurisdictions:** *(e.g. EU (Spain), Costa Rica, US-California)*
- **Personal data collected:** *(categories: identity, contact, payment, health,
  location, behavioral/analytics…)*
- **Third parties that receive user data:** *(analytics, email, payments, hosting
  region…)*
- **Where the legal docs live:** *(privacy policy, ToS, cookie policy — routes or
  files)*
- **Known constraints:** *(e.g. "clients' end-customers are also data subjects",
  "no minors", "health data → special category")*

## 11. Out of scope / known constraints
*Things not to touch, decisions already made, deliberate tech debt, deadlines,
budget limits.*

## 12. Ticketing (optional — Notion kanban)
*Written by `/board`; governed by `docs/TICKETS.md`. Leave `Ticketing: none` (or
delete this section) to run the crew ticketless — `/work <description>` is the
full lifecycle either way.*

- **Ticketing:** `none` *(`notion` once `/board` has created the board)*
- **Board section page:** *(Notion page URL)*
- **Tickets database:** *(Notion database URL)*
- **Data source id:** *(`collection://<uuid>` — from `/board`)*
- **Ticket prefix:** *(e.g. `KANI` — set by `/board` at creation, **do not
  edit**: Notion fixes it at the database, and branches/PRs/resume searches key
  on it)*
- **Status property:** `Status`
- **Max parallel tickets:** `3` *(batch `/work` wave cap — counts tickets, not
  agents; see `docs/WORKTREES.md` on the agent ceiling)*
