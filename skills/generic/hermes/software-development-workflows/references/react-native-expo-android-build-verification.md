# React Native / Expo Android build verification

Use this when asked whether a mobile branch is actually buildable/installable on Android, especially for Expo apps with native modules.

## Checklist

1. Resolve the repo/branch and inspect `apps/mobile/package.json`, `app.config.*`, `eas.json`, and README notes before guessing commands.
2. Install dependencies with the repo package manager, normally from repo root:
   ```bash
   pnpm install --frozen-lockfile
   ```
3. Run JS/native-independent checks first:
   ```bash
   pnpm --filter <mobile-package> run config:dev
   pnpm --filter <mobile-package> run typecheck
   pnpm --filter <mobile-package> run test
   ```
4. For Expo native modules, Expo Go is not enough. Prebuild native Android:
   ```bash
   APP_VARIANT=preview EXPO_NO_GIT_STATUS=1 pnpm --filter <mobile-package> exec expo prebuild --clean --platform android
   ```
5. Build a real APK, preferably arm64 for a modern physical phone:
   ```bash
   cd apps/mobile/android
   ./gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a --stacktrace --no-daemon
   ```
6. Verify the artifact before handing it over:
   ```bash
   aapt dump badging app/build/outputs/apk/release/app-release.apk | sed -n '1,35p'
   apksigner verify --verbose --print-certs app/build/outputs/apk/release/app-release.apk
   sha256sum app/build/outputs/apk/release/app-release.apk
   ```

## Gradle / React Native foojay resolver pitfall

Some React Native Gradle plugin versions include this in `@react-native/gradle-plugin/settings.gradle.kts`:

```kotlin
plugins { id("org.gradle.toolchains.foojay-resolver-convention").version("0.5.0") }
```

With newer Gradle wrappers, local builds can fail early with:

```text
Class org.gradle.jvm.toolchain.JvmVendorSpec does not have member field ... IBM_SEMERU
```

If CI/EAS works but a local Gradle 9.x verification build hits this, a local-only diagnostic workaround is to patch the generated dependency copy to `1.0.0` and re-run the build:

```bash
for f in node_modules/.pnpm/@react-native+gradle-plugin@*/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
         node_modules/.pnpm/node_modules/@react-native/gradle-plugin/settings.gradle.kts \
         node_modules/.pnpm/react-native@*/node_modules/@react-native/gradle-plugin/settings.gradle.kts; do
  [ -f "$f" ] && perl -0pi -e 's/foojay-resolver-convention"\)\.version\("0\.5\.0"/foojay-resolver-convention").version("1.0.0"/g' "$f"
done
```

Do **not** commit this blind as an app change; treat it as local build-environment unblock evidence unless upstream intends to pin a newer React Native Gradle plugin/resolver.

## React runtime / React Native renderer exact-version pitfall

React Native can vendor a `react-native-renderer` patch version that must be **identical** to the mobile app's `react` package version. A Gradle-successful APK can still abort immediately with:

```
Incompatible React versions: The "react" and "react-native-renderer" packages must have the exact same version.
```

When this occurs, inspect the actual installed renderer rather than trusting compatible semver ranges:

```bash
node - <<'NODE'
const fs = require('fs');
const renderer = require.resolve('react-native/Libraries/Renderer/implementations/ReactNativeRenderer-prod.js', { paths: ['apps/mobile'] });
const expected = fs.readFileSync(renderer, 'utf8').match(/react-native-renderer:\\s+ (19\\.[0-9.]+)/)?.[1];
const app = require('./apps/mobile/package.json');
console.log({ expectedRendererReact: expected, react: app.dependencies.react, reactDom: app.dependencies['react-dom'] });
NODE
```

Pin `react` and `react-dom` to the renderer's exact version, refresh the lockfile, then perform a clean native build. Do not publish the prior APK simply because it assembled; verify the fixed APK signature and report physical-device launch separately.

## Large Expo/RN builds on small machines

If Kotlin/KSP or lint dies with metaspace/OOM, increase Gradle metaspace and reduce parallelism for verification builds:

```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=2048m
org.gradle.parallel=false
```

For delivery to a specific phone, arm64-only builds reduce native compile work and artifact size:

```bash
./gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a --no-daemon
```

If `lintVitalRelease` is the only long tail and the goal is installability rather than store readiness, one diagnostic build may use `-x lintVitalRelease`, but state that clearly and do not call it a full release-quality gate.

## Reporting

Report separately:

- branch and app path
- checks run and counts/results
- whether an APK/AAB was actually produced
- package id, min/target SDK, signing type, architecture scope
- whether it was run on a real device or only built/verified statically
- install steps and SHA256 for any delivered APK
