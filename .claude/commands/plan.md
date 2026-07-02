---
description: Have the architect design and plan a change without implementing it.
argument-hint: <what to plan>
---

Spawn the `architect` agent to produce a Technical Design Brief for the following,
then stop — do **not** implement.

**Task:** $ARGUMENTS

The brief must include: problem & goal, constraints & non-goals, the chosen
approach with key interfaces/contracts, alternatives considered, risks &
unknowns, and an execution plan (ordered tasks tagged with owning agents,
dependencies, and a hot-file map). Pull in `designer`, `database-architect`, or
`security-engineer` for input if the design needs it.

When the brief is back, present it and ask whether to proceed to implementation
(e.g. via `/feature`).
