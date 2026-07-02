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

## 4. Git & integration
- **Integration branch** *(what `<integration-branch>` means in the docs)*: `main`
- **Branch naming:** `<type>/<slug>` *(e.g. `feat/per-location-availability`)*
- **Autonomous commits?** `no` *(default: agents prepare commits and wait for
  human approval. Set to `yes` only if you want the crew to commit without asking
  — pushing/deploying still needs authorization.)*
- **Autonomous deploy?** `no`

## 5. Conventions & non-negotiables
*Project-specific rules that override defaults. Examples:*
- *Code style specifics (indent, quotes) beyond what the formatter enforces.*
- *"All timezone logic flows through `src/lib/timezone-service.ts`."*
- *"Server actions only — no REST layer."*
- *"RLS on every table; users access only their own rows."*
- *Testing policy (e.g. "TDD always; write failing tests first").*

## 6. Architecture notes
*A few sentences or a small map: routing model, data-flow pattern, where the
important code lives. Enough that `architect` and reviewers orient fast.*

## 7. Tooling installed
*Which MCP servers / plugins from `docs/TOOLING.md` this project uses, so agents
know what tools they can call.*
- *e.g. Supabase MCP (read-only), Playwright MCP, Context7, security-guidance.*

## 8. Environment
*Required env vars (names only — never values). Where secrets live. Which
git-ignored files a fresh worktree needs (mirror these in `.worktreeinclude`).*

## 9. Data & compliance
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

## 10. Out of scope / known constraints
*Things not to touch, decisions already made, deliberate tech debt, deadlines,
budget limits.*
