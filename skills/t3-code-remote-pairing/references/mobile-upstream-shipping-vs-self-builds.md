# T3 Code mobile: upstream shipping vs self-built APKs

Use this when Semyon asks whether T3 Code mobile is "built", "served", "shipped", or whether he needs to build from source.

## Key distinction

Do not conflate Semyon's locally mirrored APK endpoint with upstream officially shipping mobile builds.

- `https://fileshare.semyon.ie/t3-apk.php` is Semyon's own cron-built APK mirror from source/branch state. It proves the local cron built and served an APK, not that upstream publicly ships Android mobile artifacts.
- Upstream GitHub releases/nightlies currently ship desktop artifacts: macOS `.dmg`/`.zip`, Windows `.exe`, Linux `.AppImage`, update YAML/blockmaps.
- Mobile lives in source under `apps/mobile` and has EAS build config/scripts, but normal public GitHub releases/nightlies should not be assumed to include mobile APK/AAB artifacts unless verified.

## How to verify

From a checkout or with `gh`:

```bash
gh release list --repo pingdotgg/t3code --limit 10
gh release view --repo pingdotgg/t3code --json tagName,name,isPrerelease,assets,url
```

Inspect asset names for `.apk`, `.aab`, or mobile-specific install links. Desktop-only assets usually look like:

- `T3-Code-...-arm64.dmg`
- `T3-Code-...-arm64.zip`
- `T3-Code-...-x64.exe`
- `T3-Code-...-x86_64.AppImage`
- `latest*.yml` / `nightly*.yml` / `.blockmap`

Check mobile CI config:

```bash
sed -n '1,140p' .github/workflows/mobile-eas-preview.yml
sed -n '1,160p' .github/workflows/mobile-eas-production.yml
sed -n '1,120p' apps/mobile/eas.json
node -e "const p=require('./apps/mobile/package.json'); console.log(p.scripts)"
```

Observed workflow shape in this repo:

- `mobile-eas-preview.yml` runs on PRs only when labelled `🚀 Mobile Continuous Deployment`, uses Expo EAS `continuous-deploy-fingerprint`, and profile `preview:dev`.
- `mobile-eas-production.yml` is manual `workflow_dispatch`, builds/submits through EAS or publishes OTA updates.
- `apps/mobile/eas.json` has `preview:dev` with Android `buildType: apk`, but that is internal/preview distribution unless a public asset/link is explicitly exposed.

## Answer pattern

If Semyon asks "is it shipped built or do I build it myself?":

- For desktop: upstream ships built releases/nightlies; no source build needed.
- For Android/mobile alpha: assume source/EAS/self-build or Semyon's cron-built APK unless a current upstream public APK/AAB/EAS install link is verified.
- Be explicit: "served on your fileshare" is not the same as "officially shipped by upstream".

Keep the answer short; Semyon is usually checking whether he must do work, not asking for a release-engineering lecture.