# Bot/autofix PR triage

Use this when CodeRabbit, Copilot, Dependabot, Renovate, or another bot opens an autofix PR.

## Default stance

Do not treat bot autofix PRs as automatically safe, especially when they bundle unrelated edits. Mine them for real issues, then salvage the useful pieces into a human-authored PR if needed.

## Review sequence

1. Read the bot PR diff and original review context/comment that produced it.
2. Re-check current base. The underlying issue may already be fixed, moved, or made irrelevant.
3. Pull failed CI logs and separate:
   - failures caused by the bot patch
   - stale branch/tooling failures
   - unrelated failures now fixed on base
4. For each changed file, classify the edit as:
   - safe direct fix
   - real issue but unsafe/incomplete implementation
   - behaviour change needing human decision
   - stale/no longer needed
5. If any edit touches security headers, CSP, auth, routing, storage origins, data deletion, or user-visible navigation, do not merge blindly. Check deployment env names and runtime architecture.

## CSP-specific pitfall

Autofixes that replace broad CSP origins with new env variables can be worse than the original issue if those env vars are undocumented or unset in deployment. Verify names against:

- `.env.example` / production templates
- Jenkins/deploy env documentation
- existing runtime code (`NEXT_PUBLIC_APP_URL`, `NEXT_PUBLIC_API_URL`, `STORAGE_ENDPOINT`, etc.)

If unset envs would collapse `connect-src` to only `'self'`/`blob:` or otherwise block legitimate app/storage/API traffic, reject the bot patch and design a deliberate CSP PR instead.

## Useful salvage patterns

- Tiny test typing fixes may be salvageable, but should not justify merging a mixed risky bot PR.
- UX fallback changes, such as redirecting on fetch/network errors, need an explicit product decision and should usually be separated.
- Security hardening should use documented env vars and include tests/assertions for generated headers.

## Reporting

Report one recommendation:

- close as stale/unsafe
- merge as-is only if all edits are coherent and checks pass
- create a new salvage PR with named pieces

Include concise evidence: changed files, failed checks, and the exact risky behaviour avoided.
