# Designs & Design Tools — Optional Design-Layer Charter

> How the crew designs screens in a real design surface the human reviews:
> which tools, who does what, and how everything degrades when the tools aren't
> there. Normative: **MUST / SHOULD / MUST NOT** carry their RFC-2119 meanings.
> Companion to [WORKFLOW.md](./WORKFLOW.md) §1 (the Design phase) and the
> `designer` agent spec.
>
> **The design layer is optional.** Everything in this doc applies only when
> `PROJECT.md` §13 declares a design tool. Without it the crew runs exactly as
> before — `designer` writes specs into the repo and hands off.
>
> **The repo is the source of truth; design tools are a mirror.** `DESIGN.md`
> and the specs in git define the design system and every screen; the external
> tool is where a human *looks at* and *reacts to* screens. A design-tool
> failure MUST NEVER block an engineering step (§6). This is the same contract
> the ticket board makes in [TICKETS.md](./TICKETS.md).

## 1. The two tools (and the one deliberately left out)

| Tool | Role in the layer | Cost |
|---|---|---|
| **Claude Design** (claude.ai/design) | The **home**: a design-system project holding the app's component library and approved screens. Synced from the repo via Claude Code's built-in `DesignSync` tool; the human browses, comments, and prototypes there. | Included in a Claude Pro/Max subscription (research preview) |
| **Google Stitch** (MCP) | The **exploration engine**: generate screens from text, edit them, produce variants, and build a Stitch design system directly from the repo's `DESIGN.md`. The human picks directions in the Stitch UI. | Free (monthly generation quota / credits) |

A project MAY declare either tool, both, or none — they are independent. With
both, the flow is: **explore in Stitch → converge in the repo → mirror to
Claude Design.**

**Figma is deliberately not part of this layer for now** (decided 2026-07): its
MCP caps *read* tool calls at 6/month on the free Starter plan, and write-side
access is a free beta with usage-based pricing announced but unsettled — a
workflow keyed on it either breaks at the cap or silently acquires a seat cost.
Revisit when a human designer joins a project or Figma's MCP pricing settles.
Until then, agents MUST NOT route design work through Figma MCP tools even
when they are installed.

## 2. `DESIGN.md` — the design source of truth

A root-level **`DESIGN.md`** (beside `PROJECT.md`) is the single place the
project's design system lives as text:

- **Tokens:** color palette (with semantic names), type scale, spacing scale,
  radii, shadows, motion durations/easings.
- **Type & voice:** font families and weights in use, headline/body pairing,
  copy tone pointers (with `copywriter`).
- **Component inventory:** the reusable components that exist, their variants
  and states, and where they live in the code.
- **Art direction:** the distinctive point of view — layout rhythm, color
  stance, what this product's screens should *feel* like, and the anti-slop
  constraints that keep it from regressing to generic AI design.

Rules:

- `designer` MUST bootstrap `DESIGN.md` from the actual codebase (styling
  config, tokens, components) the first time a design task runs and the file
  is missing — extracted, not invented.
- Every converged design decision lands back in `DESIGN.md` in the same PR as
  the feature's spec. The file evolves like code; stale entries are bugs.
- The name and location are normative: Stitch's design-system import consumes
  a `DESIGN.md` upload verbatim, and agents key on the path.

## 3. Setup & config (`PROJECT.md` §13)

**Stitch** — install the MCP server under the name `stitch` (normative: the
`designer` agent's tool grants key on the `mcp__stitch__` prefix, so a
different server name silently disables the layer):

```bash
claude mcp add --scope user --transport http stitch \
  https://stitch.googleapis.com/mcp \
  --header "X-Goog-Api-Key: <your-stitch-api-key>"
```

Get the API key from your Stitch account settings (⚠︎ verify the current
source — Google has moved this between Labs and AI Studio). The key is a
secret: env/user scope only, never committed.

**Claude Design** — nothing to install. The built-in `DesignSync` tool ships
with Claude Code; the first call may prompt to add design scopes to the
claude.ai login (headless sessions authorize via `/design-login`). Create or
pick the design-system project with `DesignSync.list_projects` /
`create_project`, then record it in §13.

`PROJECT.md` §13 fields:

- **Designs:** `none` / `stitch` / `claude-design` / `both`
- **Stitch project:** the Stitch project id the app's screens live in
- **Claude Design project:** the design-system project name/id

## 4. Who does what

| Step | Actor |
|---|---|
| Bootstrap/maintain `DESIGN.md`, push the Stitch design system from it | Crew (`designer`) |
| Generate screens & variants for a surface (2–3 directions, not 10) | Crew (`designer`) |
| **Pick a direction** | **Human only — the taste gate** |
| Converge the pick into a repo spec + `DESIGN.md` updates | Crew (`designer`) |
| Mirror approved screens / component library to Claude Design | Crew (`designer`, via `DesignSync`) |
| Implement | Crew (`frontend-engineer`), **from the repo spec** |

Rules:

- **The taste gate is the human's** — the design-layer analog of the board's
  Backlog → Dev Ready triage. In interactive runs, `designer` presents the
  variants (Stitch links or screenshots) and waits for the pick. In
  **unattended/batch runs** the gate can't block: `designer` picks, records
  which variants were considered and why in the handoff, and the human vetoes
  at PR review — the PR description MUST link the alternatives.
- `frontend-engineer` implements from the spec and screenshots **in the repo**.
  Implementation MUST NOT depend on reading an external design tool at build
  time — that's how a quota or outage becomes a blocked feature.
- DesignSync writes follow its plan flow (read → `finalize_plan` →
  `write_files`) and are **incremental — one component/screen at a time, never
  a wholesale replace** of the remote project.

## 5. Where it hooks into the lifecycle

In WORKFLOW.md §1 (Design), when the feature has a UI surface and the layer is
configured: `designer` runs the exploration loop (§4) *inside* the Design
phase, and the resulting spec feeds Plan/Test-first exactly as before. After
ship, mirroring approved screens to Claude Design SHOULD ride along with the
feature's wrap-up, not become its own ceremony.

## 6. Degradation contract — never block engineering

1. **Two gates decide the mode** (same shape as TICKETS.md §9). Config gate:
   `PROJECT.md` §13 exists and isn't `none`. Tool gate: the declared tool
   responds — `mcp__stitch__*` tools present, or the `DesignSync` tool
   available. Config without tools → say so briefly, point to
   `docs/TOOLING.md`, fall back for this run.
2. **No config / no tools → classic behavior**, repo-only specs, zero mention
   of the design layer.
3. **Every external write: try once, retry once, move on.** Collect failures
   and end the run with "design mirror out of sync — re-sync next design
   task". The repo spec is complete on its own; the mirror catches up later.
4. **Quota exhaustion is not an error state.** On Stitch quota/credit errors:
   stop generating, report what was and wasn't explored, continue with
   repo-only wireframes and specs. MUST NOT retry-loop against a quota.
5. **Never push secrets or personal data into design tools.** Screens use
   realistic but fabricated content; real user data MUST NOT appear in
   prompts, uploads, or synced files.

## 7. Non-goals

Decided, not open for re-litigation:

1. **No Figma automation** while §1's exclusion stands.
2. **No pixel-parity guarantee** between a design tool's render and the
   implementation — the repo spec is what gets implemented and reviewed.
3. **No design-tool state in CI** — gates never call design tools.
4. **No marketing-asset production** (social images, decks) through this
   layer; it exists for product surfaces the crew ships.
5. **One repo ⇄ one Stitch project ⇄ one Claude Design project.** No
   cross-repo design hubs.
