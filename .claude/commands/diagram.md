---
description: Map the architecture — refresh docs/ARCHITECTURE.md with Mermaid diagrams (system graph, core-flow sequences, data-model ERD).
argument-hint: "[optional: a subsystem, path, or flow to focus on — defaults to the whole system]"
allowed-tools: Bash(git rev-parse:*), Bash(git status), Bash(git log:*)
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

If `$ARGUMENTS` names a subsystem, path, or a single flow, focus the map there
instead of redrawing everything.

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
