# Tooling — Skills, Plugins & MCP Servers per Role

> What to install to give each agent real capabilities. Everything here is
> **optional and additive** — the crew works with zero MCP servers, but these
> turn agents from "reasoning about your stack" into "operating on it."
>
> Verified against live sources as of mid-2026. Items marked **⚠︎ verify** need a
> final check of the exact command/env var in the upstream README before you wire
> them in. Install only what a project actually uses — don't bloat context with
> servers you won't call.

## How the three extension types differ

- **MCP servers** give agents *tools* to act on external systems (a browser, a
  database, GitHub, a scanner). Configure in `.mcp.json` (project) or via
  `claude mcp add …`.
- **Plugins** bundle agents + skills + commands + hooks + MCP servers behind one
  install. Add a marketplace, then `/plugin install`.
- **Skills** are model-invoked instruction packs (`SKILL.md`) that load on demand.

## 0. Universal — install for every project

| Tool | What it does | Install |
|---|---|---|
| **Context7 MCP** | Injects current, version-specific library docs so agents don't code from stale memory. Used by the whole crew. | `claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp` (add `--api-key <key>` for higher limits; repo: `upstash/context7`) |
| **Official Anthropic marketplace** | First-party plugins for GitHub/GitLab/Sentry/Supabase/Vercel/Figma, security-guidance, commit-commands, pr-review-toolkit. | Usually preloaded; else `/plugin marketplace add anthropics/claude-plugins-official` |
| **`security-guidance` plugin** | Pattern-matches every edit for ~25 high-risk classes (injection, secrets, unsafe eval/exec) and tells Claude to fix in-session. Free. | `/plugin install security-guidance@claude-plugins-official` |
| **`/security-review`** | Built-in command: security-reviews all pending changes. | Ships with Claude Code — just run `/security-review` |

## 1. Per-role recommendations

### frontend-engineer
| Tool | Why | Install |
|---|---|---|
| **shadcn Registry MCP** | Browse/search/install components & blocks by name across registries. | `npx shadcn@latest mcp init --client claude` |
| **Chrome DevTools MCP** | Live Chrome: performance traces, network, source-mapped console — runtime debugging & Core Web Vitals. | `claude mcp add chrome-devtools -- npx chrome-devtools-mcp@latest` |
| **Playwright MCP** | Drive a real browser via the a11y tree (no vision) to click through and verify UI. | `claude mcp add playwright -- npx @playwright/mcp@latest` |
| **Storybook MCP** | Exposes component metadata/stories/props so agents reuse components. Needs Storybook 10.3+. | Add `@storybook/addon-mcp`; connect the dev-server `/mcp` endpoint ⚠︎ verify |

### designer
| Tool | Why | Install |
|---|---|---|
| **Figma MCP (official, remote)** | Pull design context, variables, and screenshots into code (design-to-code). | `claude mcp add --scope user --transport http figma https://mcp.figma.com/mcp` |
| **Figma Dev Mode (local)** | Same, via the desktop app in Dev Mode. | `claude mcp add --transport http figma-desktop http://127.0.0.1:3845/mcp` (toggle "Enable desktop MCP server") |
| **Figma-Context-MCP (Framelink)** | Community REST-API alternative; works without a Dev Mode seat. | `npx figma-developer-mcp --figma-api-key=<key> --stdio` (repo `GLips/Figma-Context-MCP`) |
| **shadcn Registry MCP** | Map designs to the actual component library. | see frontend-engineer |
| **canva / cloudinary / adobe-for-creativity** | Asset & media workflows (official plugins). | `/plugin install <name>@claude-plugins-official` |

Anti-slop taste skills — bundled in `.claude/skills/` (also shipped in the plugin
build). The designer agent is required to load these before visual work; sources
for updating them. Vendored under their own licenses — see
[`THIRD_PARTY_LICENSES.md`](../THIRD_PARTY_LICENSES.md). **`impeccable`** ships
more than a vocabulary: a local live-edit server (`scripts/live*.mjs`) and a
hook installer (`scripts/hook-admin.mjs`) that can register PostToolUse/Stop
hooks into `.claude/settings.local.json` and other tools' hook configs — treat
its updates like a dependency bump, and run
`scripts/vendor-skills.sh` afterward (it re-normalizes the `.agents/skills/` →
`.claude/skills/` paths every `npx skills add/update` reintroduces). All nine
vendored skills are hash-tracked in `skills-lock.json`; run
`.claude/scripts/verify-skills.sh` to check for drift.

