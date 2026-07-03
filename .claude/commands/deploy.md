---
description: Promote the integration branch into the production branch (e.g. merge dev into main) and push. Running this command is the explicit human authorization to deploy.
argument-hint: "[optional release context]"
allowed-tools: Bash(git status), Bash(git fetch:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(git checkout:*), Bash(git switch:*), Bash(git pull:*), Bash(git merge:*), Bash(git push:*), Bash(git remote:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(gh pr list:*)
---

Promote the integration branch into the production branch per
`docs/WORKFLOW.md` §9. The human running `/deploy` **is** the explicit
authorization that deploys require (guardrail 4) — but it authorizes exactly
this promotion and nothing else. Extra context: $ARGUMENTS

Current state:

!`git fetch origin --quiet; git status --short --branch && echo "---" && git log --oneline -10`

Steps:

1. **Resolve the branches.** Integration and production branches come from
   `PROJECT.md` §5. If no production branch is configured, use the repo's
   default branch (`git remote show origin`). If they are the same branch,
   this project has no promotion step — stop and say so.
2. **Preflight.** The working tree must be clean — stop if it isn't (don't
   stash on the user's behalf). Then compare the remote branches:
   - `git log origin/<production>..origin/<integration> --oneline` is the
     release. If it's empty, there is nothing to deploy — stop and report.
   - `git log origin/<integration>..origin/<production> --oneline` must be
     empty. If production has commits the integration branch lacks (e.g. a
     hotfix), stop: merge production back into the integration branch first,
     re-run the gate there, then run `/deploy` again.
3. **Gate on the integration branch.** Check it out, pull, and run the
   validation gate (lint + full test suite + typecheck/build per `PROJECT.md`,
   plus the e2e smoke set when configured). If anything is red, stop and
   report — never promote a red integration branch.
4. **Promote.** Check out the production branch, pull, then
   `git merge --no-ff <integration-branch>` with a `chore(release): …`
   message whose body lists what ships (the commit subjects from step 2, plus
   any context from $ARGUMENTS). Push the production branch.
   - If the push is rejected by branch protection, don't fight it: open a
     release PR from the integration branch into the production branch with
     `gh pr create` (description = the shipped-changes list), report the URL,
     and stop — the human merges it.
   - A merge conflict here means step 2 was skipped or the remote moved —
     abort the merge (`git merge --abort`), stop, and report.
5. **Wrap up.** Switch back to the integration branch. Report the merge commit
   SHA and the list of shipped changes, and remind the human that whatever
   pipeline watches the production branch (Vercel, CI/CD) is now deploying —
   verifying the live deploy is on them / `devops-engineer`.
6. **Hard limits.** Never force-push either branch, never rewrite history, and
   run nothing beyond git and `gh` — no infra or platform commands. Rollback,
   if ever needed, is `git revert` of the merge commit, not a reset.
