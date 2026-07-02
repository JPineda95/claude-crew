---
description: Prepare atomic, well-messaged commits for the current work (asks before committing).
argument-hint: "[optional context or issue reference]"
allowed-tools: Bash(git status), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git add:*)
---

Prepare the current work for shipping per `docs/COMMITS.md`. Extra context:
$ARGUMENTS

Working tree:

!`git status --short && echo "---" && git diff --stat`

Steps:

1. **Gate first.** Confirm the validation gate is green (tests + lint + typecheck
   + build per `PROJECT.md`). If it isn't, stop and report — do not commit broken
   code.
2. **Confirm the branch.** If on the integration/default branch, propose a
   feature branch name (`<type>/<slug>`) and create it before committing.
3. **Group into atomic commits.** Split the diff into logical, self-contained
   commits (one concern each). For each, write a Conventional Commit message with
   a body that explains **why** — the reasoning and trade-offs, not a restatement
   of the diff. Add `Refs:`/`Closes:` and a `Co-authored-by:` trailer.
4. **Show the plan.** Present the proposed branch, the commit split, and each full
   commit message for review.
5. **Wait for authorization.** Do **not** run `git commit` or `git push` until the
   user approves, unless `PROJECT.md` explicitly opts into autonomous commits.
   Pushing and deploying always require explicit authorization.
6. Never force-push a shared branch; `--force-with-lease` only, on your own branch.
