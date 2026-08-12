# Mobile build watcher version gating

Use this when maintaining script-backed Android/iOS build watchers for upstream mobile apps.

## Prefer version/release gating over branch-head gating

For noisy upstream repos, polling `main`/`develop` and building every new commit is wasteful. Prefer a release/version signal:

- GitHub releases via `gh release list -R owner/repo` when `gh` is authenticated and available.
- Git tags via `git ls-remote --tags --sort='v:refname' <repo> 'refs/tags/v*'` for script-only cron jobs without API credentials.
- Store a durable build key containing both ref identity and SHA, e.g. `tag:v1.2.3:<sha>` or `branch:main:<sha>`, not just a bare commit SHA.

Keep an escape hatch such as `WATCH_SOURCE=branch` for manual one-off builds of unreleased commits.

## State files

Track source-specific success independently when switching modes:

- `last_success_tag_key`, `last_success_tag_ref`, `last_success_tag_sha`
- `last_success_branch_key`, `last_success_branch_ref`, `last_success_branch_sha`
- optional global `last_success_key/ref/sha` for human inspection/backward compatibility

When migrating from old commit-only state, honor the existing SHA once so the watcher does not immediately rebuild the same APK after switching from branch-head to tag gating.

## Android packaging OOM workaround

Expo/RN generated Android projects may default to a small Gradle heap such as `org.gradle.jvmargs=-Xmx2048m`. Large native libs and JS/assets can fail late in `:app:packageRelease` with:

```text
Caused by: java.lang.OutOfMemoryError: Java heap space
  at com.android.zipflinger.Compressor.deflate
  at com.android.builder.internal.packaging.ApkFlinger$writeFile
```

For generated trees, patch `android/gradle.properties` after `expo prebuild` rather than carrying an upstream source patch:

```properties
org.gradle.jvmargs=-Xmx6144m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.workers.max=2
```

Run Gradle with `--no-daemon` in cron/script contexts so stale low-heap daemons do not survive between runs.

## Verification

After updating a watcher:

1. `bash -n` the script.
2. Seed current tag/release state to avoid an immediate duplicate build if desired.
3. Run a manual branch build only if the user explicitly wants the current unreleased commit rebuilt.
4. Run the default watcher once and verify it exits with empty stdout when no new version exists.
5. Verify APK path, file size, checksum, and published static/latest copy match.
