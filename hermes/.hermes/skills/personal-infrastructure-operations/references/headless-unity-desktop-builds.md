# Headless Unity desktop builds and public artifact delivery

Use this for a small Unity project that must be built on Semyon's Ubuntu server for Linux and Windows friends, without using a desktop Unity GUI.

## Preconditions and secure account flow

1. Install the official standalone Unity CLI (not Unity Hub desktop) user-locally:

   ```bash
   curl -fsSL https://public-cdn.cloud.unity3d.com/hub/prod/cli/install.sh | UNITY_CLI_CHANNEL=beta bash
   ~/.unity/bin/unity --version
   ```

2. Have Semyon authenticate **from his own SSH terminal**, not by sharing Unity credentials or a browser callback in Discord:

   ```bash
   ssh -t semyon@10.0.0.5 ~/.unity/bin/unity auth login
   ```

3. Verify and activate Unity Personal headlessly. The current Unity CLI exposes this explicitly; `auth status` alone is not enough for an Editor build.

   ```bash
   unity auth status
   unity license activate --personal --accept-eula --non-interactive --format json
   unity license status --format json
   ```

4. Match the exact editor version and changeset in `ProjectSettings/ProjectVersion.txt`:

   ```bash
   unity install 2022.3.62f1 -c <changeset> --non-interactive --accept-eula --yes
   unity editors --installed --format json
   ```

5. List modules before guessing IDs, then install only the target support required. On Linux, the standard Linux player is included with this editor; Windows desktop export required `windows-mono` for the prototype:

   ```bash
   unity install-modules -e 2022.3.62f1 -l --format json
   unity install-modules -e 2022.3.62f1 -m windows-mono --non-interactive --accept-eula --yes
   ```

6. Run an Editor batch smoke before importing/building a project:

   ```bash
   "$HOME/Unity/Hub/Editor/2022.3.62f1/Editor/Unity" -batchmode -nographics -quit -logFile /tmp/unity-smoke.log
   ```

## Build and verify

Use direct Editor flags for a simple project with an enabled scene in `EditorBuildSettings.asset`:

```bash
EDITOR="$HOME/Unity/Hub/Editor/2022.3.62f1/Editor/Unity"
PROJECT=/home/semyon/code/<game>

"$EDITOR" -batchmode -nographics -quit -projectPath "$PROJECT" \
  -buildLinux64Player "$PROJECT/build/linux/<game>.x86_64" \
  -logFile "$PROJECT/build/linux-build.log"

"$EDITOR" -batchmode -nographics -quit -projectPath "$PROJECT" \
  -buildWindows64Player "$PROJECT/build/windows/<game>.exe" \
  -logFile "$PROJECT/build/windows-build.log"
```

- Run builds serially: simultaneous Editors can compete for ports/project `Library` state.
- For a headless Linux smoke, run the emitted player for a bounded interval; expected `timeout` exit `124` proves it stayed alive, while the log must not contain a crash:

  ```bash
  timeout 8s ./<game>.x86_64 -batchmode -nographics -logFile /tmp/<game>-smoke.log
  ```

- Verify artifact formats with `file`; a Windows result should report `PE32+ executable` and Linux `ELF 64-bit`.
- Be precise in reporting: Linux was runtime-smoke-tested; Windows archive and PE format were verified but not GUI-run on the Linux server.

## Minimal package-manifest pitfall

For hand-authored minimal Unity `Packages/manifest.json`, built-in module dependencies must cover runtime API use. If code uses `GUI`/`GUIStyle`/`OnGUI`, include `com.unity.modules.imgui`. If it uses `AudioListener` or other audio APIs, include `com.unity.modules.audio`; alternatively remove unused audio components. Do not omit required modules simply to make the manifest small.

## Share bundles through Erugo

Unity desktop output is a bundle, not a standalone executable: preserve the executable beside its `<Game>_Data/` directory and `UnityPlayer` library/DLL.

- Linux: archive the whole output as `.tar.gz`.
- Windows: archive the whole output as `.zip`; include a short `README.txt` with extract/run instructions and controls.
- Generate `SHA256SUMS.txt`, validate archives (`tar -tzf`, `unzip -t`), then publish to:

  ```text
  /home/semyon/server-stacks/fileshare/erugo-storage/app/public/bin/<app>/<version>/
  https://fileshare.semyon.ie/storage/bin/<app>/<version>/
  ```

- Always download the public URLs back and run `sha256sum -c SHA256SUMS.txt`.
- Publish immutable versioned paths. If an existing public path is CDN-cached with an older file, do not claim the overwritten object was verified; publish a new version directory and verify that URL instead.