| Skill(s) | Source | Update |
|---|---|---|
| `impeccable` | [impeccable.style](https://impeccable.style/) — design vocabulary, 45 slop-detection rules, 23 design commands | `npx skills add pbakaus/impeccable && scripts/vendor-skills.sh` |
| `design-taste-frontend`, `high-end-visual-design`, `minimalist-ui`, `redesign-existing-projects` | [tasteskill.dev](https://www.tasteskill.dev/) — anti-slop framework, brief inference, audit-first redesigns | `npx skills add Leonxlnx/taste-skill --skill <name>` |
| `emil-design-eng`, `review-animations`, `animation-vocabulary` | [emilkowal.ski](https://emilkowal.ski/) (Design Engineer at Linear, ex-Vercel; animations.dev, Sonner, Vaul) | `npx skills add emilkowalski/skills` |
| `ui-ux-pro-max` | [ui-ux-pro-max-skill.nextlevelbuilder.io](https://ui-ux-pro-max-skill.nextlevelbuilder.io/) — 67 styles, 96 palettes, 57 font pairings | `npx skills add nextlevelbuilder/ui-ux-pro-max-skill --skill ui-ux-pro-max` |

### qa-engineer
| Tool | Why | Install |
|---|---|---|
| **Cypress** | Default e2e runner for the core-flow specs the pre-PR gate runs (`docs/TESTING.md` §4). | `npm i -D cypress` → specs in `cypress/e2e/`, author with `npx cypress open`, gate with `npx cypress run` |
| **Playwright MCP** | E2E & interaction automation via a11y snapshots. | `claude mcp add playwright -- npx @playwright/mcp@latest` |
| **playwright-axe-mcp** | WCAG 2.0/2.1 scans via Playwright + axe-core; re-tests after fixes. | Local build only (repo `PashaBoiko/playwright-axe-mcp`) ⚠︎ verify |
| **Chrome DevTools MCP** | Runtime/perf debugging during test triage. | see frontend-engineer |
| **code-review / coderabbit / codspeed** | Static analysis (40+ analyzers) and benchmark/flamegraph plugins. | `/plugin install <name>@claude-plugins-official` |

### backend-engineer & database-architect

Every install command below was web-verified and adversarially re-checked
against live npm/PyPI/GitHub/vendor docs. Pick the one row that matches the
project's datastore — plus **Context7** (universal) for exact ORM/engine syntax.
Sensible defaults for most projects: **DBHub** (any SQL engine) or the
engine-specific server, plus **Prisma/Drizzle MCP** if that ORM is in use.

**Core — engine-agnostic**
| Tool | Why | Install |
|---|---|---|
| **DBHub** (`@bytebase/dbhub`) | One gateway for Postgres, MySQL, MariaDB, SQL Server, SQLite — swap the `--dsn` scheme per engine. Needs Node ≥ 22.5. | `claude mcp add dbhub -- npx -y @bytebase/dbhub@latest --transport stdio --dsn "postgres://user:pass@host:5432/db"` (read-only is per-tool TOML config — also connect with a read-only DB user) |
| **Prisma MCP (local)** | Prisma migrations, Studio, Prisma Postgres provisioning. Built into Prisma CLI 6.6+. | `claude mcp add prisma -- npx -y prisma mcp` |

**Relational engines**
| Tool | Why | Install |
|---|---|---|
| **Postgres MCP Pro** (crystaldba) | Best Postgres server: `EXPLAIN` analysis, index tuning, health checks; access modes. | `claude mcp add postgres --env DATABASE_URI="postgresql://user:pass@host:5432/db" -- uvx postgres-mcp --access-mode=restricted` |
| **Postgres reference server** | ⚠️ **Archived & has an unpatched SQL-injection flaw — avoid.** Use Postgres MCP Pro or DBHub instead. | *(deprecated: `@modelcontextprotocol/server-postgres`)* |
| **MySQL/MariaDB** (community) | List/read/query MySQL & MariaDB. Note the **underscored** entrypoint. | `claude mcp add mysql -- uvx mysql_mcp_server` (env: `MYSQL_HOST/USER/PASSWORD/DATABASE`) |
| **SQLite reference server** | Query a local SQLite file. Archived but still runs; DBHub (`sqlite://`) is the maintained path. | `claude mcp add sqlite -- uvx mcp-server-sqlite --db-path /path/db.sqlite` |
| **SQL Server / Azure SQL** (Data API Builder) | Microsoft's production MCP via DAB (also PG/MySQL/Cosmos). | `dab start --mcp-stdio` (after `dab init`/`dab add` config; DAB v2.0) |

**ORM / query-layer**
| Tool | Why | Install |
|---|---|---|
| **Prisma MCP (remote)** | Manage Prisma Postgres (create/list, connection strings, backups, SQL). | `claude mcp add --transport http prisma https://mcp.prisma.io/mcp` |
| **Drizzle Kit MCP** (official) | Migration lifecycle (generate/push/check/up/pull). **Pre-release — must pin `@rc`.** | `claude mcp add drizzle -- npx -y drizzle-kit@rc mcp` ⚠︎ verify |
| **drizzle-mcp** (community) | Adds raw SQL execution + schema introspection (SQLite/Postgres). | `claude mcp add drizzle -- npx -y github:defrex/drizzle-mcp ./drizzle.config.ts` |

**NoSQL & other stores**
| Tool | Why | Install |
|---|---|---|
| **MongoDB** (official) | Query/manage MongoDB + Atlas. | `claude mcp add mongodb --env MDB_MCP_CONNECTION_STRING="mongodb://localhost:27017/db" -- npx -y mongodb-mcp-server@latest --readOnly` |
| **Redis** (official) | Manage/search Redis (strings…streams, vectors). | `claude mcp add redis -- uvx --from redis-mcp-server@latest redis-mcp-server --url redis://localhost:6379/0` |
| **ClickHouse** (official) | SQL over ClickHouse Cloud/self-hosted; read-only by default. | `claude mcp add clickhouse --env CLICKHOUSE_HOST=<h> --env CLICKHOUSE_USER=<u> --env CLICKHOUSE_PASSWORD=<p> -- uv run --with mcp-clickhouse --python 3.10 mcp-clickhouse` |
| **Neo4j Cypher** (Neo4j Labs) | Run Cypher read/write. Labs (no SLA); official `neo4j/mcp` runs via `python -m neo4j_mcp_server`. | `claude mcp add neo4j --env NEO4J_URI=bolt://localhost:7687 --env NEO4J_USERNAME=neo4j --env NEO4J_PASSWORD=<pw> -- uvx mcp-neo4j-cypher@0.6.0 --transport stdio` |
| **Elasticsearch** (official) | Query indices. **Deprecated** in favor of Elastic Agent Builder MCP. | `claude mcp add elasticsearch --env ES_URL=... --env ES_API_KEY=... -- npx -y @elastic/mcp-server-elasticsearch` |

**Serverless DB platforms** (hosted, OAuth/API-key)
| Tool | Why | Install |
|---|---|---|
| **Supabase** (hosted remote — recommended) | Manage DB, run SQL, schemas, edge functions, branches. Scope via URL params. | `claude mcp add --transport http supabase https://mcp.supabase.com/mcp` then `/mcp` to auth. Harden: `…/mcp?read_only=true&project_ref=<ref>` |
| **Supabase** (local stdio — legacy) | Pre-hosted path; still published. Flags may have shifted in v0.8+. | `claude mcp add supabase --env SUPABASE_ACCESS_TOKEN=<pat> -- npx -y @supabase/mcp-server-supabase@latest --read-only --project-ref=<ref>` ⚠︎ verify |
| **Neon** | Manage Neon Postgres projects/branches, run SQL. | `claude mcp add --transport http neon https://mcp.neon.tech/mcp` then `/mcp` |
| **PlanetScale** | Orgs, databases, branches, schema, Insights. | `claude mcp add --transport http planetscale https://mcp.pscale.dev/mcp/planetscale` then `/mcp` |
| **Turso / libSQL** | Query local Turso/SQLite-compatible DBs (CLI-built). | `claude mcp add my-db -- tursodb ./path/db.db --mcp` |
| **Convex** | Introspect tables/functions, run queries. | `claude mcp add convex -- npx -y convex@latest mcp start` |
| **CockroachDB Cloud** | Schemas, query plans, queries; read-only by default. | `claude mcp add cockroachdb-cloud https://cockroachlabs.cloud/mcp --transport http --header "mcp-cluster-id: <id>"` |
| **Upstash** | Manage Upstash Redis/QStash/Workflow. | `claude mcp add --scope user upstash -- npx -y @upstash/mcp-server@latest --email <email> --api-key <key>` |

> **DB safety:** connect with a dedicated **read-only, least-privilege** user and
> enable each server's read-only mode for exploration. Run migrations through the
> project's own migration tool against a **local/branch DB first** — never point
> them at production. Production writes are an explicit, human-authorized step.
>
> *Omitted (no official MCP as of mid-2026): Xata — use a generic Postgres MCP
> against its connection string. Oracle's MySQL MCP ships only placeholder
> packages (run from source). The archived reference Postgres/SQLite servers are
> unmaintained.*

### devops-engineer
| Tool | Why | Install |
|---|---|---|
| **GitHub MCP (official, remote)** | Repos, PRs, issues, Actions, code search. | `claude mcp add --transport http github https://api.githubcopilot.com/mcp` then `/mcp` to auth |
| **Vercel MCP** | Manage projects/deployments; search Vercel docs. | `claude mcp add --transport http vercel https://mcp.vercel.com` then `/mcp` |
| **Sentry MCP** | Query issues/events/traces; Seer root-cause. | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` then `/mcp` |
| **AWS MCP servers** | API, Docs, IaC (CDK/CloudFormation), Pricing, Cost. | `claude mcp add awscore -- uvx awslabs.core-mcp-server@latest` (monorepo `awslabs/mcp`) |
| **Terraform MCP (HashiCorp)** | 35+ IaC tools; live registry docs. Prefer over the deprecated awslabs Terraform server. | Docker `hashicorp/terraform-mcp-server` → `claude mcp add --transport http terraform http://localhost:8080/mcp` |
| **Kubernetes MCP** | Pods/deploys/services/logs; Helm. | `claude mcp add kubernetes -- npx -y mcp-server-kubernetes` (repo `Flux159/mcp-server-kubernetes`) |
| **`devops-toolkit` plugin** | Bundles AWS/GCP/Datadog/Sentry MCPs + `/incident`, `/deploy`, `/rollback`. | official marketplace ⚠︎ verify exact slug |

> AWS note: `awslabs.cdk-mcp-server` and `awslabs.terraform-mcp-server` are
> **deprecated** — use the unified **AWS IaC MCP** and **HashiCorp Terraform MCP**.

### security-engineer & reviewer-security
| Tool | Why | Install |
|---|---|---|
| **Semgrep MCP** | SAST — run Semgrep rules for vulnerabilities. | `claude mcp add semgrep -- uvx semgrep-mcp` (repo `semgrep/mcp`) |
| **Snyk MCP** | SCA + SAST + IaC/container scanning (CLI-native). | `claude mcp add snyk -- snyk mcp -t stdio` (Snyk CLI v1.1296.2+) |
| **Trivy MCP** | Vuln + misconfig scanning of fs/images/repos. | `trivy plugin install mcp` → `trivy mcp` (early-stage) |
| **OSV** | Dependency CVE lookups (OSV.dev). | Google `osv-scanner` built-in MCP, or `StacklokLabs/osv-mcp` (community) |
| **GitGuardian MCP** | Secret detection/remediation (600+ types). | Hosted: point client at `https://mcp.gitguardian.com/mcp` (OAuth) |
| **`/security-review` + GitHub Action** | Diff-aware SAST in-session and on PRs. | Built-in command; Action: `anthropics/claude-code-security-review` |

> **Caveat:** the security-review Action is **not hardened against prompt
> injection** — run it only on trusted PRs.

### copywriter
| Tool | Why | Install |
|---|---|---|
| **LanguageTool MCP** | Grammar/style across 25+ languages (useful for non-English-primary UIs). Needs LanguageTool **Pro**. | `npx @dpesch/languagetool-mcp-server` (`LT_USERNAME` + `LT_API_KEY`) |
| **Vale (CLI, not MCP)** | Config-driven prose/style-guide linter; enforce an editorial style guide in CI. | `brew install vale`; agent runs it via Bash. No MCP needed. |
| **readability-mcp** | Flesch-Kincaid/ARI readability metrics. Early-stage. | `pip install readability-mcp` ⚠︎ verify |

### seo-aeo-specialist
| Tool | Why | Install |
|---|---|---|
| **Google Search Console MCP** | Query performance (queries/pages/CTR), indexing, sitemaps. | `npx -y mcp-server-gsc` (`GOOGLE_APPLICATION_CREDENTIALS` service-account JSON; repo `ahonn/mcp-server-gsc`) |
| **Google Analytics (GA4) MCP (official)** | Chat with GA4 data — reports, dimensions. | `pipx run analytics-mcp` (repo `googleanalytics/google-analytics-mcp`) |
| **DataForSEO MCP (official)** | SERP, keywords, backlinks, on-page, domain analytics. | `npx dataforseo-mcp-server@latest` (`DATAFORSEO_USERNAME`/`_PASSWORD`) |
| **schema-org-mcp** | Generate + validate JSON-LD against schema.org. | `npx schema-org-mcp` (repo `Theycallmeholla/schema-org-mcp`) |
| **Lighthouse / PageSpeed MCP** | Core Web Vitals + perf/SEO/a11y audits. | `npx lighthouse-mcp-server` (repo `adamsilverstein/lighthouse-mcp-server`) ⚠︎ verify env var |
| **Semrush (hosted) / Plausible MCP** | Competitive data / privacy-first analytics. | Semrush: `https://mcp.semrush.com/v1/mcp`; Plausible: `getsentry/plausible-mcp` |
| **`claude-seo` plugin** | 25 sub-skills + 18 sub-agents (technical SEO, E-E-A-T, schema, GEO/AEO). No required MCPs. | `/plugin marketplace add AgriciDaniel/claude-seo` → `/plugin install claude-seo@…` |
| **`claude-seo-ai` plugin** | AEO/GEO-focused two-axis audit (Search + AI visibility). | `/plugin marketplace add Hainrixz/claude-seo-ai` → `/plugin install …` |

### data-compliance-officer
| Tool | Why | Install |
|---|---|---|
| **Playwright MCP** | Load the real pages and verify cookie/consent behavior empirically — which cookies fire before consent, whether reject works. | see frontend-engineer |
| **Web search / WebFetch** | Verify current regulation requirements and regulator guidance (GDPR/ePrivacy, CCPA, LGPD…) instead of citing from memory — rules and thresholds change. | built into Claude Code |
| **DB MCP (read-only)** | Walk the actual schema to build the data map from evidence (what personal data exists, where). | reuse the database-architect server, read-only |

> **Caveat:** no tool makes generated legal documents final. Everything the
> agent drafts (privacy policy, ToS, cookie policy) is a draft for review by
> qualified counsel in the relevant jurisdiction.

### orchestrator — ticketing (optional)
| Tool | Why | Install |
|---|---|---|
| **Notion MCP (official, hosted)** | Powers the optional kanban ticket layer (`docs/TICKETS.md`): `/board` creates the board; `/feature` `/bug` `/spike` `/epic` file cards; `/work` reads Dev Ready tickets and moves cards. | `claude mcp add --transport http --scope user notion https://mcp.notion.com/mcp`, then `/mcp` to complete the OAuth |

> **Caveats that shape the crew's usage** (already baked into `docs/TICKETS.md`):
> Notion's SQL and view-query tools need a Business-plan workspace with Notion
> AI — the crew never depends on them (scoped-search + fetch fallback,
> verified on a non-Business workspace). The installed server's
> tool-name prefix varies, so commands reference tools by function, never by
> full name. Before batch `/work`, allowlist your Notion server's tools in
> `.claude/settings.local.json` permissions or unattended runs stall on
> permission prompts.

## 2. Plugin marketplaces worth adding

| Marketplace | What it offers | Add | Verdict |
|---|---|---|---|
| **anthropics/claude-plugins-official** | First-party MCP integrations, security-guidance, pr-review-toolkit, commit-commands. | preloaded / `/plugin marketplace add anthropics/claude-plugins-official` | **Use first, always.** Safest, lowest-friction. |
| **wshobson/agents** | 88 plugins / 194 agents / 158 skills / 106 commands; cross-harness, actively maintained. | `/plugin marketplace add wshobson/agents` then install by plugin | **Add & cherry-pick.** Highest-signal single source — don't dump all, pick plugins. |
| **anthropics/claude-plugins-community** | Auto-validated third-party plugins. | `/plugin marketplace add anthropics/claude-plugins-community` | Good for vetted extras. |
| **VoltAgent/awesome-claude-code-subagents** | 154+ categorized subagent definitions. | browse; copy individual agents | **Reference & selectively copy** role ideas. |
| **hesreallyhim/awesome-claude-code** | Curated index of the whole ecosystem (not installable). | bookmark | **The map** — start here to find repos worth installing. |

## 3. This crew vs. public collections

The agents in this repo are **custom-built, technology-agnostic, and wired to a
shared workflow + git protocol**. Public collections (wshobson, VoltAgent) are
excellent for *discovering* narrow, language-specific experts you can drop in
alongside — e.g. a `rust-pro` or `kubernetes-specialist` for a specific project.

Rule of thumb:
- **Keep custom** the roles that encode *your* standards and workflow (the crew
  here, plus anything a project's `PROJECT.md` defines).
- **Pull from public marketplaces** for deep, narrow specialists a given project
  needs and that no general role covers.
- **Use official plugins** for all the boring integration plumbing (GitHub,
  Sentry, Supabase, security review) — never build those custom.

## 4. Install cheat-sheet (copy/paste)

```bash
# Universal
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
/plugin install security-guidance@claude-plugins-official

# Frontend / Design / QA
claude mcp add playwright       -- npx @playwright/mcp@latest
claude mcp add chrome-devtools  -- npx chrome-devtools-mcp@latest
npx shadcn@latest mcp init --client claude
claude mcp add --transport http figma https://mcp.figma.com/mcp

# Backend / DBA (example: Supabase, read-only)
claude mcp add supabase -- npx -y @supabase/mcp-server-supabase@latest --read-only

# DevOps
claude mcp add --transport http github  https://api.githubcopilot.com/mcp
claude mcp add --transport http vercel  https://mcp.vercel.com
claude mcp add --transport http sentry  https://mcp.sentry.dev/mcp

# Security
claude mcp add semgrep -- uvx semgrep-mcp
claude mcp add snyk    -- snyk mcp -t stdio

# Marketplaces
/plugin marketplace add wshobson/agents
```

> After adding MCP servers, restart Claude Code (or `/reload-plugins` for
> plugins) and run `/mcp` to authenticate any OAuth-based remote servers. Scope
> secrets via env vars — never hardcode keys in `.mcp.json` that you commit.

`.mcp.json.example` ships with only `context7` — every key in that file is a
live server Claude Code will try to launch (a `"//name"` key is NOT a
comment, it's still an entry). Rename/paste whichever of these you need
straight into your `.mcp.json`'s `mcpServers` object:

```jsonc
"playwright": {
  "command": "npx",
  "args": ["@playwright/mcp@latest"]
},

"supabase": {
  "type": "http",
  "url": "https://mcp.supabase.com/mcp?read_only=true&project_ref=${SUPABASE_PROJECT_REF}"
},

"github": {
  "type": "http",
  "url": "https://api.githubcopilot.com/mcp"
},

"sentry": {
  "type": "http",
  "url": "https://mcp.sentry.dev/mcp"
},

"notion": {
  "type": "http",
  "url": "https://mcp.notion.com/mcp"
},

"semgrep": {
  "command": "uvx",
  "args": ["semgrep-mcp"]
}
```
