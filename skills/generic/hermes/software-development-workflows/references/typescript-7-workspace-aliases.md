# TypeScript 7 migration: aliases, workspaces, and removed config

## Why aliases are needed

TypeScript 7.0 provides the fast native `tsc`, but does not yet provide the stable programmatic API consumed by tools such as `typescript-eslint`, framework language servers, and some build integrations. Keep two surfaces when those tools are present:

```json
{
  "devDependencies": {
    "typescript": "npm:@typescript/typescript6@^6.0.2",
    "typescript-7": "npm:typescript@^7.0.2"
  }
}
```

- `typescript` is the compatibility API for tooling.
- `typescript-7` is the native compiler used for source typechecks.

## Do not trust bare `tsc`

With aliases installed, package-manager bin linking can select the TypeScript 6 compatibility package (or its nested legacy compiler) for a bare `tsc`. Assert the version from the exact native package path and make scripts explicit:

```json
{
  "scripts": {
    "typecheck": "node node_modules/typescript-7/bin/tsc --noEmit"
  }
}
```

For a pnpm workspace, resolve the path from the workspace package's own directory, not from the repo root. Examples:

- direct child such as `client/`: `node ../node_modules/typescript-7/bin/tsc --noEmit`
- nested package such as `scripts/tool/`: `node ../../node_modules/typescript-7/bin/tsc --noEmit`

Run the script once before treating the migration as valid; an incorrect relative path can otherwise look like a compiler failure.

## TS7 config removals seen in real projects

TS7 turns several TS6 deprecations into errors. In addition to removing `ignoreDeprecations: "6.0"`, remove `baseUrl` when it is only supporting `paths`. Modern `paths` entries can remain relative to the config file:

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

Verify every configured alias after the change with the native TS7 typecheck.

## Framework cases

- **Next.js / ESLint:** retain the TS6 API alias until framework/linter support is available; point the standalone `typecheck` script at TS7.
- **Astro:** run `astro sync` before direct TS7 `tsc`; keep `astro check` on the TS6 compatibility API, then run TS7 source typecheck as a separate CI step.
- **Plain CLI/library projects with no TypeScript API consumer:** install `typescript@^7` directly and keep standard `tsc` scripts.

## Verification

1. Record `node .../typescript-7/bin/tsc --version`.
2. Run the project’s normal lint/test/build checks as well as TS7 typecheck.
3. Compare TS6 (`tsc6`) and TS7 timings if useful.
4. Confirm `git diff --check` and commit only manifests, lockfile, scripts, and necessary TS config changes.
