# T3 Code Android release watcher recovery

Use this when a script-backed watcher builds an Android APK from `pingdotgg/t3code` and its configured integration branch no longer resolves.

## Durable recovery pattern

1. Confirm the failure is source-ref resolution, not Gradle/Android tooling:
   ```bash
   git ls-remote --heads https://github.com/pingdotgg/t3code.git refs/heads/<branch>
   ```
2. Do not replace a deleted integration branch with an arbitrary `main` commit. First verify that a release tag still contains `apps/mobile` and its Android Expo configuration.
3. Default to the latest **stable** `v*` tag. Exclude names containing `-` by default so nightlies, alpha/beta/RC tags are never silently promoted.
4. Version-sort candidate tags (`sort -V`), select the newest, and resolve an annotated tag to its peeled commit SHA. Store both tag and SHA in the watcher state key.
5. In tag mode, fetch the exact tag ref and check out the resolved commit. Do not fetch/reset a stale branch as part of a tag build.
6. Keep branch tracking as an explicit temporary override, e.g. `T3_WATCH_SOURCE=branch T3_WATCH_BRANCH=<existing-ref>`. Permit prerelease selection only by explicit override, e.g. `T3_WATCH_STABLE_TAGS_ONLY=0`.
7. Verify before restoring the cron schedule: script syntax, ref resolution, and exact tag fetch. Trigger one real run and confirm it gets through checkout/dependency install/typecheck/prebuild before treating the source fix as proven.

## Operational notes

- A `no_agent=true` cron job delivers script stdout and treats a non-zero exit as an alert. For a source-resolution incident, repair the script's selection/fallback logic first, then manually trigger the existing job rather than waiting for its next interval.
- Avoid embedding an LLM invocation inside a build script as the primary recovery mechanism. Deterministic ref selection is safer, testable, and works in non-interactive scheduler environments; use an autonomous coding agent to investigate and implement a one-time repair when needed.
- Preserve the build's existing timeouts and lock. A successful resolver can still reveal independent build regressions; do not conflate them.
