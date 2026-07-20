# VietLunar implementation-document bundle

Files:

- `docs/VietLunar_SPEC.md` — product requirements, calendar conventions, architecture, APIs, future event design, testing, acceptance criteria.
- `docs/VietLunar_CODEX_PLAN.md` — ordered implementation tasks and definitions of done.
- `docs/VietLunar_CODEX_PROMPT.md` — ready-to-paste prompt for a Codex coding session.
- `docs/VietLunar_TEST_VECTORS.json` — curated regression inputs; exhaustive reference data is still required.

Recommended use:

1. Copy the Markdown files into the repository’s `docs/` directory.
2. Give Codex the prompt file and tell it which milestone to execute.
3. Require Codex to stop at milestone boundaries and attach test/build results.
4. Preserve the accepted 2033 golden sequence and commit its independent source provenance before release.

