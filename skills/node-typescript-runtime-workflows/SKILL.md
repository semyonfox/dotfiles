---
name: node-typescript-runtime-workflows
description: "Use when diagnose and repair Node/TypeScript runtime-boundary failures in application scripts, seeds, migrations, and local mock flows."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Node/TypeScript Runtime Workflows

Use when a developer script, seed, migration, CLI, or local mock command crosses from Node JavaScript/MJS into TypeScript application code, especially when it works under a framework but fails in plain Node.

## Diagnose before changing runtime

1. Reproduce the exact public/package-script command, not a hand-assembled equivalent.
2. Identify the first failing import and trace the import chain one layer further.
3. Inspect the target module's runtime assumptions: TypeScript syntax, TS extension imports, framework-only aliases, environment loading, and side effects at import time.
4. Check whether the repository already declares a TypeScript runtime such as `tsx`; use that established tool rather than introducing a second resolver or a machine-specific path.

## TypeScript path aliases

Framework aliases such as `@/*` in `tsconfig.json` are compile-time/framework configuration; plain `node` does not resolve them. When an MJS script imports a TypeScript module that itself imports an alias, run the entrypoint with the project TypeScript runtime (normally `tsx`) so the TypeScript and path configuration are applied.

Prefer a package-script-level fix that changes only the affected child command, for example:

```json
"seed": "node scripts/dev/run-env.mjs tsx scripts/dev/seed.mjs"
```

Preserve the existing env wrapper and command ordering. Do not replace aliases with absolute host paths, add ad-hoc `NODE_PATH`, copy production code into the script, or broadly convert unrelated scripts.

## Mock and disposable-service verification

For an end-to-end mock setup change:

1. Install from the lockfile using the project's package manager.
2. Copy the documented mock environment example to the ignored local env file.
3. Start the disposable Compose stack and require its health checks to pass.
4. Run the documented public seed command. Verify meaningful side effects from its output—such as reset/schema work, object storage upload, and vector/index records—not merely exit code.
5. Start the documented mock dev command and probe its advertised local route with HTTP.
6. Stop the app process and tear down the disposable stack/volumes after verification.
7. Run typecheck, lint, and the relevant/full test suite. Inspect the final diff, run `git diff --check`, and commit only intended files.

## Documentation policy

If documentation carried a temporary multi-command workaround for a known seed/runtime bug, replace it with the concise canonical command only after the actual full flow has passed. Keep any persistent caveat only when it still applies.

## Handoff checklist

Report the branch, commit SHA, changed files, exact commands/results, whether disposable resources were cleaned up, and any limitation. If asked to stop for parent verification, commit locally but do not push.
