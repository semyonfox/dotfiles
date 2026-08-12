# Multi-agent branch integration to `dev`

Use this when Semyon asks to take several local agent/worktree branches and commit/push the curated result to `dev`.

## Pattern

1. **Create a clean integration worktree from `origin/dev`.** Do not integrate in the dirty normal checkout.
   ```bash
   git fetch origin --prune
   git worktree add -B agent/<topic>-dev-integration /tmp/<repo>-dev-integration origin/dev
   ```
2. **Cherry-pick lanes in the intended dependency order**, not in discovery order. Resolve conflicts by preserving product intent, not blindly choosing either side.
3. **If a late optional/high-risk lane conflicts heavily**, reassess whether it is actually merge-ready. If the user said "if good", skip/report it rather than forcing a bad integration.
4. **After conflict resolution, run the project-native checks before pushing:** focused tests for touched surfaces, full test suite, lint, production build.
5. **Do a product smoke when UI changed.** Start the production build locally with the appropriate non-secret test env, hit the relevant URL, and capture/inspect screenshots. If the visual result is obviously wrong, fix it before push.
6. **Secret/staging hygiene:** stage exact files, restore generated noise such as `next-env.d.ts`, and run a lightweight secret grep over staged/non-lockfile source files.
7. **Guard the push:** fetch immediately before pushing and verify `origin/dev` is still an ancestor of the integration HEAD.
   ```bash
   test "$(git merge-base HEAD origin/dev)" = "$(git rev-parse origin/dev)"
   git push origin HEAD:dev
   git ls-remote --heads origin dev
   ```
8. **Post-push verification:** wait for GitHub Actions/CI and probe the deployed dev endpoint if push triggers deployment. Report only after remote branch, CI, and live endpoint are verified.

## Reporting

Keep the final report short: commit SHA, what landed, checks that passed, remote/deploy verification, and any caveats. Attach screenshots for visual/editor work when available.
