# Contributing

## The gate

This repo's own validation gate is **`scripts/check.sh`**: `bash -n` syntax
check on every script, `shellcheck -S warning` (info-level style nits don't
fail; install it locally with `brew install shellcheck` or
`apt-get install shellcheck` to run the full check — it's skipped, not
failed, when absent), `scripts/build-plugin.sh` (which also asserts
`.claude-plugin/plugin.json`'s version matches `marketplace.json`'s and has a
matching `CHANGELOG.md` heading), and reports the result.

Run it before every PR:

```bash
scripts/check.sh
```

`.github/workflows/gate.yml` re-runs the same check on every PR to `dev` and
`main`, plus two scripted smoke tests: `install.sh`/`update.sh` idempotence
(installing twice produces zero `.crew-new` files) and the downgrade guard
(PR 1's protection — syncing from an older ref than what's installed must be
refused unless `--allow-downgrade` is passed).

(This is unrelated to `CLAUDE_VALIDATE_CMD` / `.claude/crew.env` — those
configure the gate for *projects the crew builds*, not for developing the
crew itself.)

## Commits & PRs

- Conventional Commits, atomic, with a body that explains **why** — see
  [`docs/COMMITS.md`](docs/COMMITS.md).
- PRs target **`dev`**, never `main` — see guardrail 1 in
  [`CLAUDE.md`](CLAUDE.md). Only a human-run `/deploy`-equivalent (the
  release flow below) moves `main`.
- Attribution trailers for agent-authored commits
  (`Co-authored-by: Claude <noreply@anthropic.com>`).

## Release flow

1. Cut a `CHANGELOG.md` entry: move the `## Unreleased` content under a new
   `## X.Y.Z — <date>` heading.
2. Bump the version in **both** `.claude-plugin/plugin.json` and
   `.claude-plugin/marketplace.json` (the `plugins[0].version` field — never
   the unrelated top-level marketplace schema `"version": "1"`) to match.
   `scripts/build-plugin.sh` asserts these three agree and will fail the
   build otherwise.
3. Open the release PR into `dev`; once merged, a human promotes `dev` →
   `main`, tags `vX.Y.Z`, and cuts a GitHub release.
4. Consuming projects pick up the release via `/crew-update` (or
   `.claude/scripts/crew-update.sh`).
