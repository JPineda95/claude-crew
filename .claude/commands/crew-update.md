---
description: "Pull crew updates into this project via crew-update.sh, then interactively walk any .crew-new merge conflicts."
argument-hint: "[optional: a branch/tag to sync instead of the released main, e.g. dev — sets CREW_REF]"
allowed-tools: Bash(git ls-remote:*), Bash(.claude/scripts/crew-update.sh:*), Bash(rm:*), Read, Write, Edit, Glob
---

Update this project's crew installation, then merge anything the sync
couldn't apply automatically. Optional ref to sync instead of the released
`main`: $ARGUMENTS (passed through as `CREW_REF`).

Steps:

1. **Compare versions first.** Read `.claude/crew-manifest`'s `# commit:`
   and `# ref:` lines — that's the installed version. If a `# remote:` line
   is present, run `git ls-remote <remote> <ref-or-main>` to show the
   upstream commit without downloading anything. Report both, and confirm
   with the user before syncing — skip the confirmation only when
   `$ARGUMENTS` makes it obvious they're already asking for a specific sync.
2. **Run the sync.** `.claude/scripts/crew-update.sh`, with `CREW_REF` set
   to `$ARGUMENTS` only if it was given (don't pass an empty `CREW_REF`).
   If it exits non-zero because of the downgrade guard (PR 1's protection —
   the installed content isn't an ancestor of the ref being synced), report
   the guard's message verbatim and **stop** — never retry with
   `--allow-downgrade` without the user's explicit go-ahead.
3. **Summarize the sync output in plain language**, not a raw log dump: how
   many files were updated in place (↑), added (+), removed (−), and kept
   with a merge copy (✎) — and which files those are.
4. **Walk each merge.** For every `<file>.crew-new` the sync dropped
   (including the friendlier pairings `CLAUDE.crew.md` → `CLAUDE.md` and
   `settings.crew.json` → `.claude/settings.json`):
   - Read both the local file and its `.crew-new` counterpart. There is no
     common-ancestor version available (only these two flat files) — judge
     mergeability from what each side actually did, not from diff line
     numbers alone (two independent additions can land on the "same line"
     in a naive diff without truly conflicting).
   - **Add/add (mergeable — the common case):** both sides independently
     *added* content (a new hook, a new permission rule, a new paragraph)
     with no shared pre-existing line changed to two different values.
     Propose a union merge that keeps both additions — local's addition
     first, then upstream's, unless one obviously must come first
     structurally (e.g. upstream added a new required JSON key that must sit
     in a specific position). Get explicit approval before writing; on
     approval, write the merged content to the real path and delete the
     `.crew-new` artifact.
   - **Edit/edit (a true conflict — rarer):** a line that existed in both
     versions was changed to two *different* values by each side (not two
     independent additions). Present both sides plus enough surrounding
     context to judge, and let the user choose or hand-edit — never guess
     which one wins, and never silently keep one side.
   - When genuinely unsure which case you're looking at, say so and default
     to presenting both sides — the cost of an unnecessary question is much
     lower than the cost of silently dropping one side's content.
5. **CI reminder.** If `docs/TESTING.md` or either gate script
   (`.claude/scripts/validate.sh`, `.claude/scripts/pre-pr-gate.sh`) was
   among the updated/added files, remind the user: `docs/TESTING.md` §8's
   same-PR sync rule means this project's `.github/workflows/gate.yml` (if
   it has one) may need a matching update before the next PR.
6. **Report.** What changed, what got merged and how, and anything still
   needing manual attention.
