# TypeScript 7 practical migrations

## Scope

Use for owned Node/TypeScript projects moving from TypeScript 5.x/6.x to TS 7.0.2. The key distinction is **native `tsc`** versus tooling that imports the TypeScript compiler API: TS 7.0 has the former but not the stable programmatic API.

## Decision table

| Project shape | Safe package setup |
|---|---|
| Plain CLI/library; test/build tools do not import `typescript` | Upgrade direct `typescript` dependency to `^7.0.2`; retain ordinary `tsc` scripts. |
| Framework or ESLint tooling consumes the compiler API (Next, Astro language tooling, `typescript-eslint`) | Keep `typescript` as `npm:@typescript/typescript6@^6.0.2` for API consumers and add `typescript-7: npm:typescript@^7.0.2`. Point the project-owned typecheck explicitly at the TS7 binary. |

Do not claim a project uses TS7 merely because it has a TS7 package installed. Run the exact compiler path and print its version.

## Workspace and framework details

- In pnpm workspaces, scripts execute from the workspace package directory. Resolve the TS7 binary relative to that directory, not the repository root:
  - immediate child package: `node ../node_modules/typescript-7/bin/tsc --noEmit`
  - two-level nested package: `node ../../node_modules/typescript-7/bin/tsc`
- For Astro, run `astro sync` before native `tsc`, then keep `astro check` as the framework/API compatibility check.
- For a nested independently-built package, migrate its own manifest and lockfile, install there, and test it separately. A parent-project migration does not upgrade nested package toolchains automatically.
- TS7 removes options previously merely deprecated in TS6. The verified removals encountered here were `ignoreDeprecations: "6.0"` and `baseUrl`. Remove `baseUrl`; explicit `paths` entries relative to the config file can remain and must be typechecked after the change.

## Safe execution sequence

1. Inspect canonical repo/worktree state and package manager. Exclude archived copies, reference implementations, and feature worktrees unless explicitly requested.
2. Scan tsconfigs for TS6-deprecated options and inspect scripts that invoke `tsc`.
3. If canonical work has unrelated edits, create a clean worktree and commit the migration alone.
4. Upgrade or add the compiler package(s), regenerate the lockfile, and verify the exact TS7 version.
5. Run direct TS7 typecheck, then project lint/tests/build. Distinguish pre-existing lint/format failures from migration regressions.
6. Restore generated build artifacts before committing unless the project intentionally versions them.
7. Merge only when modified manifest/lockfile files do not overlap user work. If they overlap, leave the verified migration as a clean branch/commit rather than stashing, overwriting, or committing the user's WIP.

## Evidence from verified migrations

- Plain TS7 direct compilation succeeded for a Bun-compiled Canvas CLI, a small Node CLI, a userscript, and Canvas MCP packages.
- API-isolated TS7 typechecks succeeded alongside TypeScript 6 aliases in Next, Astro, and ESLint-based projects.
- Measured native typecheck speedups were material: OghmaNotes 0.67s vs 13.44s; Portfolio 0.28s vs 2.44s; Swim 1.42s vs 10.56s.

## Validation minimum

- `git diff --check`
- exact TS7 `--version`
- direct TS7 typecheck
- native test/build scripts
- lockfile-consistent install
- dependency audit, reported separately from compiler migration failures
