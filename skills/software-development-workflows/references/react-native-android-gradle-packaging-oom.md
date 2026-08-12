# React Native / Expo Android Gradle packaging OOM triage

Use when an Android release build gets through config/typecheck/prebuild/compile work but fails near the end in `:app:packageRelease`.

## Signature

Typical log shape:

```text
> Task :app:packageRelease FAILED
Execution failed for task ':app:packageRelease'.
> A failure occurred while executing com.android.build.gradle.tasks.PackageAndroidArtifact$IncrementalSplitterRunnable
Caused by: java.lang.OutOfMemoryError
Caused by: java.lang.OutOfMemoryError: Java heap space
    at com.android.zipflinger.NoCopyByteArrayOutputStream.<init>
    at com.android.zipflinger.Compressor.deflate
    at com.android.builder.internal.packaging.ApkFlinger$writeFile
```

This points to APK packaging/compression memory pressure, not necessarily a source-code regression.

## Fast diagnosis

1. Read the end of the Gradle log first; packaging failures often appear after hundreds/thousands of successful tasks.
2. Identify the exact Gradle command and variant/architectures, e.g. `./gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a --stacktrace`.
3. Inspect `android/gradle.properties` for `org.gradle.jvmargs`; Expo/RN projects often default to `-Xmx2048m`, which can be too small for packaging large native libs/assets.
4. Check whether previous watcher/build logs succeeded for nearby commits. If the failing commit is source-small and the failure is heap-at-package, treat it as resource/config flake until reproduced with a larger heap.
5. Check machine pressure (`free -h`, swap usage) and large build artifacts/native libs (`du -sh android/app/build`, largest files under `merged_native_libs`, bundles, dex files) to support the conclusion.

## Common mitigation

Retry with a larger Gradle heap, e.g. `org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m` or `-Xmx6g` on sufficiently large builders. If the box is memory pressured, also consider reducing parallelism (`org.gradle.parallel=false` or lower worker count) for the release packaging run.

For cron/watchers, prefer reporting this as "Gradle packaging OOM" with the failed task, heap setting, current memory/swap state, and whether the commit diff is plausibly related. Avoid blaming the source commit unless the failure reproduces after memory is increased or the diff clearly enlarged package inputs.
