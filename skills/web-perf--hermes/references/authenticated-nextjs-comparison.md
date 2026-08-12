# Authenticated Next.js A/B performance comparison

Use this pattern when comparing a PR/worktree against `dev` for a logged-in app page, especially when the performance question is about lazy client-side code such as syntax highlighting.

## Setup pattern

1. Create/run two or more clean worktrees on separate ports, sharing the same disposable/mock backing services and seeded test user. Include a clean base/reference worktree from the same `origin/<base>` commit.
2. Use production builds (`next build` + `next start`) rather than `next dev`; dev-server traces are too noisy for bundle/perf comparisons.
3. Seed a deterministic fixture that exercises the feature under test. For markdown/code highlighting, use a note with several fenced blocks across likely languages (`tsx`, `ts`, `sql`, `bash`), language aliases, unknown languages, long lines, fence metadata/title, tables, tasks, math, and hostile-looking HTML/script inside code fences.
4. For auth-gated pages, avoid UI-login cookies if the session cookie is `HttpOnly` and not visible from Playwright storage exports. If the app uses a signed JWT session cookie and the local mock secret is known, generate a short-lived test-only `session=<jwt>` cookie for the seeded user and pass it to Lighthouse/Unlighthouse via cookies/headers. For Oghma's custom auth helper, a `session` cookie signed with `JWT_SECRET` containing `{ user_id, email }` is enough for `validateSession`.
5. Always verify the audited URL did not redirect to `/login`; Lighthouse/Unlighthouse can silently produce good-looking login-page numbers if auth was not actually applied. Capture body excerpts or route screenshots as proof.

## Lighthouse / Unlighthouse command shape

For Lighthouse directly:

```bash
export CHROME_PATH="$(node -e "const {chromium}=require('playwright'); console.log(chromium.executablePath())")"
COOKIE="session=<test-jwt>; ogma-theme=system; ogma-locale=en"
npx -y lighthouse@latest "http://127.0.0.1:3311/notes/<fixture-id>" \
  --output=json --output=html --output-path=/tmp/perf/lh-base \
  --chrome-flags="--headless=new --no-sandbox --disable-dev-shm-usage" \
  --extra-headers="{\"Cookie\":\"$COOKIE\"}" \
  --only-categories=performance \
  --quiet
```

For Unlighthouse CI over a small explicit URL set, use `unlighthouse-ci` with a config file that passes no-sandbox flags to Puppeteer/Chrome when running on locked-down Linux hosts:

```ts
// /tmp/unlighthouse-nosandbox.config.ts
export default {
  puppeteerOptions: {
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  },
  lighthouseOptions: {
    chromeFlags: ["--headless=new", "--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  },
};
```

```bash
COOKIE="session=<test-jwt>"
npx -y -p puppeteer@latest -p unlighthouse-ci@0.18.0 unlighthouse-ci \
  --site "http://127.0.0.1:3311" \
  --urls "/syntax-guide,/notes/<fixture-id>" \
  --cookies "$COOKIE" \
  --desktop --samples 1 --reporter json \
  --output-path /tmp/perf/unlighthouse-base \
  --disable-robots-txt --disable-sitemap --no-cache \
  --config-file /tmp/unlighthouse-nosandbox.config.ts
```

The explicit `-p puppeteer` avoids Unlighthouse/puppeteer-cluster module-resolution failures in ephemeral `npx` installs.

Extract and compare at minimum:
- performance score
- FCP / LCP / Speed Index
- TBT / TTI
- CLS
- total byte weight
- main-thread work
- JS bootup

## Focused interaction timing

Lighthouse is useful but not enough for lazy-loaded UI. Add a Playwright median-of-5 interaction probe:

- navigate to the authenticated fixture page
- wait for `domcontentloaded` and then `networkidle`
- click the relevant UI mode/action (`Read`, preview, open panel, etc.)
- wait for feature-specific ready selectors, e.g. 4 `.oghma-shiki-code` blocks or 4 `pre code` blocks
- record median `readReadyMs`, `readNetworkIdleMs`, script resource count, encoded script bytes, post-click chunk bytes, and detected feature block counts

This catches deferred costs that Lighthouse’s page-level numbers flatten.

## Visual proof

Capture full-page screenshots for each variant, then produce:
- individual screenshots for the user to inspect
- a labelled side-by-side composite cropped to the useful area, because full-page tall screenshots are hard to compare in chat

Use the screenshots as evidence, not decoration: note obvious differences (e.g. ignored fence metadata vs filename chrome, light code box vs dark editor-like Shiki panel, wrap/copy controls, syntax quality).

## Reporting guidance

Give a blunt tradeoff call:
- separate hot-path metrics from lazy feature costs
- quantify bundle/interaction deltas, not just Lighthouse score
- call out CLS/layout shift if highlighting replaces a fallback after first paint
- if a heavy library is justified visually, recommend the next optimization specifically (e.g. replace `shiki/bundle/web` with fine-grained `shiki/core`, selected languages, and a single theme)

Avoid preserving session-specific PR numbers, local ports, or fixture IDs in the main skill. Keep those details in this reference only when needed as examples.
