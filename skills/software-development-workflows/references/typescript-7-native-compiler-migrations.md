# TypeScript 7 native-compiler migrations

## Scope

Use this when upgrading an application from TypeScript 5.x/6.x to TypeScript 7. TypeScript 7's `tsc` is native and materially faster, but 7.0 does **not** provide the established programmatic compiler API. Frameworks, lint parsers, language servers, code generators, or custom tooling that `import "typescript"` may still need TypeScript 6.

## Safe workflow

1. **Discover canonical repos and protect active work.** Exclude backups, vendored code, templates, external forks, and duplicate worktrees. Inspect Git/JJ status. If the canonical checkout is dirty, make the migration in a clean worktree/branch from its current commit.
2. **Baseline first.** Run the existing typecheck/check, lint, tests, and build. Inspect `tsconfig*.json` for TS6-deprecated options that TS7 removes (notably `ignoreDeprecations`, `charset`, `importsNotUsedAsValues`, `preserveValueImports`, `noImplicitUseStrict`, `keyofStringsOnly`, `suppressExcessPropertyErrors`, and `suppressImplicitAnyIndexErrors`). Do not add config churn if none are present.
3. **Classify compiler consumers.** Search project source/configuration for imports/requires of `typescript`, and inspect peer dependencies of tooling such as `typescript-eslint`, Astro/Volar, Next, loaders, transforms, and generators. A package declaring support only through TS6 is a compatibility boundary, not a reason to force it onto TS7.
4. **Use a side-by-side transition when API consumers remain.** Keep the API-facing package as an alias to `@typescript/typescript6`, and install TS7 under a second alias, for example:

   ```json
   {
     "devDependencies": {
       "typescript": "npm:@typescript/typescript6@^6.0.2",
       "typescript-7": "npm:typescript@^7.0.2"
     }
   }
   ```

   The root `typescript` continues satisfying tools that import the old API; TS7 is used for project typechecks.
5. **Do not assume package-manager bin selection.** With aliases, a bare `tsc`/`npx tsc` can resolve to an old nested binary. Point the project script explicitly to the TS7 package:

   ```json
   {
     "scripts": {
       "typecheck": "node node_modules/typescript-7/bin/tsc --noEmit"
     }
   }
   ```

   Verify both sides after install:

   ```sh
   node node_modules/typescript-7/bin/tsc --version
   node -e "console.log(require('typescript').version)"
   ```

6. **Framework-specific generated types matter.** For Astro, run `astro sync` before direct TS7 typechecking so `.astro/types.d.ts` contains the generated content collection types. Retain `astro check` as an API-compatible framework diagnostic and add TS7 source typechecking after it:

   ```json
   {
     "scripts": {
       "typecheck": "astro sync && node node_modules/typescript-7/bin/tsc --noEmit",
       "check": "<existing lint> && astro check && <package-manager> run typecheck"
     }
   }
   ```

7. **Validate and measure.** Run project-native typecheck, lint, tests, production build, and production dependency audit. Measure TS6 and TS7 using the same command/config (`/usr/bin/time` is sufficient), and state clearly when framework-internal build checking still uses the TS6 compatibility API.
8. **Review and integrate cleanly.** Inspect the lockfile diff for only aliases/platform native packages and the intended script changes. Commit the migration separately. Fast-forward or merge it only after confirming existing dirty work does not overlap; never include the user's unrelated changes. Do not push/deploy unless explicitly requested.

## Pitfalls

- TS7's stable package is `typescript`, but TS7.0's missing programmatic API makes a direct one-package upgrade unsafe for API-consuming tooling.
- A successful framework check alone does not prove the TS7 compiler ran; assert its version from the exact binary.
- A direct `tsc` check in an Astro project can report `any`/content-collection errors simply because generated `.astro` types are absent. Run `astro sync` before treating those as source regressions.
- Do not “upgrade everything” merely because a compiler migration occurs. Update compatibility tooling only when it supports the new compiler/API and verify it; otherwise retain the documented side-by-side bridge.
