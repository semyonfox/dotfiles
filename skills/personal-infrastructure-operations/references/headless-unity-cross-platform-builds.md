# Headless Unity cross-platform build and PC launch

Use for a Unity game/prototype that should be built on Semyon's headless server and delivered/run on his Linux PC or shared with Windows friends.

## Server-side toolchain (no desktop editor UI)

Unity's standalone CLI is suitable for a headless build worker. Install it user-locally from Unity's current official CLI installer, authenticate through an **SSH terminal owned by Semyon** (do not paste an OAuth/browser sign-in URL in a group chat), then confirm both account and license state:

```bash
unity auth status
unity license activate --personal --accept-eula --non-interactive
unity license status --format json
```

Install the exact `ProjectSettings/ProjectVersion.txt` editor version. For archive versions, include the project's revision/changeset. Query available modules after installing the editor; Linux Mono is normally bundled on Linux, while a Windows share build needs `windows-mono`:

```bash
unity install <version> -c <changeset> --non-interactive --accept-eula --yes
unity install-modules -e <version> -l
unity install-modules -e <version> -m windows-mono --non-interactive --accept-eula --yes
```

Prove licensing with a real batch editor start before attempting the project build:

```bash
<Editor>/Unity -batchmode -nographics -quit -logFile /tmp/unity-license-smoke.log
```

## Build and verify

Build sequentially (not parallel editor processes) to avoid transient player-connection/REST-port conflicts:

```bash
<Editor>/Unity -batchmode -nographics -quit \
  -projectPath /path/to/project \
  -buildLinux64Player /output/linux/Game.x86_64 \
  -logFile /output/linux-build.log

<Editor>/Unity -batchmode -nographics -quit \
  -projectPath /path/to/project \
  -buildWindows64Player /output/windows/Game.exe \
  -logFile /output/windows-build.log
```

Verify the Linux executable with `file`, execute it briefly with `timeout ... -batchmode -nographics`, and inspect logs. Verify Windows output as a `PE32+` executable and archive integrity; do not claim a GUI Windows runtime test from the Linux server.

Archive the executable **with** its Unity `*_Data` directory and player libraries. Use a Windows ZIP and Linux `.tar.gz`, include a short `README.txt`, generate `SHA256SUMS.txt`, publish versioned immutable paths, then download both public URLs back and run `sha256sum -c`.

## Common project fixes found by real builds

- A minimal custom `Packages/manifest.json` must include every built-in module directly used by scripts. Legacy `OnGUI`/`GUIStyle` needs `com.unity.modules.imgui`; do not assume every UnityEngine type is automatically linked.
- If a scene creates all materials dynamically, shaders can be stripped from the player, producing pink geometry. Generate/reference a real material asset under `Assets/Resources/` using the intended shader (for example Standard) and explicitly create runtime materials from that shader before release.
- `AddComponent<T>()` invokes `Awake` immediately. If a controller looks up a child camera in `Awake` but the camera is created immediately afterward, it will null-reference. Put dependent lookup in `Start` or initialize after all children exist.
- `GUI.skin` is only legal inside `OnGUI`. Lazily create GUI styles from `OnGUI`, not an arbitrary `Start` method.

## PC extraction and graphical launch

Copy the verified server bundle directly to `~/Games/<game-version>/`, verify the archive checksum before extraction, then preserve the expected sibling layout. For a Hyprland/Wayland PC, launch through the live compositor rather than a detached SSH process:

```bash
XDG_RUNTIME_DIR=/run/user/1000 \
WAYLAND_DISPLAY=<wayland-socket> \
HYPRLAND_INSTANCE_SIGNATURE=<signature> \
hyprctl dispatch exec '"/home/semyon/Games/<game>/Game.x86_64" -logFile "/home/semyon/Games/<game>/player.log"'
```

Check the game process and player log for exceptions. A headless smoke test does not prove shaders/UI look correct; capture a real desktop screenshot only while the PC is unlocked, and do not expose the screenshot or bypass the lock screen.