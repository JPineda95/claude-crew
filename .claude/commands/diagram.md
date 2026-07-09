---
description: "Map the architecture — refresh docs/ARCHITECTURE.md with Mermaid diagrams (system graph, core-flow sequences, data-model ERD)."
argument-hint: "[optional focus — path:<dir> · flow:<name> · system · data; omit to map the whole system]"
allowed-tools: Bash(git rev-parse:*), Bash(git status:*), Bash(git log:*)
---

Produce or refresh the architecture map for: **$ARGUMENTS** — if no target was
given, map the whole system.

Spawn the `diagrammer` agent to reverse-engineer the current codebase and write
(or refresh) **`docs/ARCHITECTURE.md`** with, at minimum:

- a **system / component graph** (Mermaid `flowchart`) — components, boundaries,
  external systems, and what crosses each edge;
- a **`sequenceDiagram` per core flow** — the sequences the product lives on
  (auth, the primary create/checkout path, key jobs). If `docs/TESTING.md` lists
  e2e core flows, use that as the flow set;
- a **data-model ERD** (Mermaid `erDiagram`) from the real schema/migrations.

**Focus (`$ARGUMENTS`)** — omit it to map the whole system; otherwise narrow the
run so a large repo stays legible and refreshes stay cheap:

- `path:<dir>` — only the subsystem under that path and what it connects to (all
  three diagram families, scoped to it), e.g. `path:src/billing`.
- `flow:<name>` — only the `sequenceDiagram` for that one flow, e.g. `flow:checkout`.
- `system` — only the system / component graph.
- `data` — only the data-model ERD.
- anything else — a best-effort focus on whatever the free text names.

A focused run refreshes only the sections it covers and leaves the rest of
`docs/ARCHITECTURE.md` untouched (the `crew:diagram` markers preserve everything
else).

Rules for the run:

- **Document what exists, not what should.** Every node must trace to real code;
  unresolved wiring is marked `%% TODO: verify`, never guessed. Design decisions
  belong to `architect`, not here.
- **Refresh, don't clobber.** The generated body lives between
  `<!-- crew:diagram:start -->` / `<!-- crew:diagram:end -->` markers; a re-run
  replaces only what's inside and preserves any human-authored sections around it.
- **Zero dependency.** Mermaid is emitted as text and renders on GitHub, in
  Obsidian, and in VS Code as-is. This command is **read-only on application
  code** — it writes only `docs/ARCHITECTURE.md`.

When the agent returns, summarize what changed (diagrams added/updated, the
`Last mapped` sha, any `TODO: verify` gaps to confirm) and note how to view it:
render it on GitHub/Obsidian, or export images on demand with
`npx -y @mermaid-js/mermaid-cli -i docs/ARCHITECTURE.md -o docs/architecture.svg`
(no committed dependency). Run `/diagram` again after a batch of `/work` to keep
the map current.
