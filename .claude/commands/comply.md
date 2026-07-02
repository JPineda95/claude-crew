---
description: Audit data-protection compliance and generate/refresh the required artifacts (data map, privacy policy, ToS, cookie banner spec).
argument-hint: "[optional: feature, area, or artifact to focus on]"
---

Run a data-compliance pass on: **$ARGUMENTS** — if no target was given, audit
the whole application.

1. Spawn `data-compliance-officer` to:
   - build or refresh the **data map** from the code (schema, forms, logs,
     analytics, third-party SDKs, cookies actually set),
   - determine the applicable regimes from the markets in `PROJECT.md` (ask if
     they aren't declared — don't guess),
   - run the gap analysis and produce findings ordered by risk, each with the
     regime it violates, the evidence, and a remediation.
2. Have it generate or update the artifacts that are missing or stale: privacy
   policy, terms of service, cookie policy + consent-banner spec, DSR runbook,
   retention schedule — in the product's locale, marked as drafts for counsel.
3. Route each engineering gap to its owning specialist: consent banner →
   `frontend-engineer`, export/erasure endpoints → `backend-engineer`,
   retention/deletion cascades → `database-architect`, wording → `copywriter`,
   protection issues discovered along the way → `security-engineer`.
4. Present one consolidated report: the data-map delta, findings by risk, the
   artifacts produced, the task list per specialist, and every open question
   that needs the human or qualified counsel.

Do not implement the fixes in this pass unless the user asks — this is an audit
plus artifact generation. Never present generated legal documents as final:
they are drafts requiring review by a lawyer in the relevant jurisdiction.
