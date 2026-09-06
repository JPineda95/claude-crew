---
description: "Read-only tech-debt audit — dead code, vulnerabilities, refactor candidates — ranked report plus optional ticket filing."
argument-hint: "[optional focus: a path, module, or area — blank for the whole repo]"
---

Run a read-only tech-debt audit on: **$ARGUMENTS** — if no focus was given,
audit the whole repository.

**Hard rule: this command changes nothing.** No file writes, no branches, no
commits, no dependency installs or upgrades, no fixes "while we're here".
Every spawned agent gets that same mandate verbatim. Scanners run only if
already available in the repo or on PATH (`npx --no-install`, never a fresh
install); when a scanner is missing, fall back to grep/`git log` heuristics
and say so. The only outputs are the report in chat and, if the user opts in
at the end, tickets.

1. **Scope.** Read `PROJECT.md` (stack, core flows, constraints) and note the
   current HEAD — every finding cites `file:line` as of that commit. Restrict
   everything to the focus when one was given.
2. **Scan** — spawn three auditors **in parallel**, each read-only, each
   returning severity-tagged findings with evidence:
   - `reviewer-code-quality` — **dead & rotting code:** unused
     exports/files/dependencies (prefer an installed scanner — knip,
     ts-prune, depcheck, vulture, deptry — else import-graph greps),
     duplicated logic, commented-out blocks, stale TODO/FIXME/HACK markers
     (age via `git blame`), lint/type suppressions, complexity hotspots,
     and risky seams (auth, money, data mutations, external input) with no
     tests — flagged briefly; the deep coverage audit belongs to `/tests`.
   - `reviewer-security` — **vulnerabilities:** OWASP pass over the risky
     seams, secrets in the tree or git history, permissive configs, and
     dependency CVEs via the ecosystem's audit command (`npm audit`,
     `pip-audit`, `cargo audit`, …). Safe local scans only — never offensive
     tooling, never against systems you don't own.
   - `reviewer-architecture` — **refactor candidates:** drift from the
     codebase's own patterns, layering violations, god files/modules, tight
     coupling, churn hotspots (`git log` frequency × size), dependencies
     more than one major behind or deprecated/EOL, config or feature flags
     that no longer vary.
3. **Consolidate** — dedupe overlapping findings (keep the highest severity),
   then present one report:
   - a 3–5 line executive summary: overall debt posture and the top risks;
   - findings grouped **CRITICAL / WARNING / SUGGESTION**, each with
     evidence (`file:line`), why it costs (risk carried or drag on change),
     a concrete remediation, an effort tag (S/M/L), and the owning
     specialist;
   - a **quick wins** list: low-effort ≥ WARNING items worth a small batch;
   - anything deliberately excluded (generated code, vendored dirs) named.
4. **Offer tickets.** Ask which findings to file — default suggestion: every
   CRITICAL plus the quick-wins batch (one card) — using AskUserQuestion
   with multi-select when available. Then resolve ticketing mode per
   `docs/TICKETS.md` §9 rule 6 (this command's classic fallback: print the
   finished cards as markdown for the human to paste — the audit itself
   never needs a board):
   - One card per selected finding — related small items may merge into one
     card when they'd ship as one change. Category `Story` (`Bug` when the
     finding is a live defect or exploitable vulnerability), `Status:
     Backlog`, `Priority` mapped from severity (CRITICAL → High,
     WARNING → Medium, SUGGESTION → Low). Never set `Ticket ID`.
   - Body per `docs/TICKETS.md` §2.2, complete enough that `/work` can pick
     the card up cold: the evidence and remediation in `## Description` /
     `## Technical Details`, observable acceptance criteria (for dead-code
     removals: gate green and the removed symbols gone).
   - Batch creation per `docs/TICKETS.md` §9 rule 4; a Notion failure never
     blocks — fall back to the markdown cards.
5. **Report & stop.** List any ticket ids created and remind: a human
   triages Backlog → Dev Ready, then `/work <id>` pays the debt down. This
   command never fixes anything, never branches, and never moves a card
   past Backlog.
