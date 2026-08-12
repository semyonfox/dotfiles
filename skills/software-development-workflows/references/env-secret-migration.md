# Env and secret migration for small repo utilities

Use this when a repo utility script has hardcoded API keys, provider project IDs, local absolute paths, or credential JSON paths.

## Goals

- Move secrets into a local `.env` or the platform's secret store.
- Keep non-secret defaults discoverable in `.env.example`.
- Avoid printing secrets during discovery, validation, diffs, or reports.
- Preserve runnable local scripts with explicit configuration errors.

## Workflow

1. **Classify what is actually secret.**
   - API keys, bearer tokens, service-account JSON, refresh tokens: secret.
   - Provider project IDs, locations, model names, local input/output paths: usually config, not secret, but should still be env-configurable.
2. **Validate without leaking.**
   - Report only provider, status, length/prefix/suffix if needed, and error class/code.
   - For OpenAI-style keys, a cheap auth probe like `/v1/models` can prove the key is syntactically/auth-valid; a tiny target endpoint probe can distinguish valid-but-quota-blocked from usable.
   - For Google Cloud client libraries, check whether Application Default Credentials or `GOOGLE_APPLICATION_CREDENTIALS` are configured; do not print JSON content.
3. **Move code to env reads.**
   - Prefer an existing config/env library if present.
   - For tiny CommonJS utilities, a small local `.env` loader is acceptable to avoid adding a dependency.
   - Use `getRequiredEnv()` for true secrets and required cloud project config; use `getEnv(name, fallback)` for defaults.
4. **Create `.env.example`.**
   - Include variable names and safe defaults only.
   - Leave secrets blank.
   - Include comments for service-account credential path setup.
5. **Harden `.gitignore`.**
   - Ignore `.env`, `.env.*`, service-account JSON, and credential JSON patterns.
   - Re-include `!.env.example`.
6. **Add runnable scripts/checks.**
   - Add `npm run check` or equivalent syntax checks for touched scripts.
   - Add named scripts for the utility entrypoints where useful.
7. **Verify.**
   - Syntax check touched files.
   - Confirm `.env` is ignored and `.env.example` is not ignored.
   - Search source excluding `.env`, `.git`, and dependencies for secret-looking patterns.
   - If a key was already committed, report that history still contains it and recommend rotation even if the repo is private.

## Pitfalls

- Do not claim a key is safe just because the repo is private. Private repos reduce exposure; committed secrets still deserve rotation.
- Do not print the key while proving it works. Use redacted metadata and provider error codes.
- Do not move a provider project ID into `.env` and forget to document it in `.env.example`.
- Do not break local scripts by replacing hardcoded absolute paths with required env vars when sensible repo-relative defaults exist.
- Do not commit `.env`; verify ignore behavior before finishing.
