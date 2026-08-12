# T3 Code mobile APK watcher repair

Use this when the T3 Code Android build watcher loses its source branch or fails during Expo/Gradle assembly.

## Source-line rule

A deleted temporary mobile/integration branch is not a reason to fall back to a release tag. Determine where the work landed:

1. Query the relevant GitHub PR and record `merged_at`, `base.ref`, and merge commit.
2. Resolve the candidate base/default/HEAD branch remotely.
3. Confirm `apps/mobile/package.json` identifies `@t3tools/mobile` on every candidate.
4. Track the active validated branch (often `main` after a merged PR), not a frozen release tag.

## Safe automatic reconciliation

Use this order only when the configured mobile branch no longer resolves:

1. explicit operator fallback;
2. known merged mobile PR base;
3. GitHub default branch;
4. Git remote HEAD.

Every candidate must pass the mobile-package check. Emit both configured and resolved branch plus commit SHA. Reject tags as an implicit fallback for this moving development line.

## Generated Android-tree fixes

Run `expo prebuild --clean` before local compatibility fixes. Keep repairs in the watcher and apply them only to the generated tree, so upstream sources and dependencies remain untouched.

For AAPT2 errors such as a manifest `@string/...` resource not found, inspect the generated manifest and resource directories. One affected widget-plugin output put `<string>` values in `res/xml`, which Android does not compile as string resources. The safe workaround copies only parsed, non-empty expected strings into a generated `res/values/*.xml` file after prebuild. It must no-op when upstream emits correct values resources and must fail if the manifest/resource contract changes.

## Verification ladder

1. `bash -n` the watcher.
2. Resolve the chosen remote branch and validate the mobile manifest.
3. Run a clean Android prebuild.
4. Run `./gradlew --no-daemon :app:processReleaseResources -PreactNativeArchitectures=arm64-v8a --stacktrace` to prove resource linking before using a full APK build.
5. Trigger one real watcher build and verify its source branch/SHA in the generated log.

Do not report a watcher repaired merely because its branch resolution succeeds: the mobile Gradle resource phase must be exercised.