# e18e dependency audit workflow

Use this when auditing JavaScript/TypeScript repos with `@e18e/cli` for dependency replacements, duplicate transitive deps, and native-feature suggestions.

## Safe sequence

1. **Analyze only first.** Run `npx -y @e18e/cli@<pinned-version> analyze <repo> --json --log-level error --report-level info` and capture JSON/markdown output outside the repo.
2. **Filter scope before acting.** Exclude archives, reference/vendor repos, generated dumps, worktrees, coursework/examples, disposable clones, and vendored/generated source such as `public/pdf.worker.js` or bundled Bootstrap/jQuery.
3. **Split findings by risk class:**
   - duplicate transitive deps / lockfile drift
   - unused direct deps
   - direct dependency replacement candidates
   - native syntax/source suggestions
4. **Use conservative mutation rules:**
   - `pnpm dedupe`/lockfile-only changes are acceptable only in clean repos and after `--check`/frozen install verification.
   - Do not run `e18e migrate --all` or broad codemods across multiple repos.
   - Do not remove a dependency just because source search says it is unused if the repo is old/stale, build tooling may rely on it, or the package is part of a deployed/static workflow; treat as design cleanup unless clearly isolated and user-approved.
   - Do not replace auth/security/session dependencies (`jsonwebtoken`, OAuth/session libs, cookie jars, HTTP clients with redirect/cookie behavior) as drive-by cleanup.
   - Do not replace UUID generation if the project deliberately uses UUID v7/sortable IDs elsewhere; keep dependency semantics coherent unless doing a dedicated ID strategy migration.
5. **Verify after every applied change:** run the project’s package-manager install check (`npm install --package-lock-only --ignore-scripts` only if appropriate, `pnpm install --frozen-lockfile`, etc.), targeted lint/tests, and a build when the project is small enough.
6. **Re-open diffs before reporting.** Agent/subagent self-reports may be wrong; inspect actual `git diff --stat`, relevant diffs, and searches after any claimed change.

## Risk heuristics

- **Easy:** lockfile-only dedupe that changes no manifests and passes frozen install.
- **Maybe:** unused dev tooling dependency in a clean repo with a green build after removal.
- **Design decision:** CRA/Jest/Babel duplicate stacks, Cloudflare toolchain skew, auth/JWT replacements, HTTP clients with cookie jars/redirect semantics, commander/CLI parser rewrites, workspace/package-manager drift.
- **Noise:** vendored JS bundles, generated workers, old device archives, reference repos.

## Reporting format

Report per repo:

- files changed
- commands run
- checks and exact pass/fail result
- findings left as design decisions
- anything reverted because verification showed broad/unwanted churn

If the user calls a cleanup dangerous or asks to revert, revert immediately and verify the relevant diff is empty.