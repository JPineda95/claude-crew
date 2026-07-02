---
description: Threat-model and security-review a change or area of the codebase.
argument-hint: "[feature, path, or diff to assess]"
---

Run a focused security pass on: **$ARGUMENTS** — if no target was given, assess
the current uncommitted changes.

1. Spawn `security-engineer` to threat-model the target: identify the trust
   boundaries, assets, and abuse cases (STRIDE), then enumerate the controls that
   should exist and which are missing. Use a SAST/SCA/secret-scan MCP if one is
   configured (see `docs/TOOLING.md`).
2. Spawn `reviewer-security` to audit the actual code/diff for OWASP-style issues
   (broken access control/IDOR, injection, auth/session, secret exposure,
   sensitive-data handling, SSRF/deserialization, vulnerable dependencies,
   misconfiguration).
3. Consolidate into one report ordered by severity/exploitability, each finding
   with a concrete exploit scenario and remediation, and the owning specialist.

Fix every CRITICAL before shipping. Do not run offensive tooling against systems
you don't own; reason from the code and safe local scans only.
