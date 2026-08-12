# e18e JS/TS dependency audits

Use this when Semyon wants to try `@e18e/cli` across one or more JavaScript/TypeScript projects to find dependency cleanup opportunities.

## What the tool does

`@e18e/cli analyze` reads a project `package.json` plus a supported lockfile and reports:

- package publishing issues via `publint`
- module replacement suggestions from the e18e/module-replacements manifests
- dependency summary/count/install-size data
- duplicate dependency analysis
- `core-js` polyfill issues
- source-level opportunities from `@e18e/web-features-codemods`

As of `@e18e/cli@0.7.0`, useful flags include:

```bash
npx @e18e/cli@0.7.0 analyze <repo> --json --report-level warn
npx @e18e/cli@0.7.0 analyze <repo> --json --report-level warn --categories native,preferred
npx @e18e/cli@0.7.0 analyze <repo> --json --report-level warn --src 'src/**/*.{ts,tsx,js,jsx}'
```

The analyzer requires a lockfile in the project root (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, or `bun.lock`). If none exists, skip the repo or report it separately rather than inventing results.

## Safety posture

Treat `analyze` as the default mode and `migrate` as a reviewed codemod, not a global cleanup button.

- `analyze` is intended to be read-only, but it may invoke package-manager packing through `publint`; current `publint` calls pack with `ignoreScripts: true`, so lifecycle scripts should not run.
- `migrate` rewrites files unless `--dry-run` is set.
- `migrate --all` across many repos is too risky: suggestions can be context-sensitive and may break behavior even when the codemod is syntactically valid.
- The migrate default include is `**/*.{ts,js}` only; include `tsx/jsx/mjs/cjs` explicitly if relevant.

## Recommended all-project workflow

1. Discover candidate JS/TS repos with `package.json` and a supported lockfile.
2. Exclude dependencies, caches, generated/build outputs, archived/coursework/templates/inactive clones, and other known-low-value project roots.
3. Run pinned CLI version in analysis mode only:

   ```bash
   npx @e18e/cli@0.7.0 analyze "$repo" --json --report-level warn
   ```

4. Capture one JSON output per repo plus a concise markdown rollup grouped by severity and fixability.
5. Do not run `migrate` during the sweep.
6. For an individual accepted suggestion, use a clean git worktree/branch, run the narrow migration with `--dry-run` first, inspect the diff, then run tests/checks before committing.

Example narrow migration shape:

```bash
npx @e18e/cli@0.7.0 migrate chalk --dry-run --include '**/*.{ts,tsx,js,jsx,mjs,cjs}'
# inspect expected scope, then if acceptable:
npx @e18e/cli@0.7.0 migrate chalk --include '**/*.{ts,tsx,js,jsx,mjs,cjs}'
git diff
# run project checks/tests
```

## Reporting to Semyon

Keep the first pass short: list projects scanned, skipped repos with reasons, top findings, and which findings are safe candidates for manual review. Avoid presenting `migrate --all` as the next step unless explicitly requested and protected by git diff/test verification.
