# Public email aliases, Cloudflare routing, and app deployment

Use this for a public-site support-address migration where Semyon wants inbound mail delivered to personal Gmail without publishing it.

## Current intended routing

- Cloudflare Email Routing is the inbound provider for `semyon.ie`.
- Explicit rule: `hello@semyon.ie` forwards to Semyon's personal Gmail.
- Keep catch-all disabled unless Semyon explicitly requests it.
- This is inbound only. It does not make Gmail able to send as the alias; do not imply replies originate from `hello@semyon.ie` without separately configured SMTP/sender infrastructure.

## Safe migration sequence

1. **Inspect before changing:** locate every public `mailto:`, visible address, privacy/terms/support copy, API/OpenAPI metadata, generated docs, and transactional-email contact configuration. Distinguish source defaults from environment overrides.
2. **Configure routing first:** confirm the destination is verified, create one explicit alias rule, enable Email Routing only after reviewing conflicting root MX/SPF records, and verify Cloudflare reports the zone ready. Do not alter unrelated tunnel/site DNS.
3. **Update all public surfaces:** replace the scraped personal address with the domain alias in frontend pages and public static docs. For services, update the runtime support-email environment variable and the code fallback so a missing environment value cannot silently restore an old address.
4. **Protect secret configuration:** never use a diff-producing editor on an env file if it can print neighboring secrets. Make a precise key replacement and report only the non-secret key name/value; restart/recreate only the service that reads that setting.
5. **Validate before and after deploy:** search source for old addresses, run native lint/type/build checks, inspect the exact version-control diff, then deploy only changed services where safe. Verify public HTTP, local container health, and the served bundle/content. Cloudflare email obfuscation can hide raw HTML addresses, so inspect/decode the served representation as needed.
6. **Treat CI separately:** if Jenkins fails in an unrelated environment-specific smoke test, state the exact failed check. A manually deployed, locally built artifact must be the exact committed revision, and live health must be verified independently. Do not claim Jenkins deployed it.

## Semyon deployment specifics

- Portfolio source: `~/code/personal/portfolio`; public alias change is deployed through its Docker stack/tunnel.
- Swim source: `~/code/personal/swim`; public client runs as `swim-client`, API as `swim-backend`, on Docker network `swim`.
- Swim runtime environment: `~/server-stacks/uisce/stack.env`; `CONTACT_EMAIL` must be `hello@semyon.ie` and the backend must be recreated to apply it.
- Swim client-only edits can be safely deployed by building the client from a clean worktree at the committed revision and replacing only `swim-client`; confirm `https://swim.semyon.ie/contact` and `http://127.0.0.1:4000/health` afterward.
- Swim uses jj. Preserve unrelated Git-LFS image status noise: inspect `jj status` and `jj diff` rather than committing image files merely because Git reports smudge/stat modifications.

## Verification checklist

- Cloudflare routing status ready and explicit alias rule active
- No old personal address in public source/built client
- Public page returns 200 and served bundle contains the alias
- Updated runtime service restarted and health endpoint reports healthy
- Main branch points at the reviewed alias commit
- Any CI failure is reported separately from manual deployment verification
