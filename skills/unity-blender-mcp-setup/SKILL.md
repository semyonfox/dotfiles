---
name: unity-blender-mcp-setup
description: "Use when working on Semyon's Unity/Blender MCP setup."
version: 1.0.0
created_by: agent
platforms: [linux]

metadata:
  harness: [hermes]
---

# Unity + Blender MCP environment (Semyon)

## Installed baseline

- Host: Ubuntu 24.04.
- Unity Hub is installed system-wide from Unity's official Debian repository. Verify with:
  ```bash
  dpkg-query -W -f='${Status} ${Version}\n' unityhub
  readlink -f ~/.local/bin/unityhub
  ```
  The user-local command is a symlink to `/usr/bin/unityhub`; do not replace it with an AppImage/user-extracted package.
- Blender is the official portable **5.2.0 LTS** binary at `~/.local/opt/blender-5.2.0`, linked as `~/.local/bin/blender`. Verify with `blender --version`.
- This agent execution shell has no GUI `$DISPLAY`; attempting `unityhub --version` headlessly can fail with an Ozone/X11 error even when the desktop installation is healthy. Verify Unity Hub by package state rather than treating that headless error as an install failure.

## MCP selections

Neither Blender Foundation nor Unity Technologies currently ships a first-party MCP integration.

- **Blender:** `ahujasid/blender-mcp` (community-maintained, widely adopted). Checked-out source: `~/Applications/mcp-sources/blender-mcp`; its `addon.py` is installed and enabled in Blender user preferences.
- **Unity:** `CoplayDev/unity-mcp` (community-maintained, MIT, active, supports Unity 2021.3 LTS through 6.x). Source: `~/Applications/mcp-sources/unity-mcp`. Python server package: `mcpforunityserver` launched as `uvx --from mcpforunityserver mcp-for-unity --transport stdio`.

Both run through the absolute `~/.local/bin/uvx`, avoiding GUI-PATH failures.

## Agent-client registrations

The Blender and Unity MCP servers are globally configured for:

- Hermes: `~/.hermes/config.yaml` under `mcp_servers`.
- Claude Code: user-scope MCP registrations (`claude mcp list`).
- Codex: `~/.codex/config.toml` (`codex mcp list`).
- OpenCode: `~/.config/opencode/opencode.json` (`opencode mcp list`).

Check all four before modifying. Preserve absolute `uvx` commands, Blender's `BLENDER_HOST=localhost` and `BLENDER_PORT=9876`, and Unity's stdio args.

## Unity project activation

Installing Hub alone does not install an Editor or the project-side bridge.

1. User signs into Unity Hub through their desktop session and installs a supported Unity LTS/Unity 6 editor.
2. For each Unity project, add the UPM dependency:
   ```text
   https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#v10.0.0
   ```
3. In the Unity editor, use **Window → MCP for Unity → Configure All Detected Clients**.
4. Restart the client agent after client-config changes and open the project/editor before attempting Unity MCP tools.

For multiple concurrent agents/editors, use Unity MCP's HTTP/multi-instance path rather than competing stdio instances. Keep the default stdio setup for one active editor/client.

## Blender activation

Open Blender graphically. In the 3D viewport sidebar (`N`), use the **BlenderMCP** tab to connect. The server can expose tools without an editor connection, but scene actions require the open GUI editor and add-on socket on localhost:9876. Do not attach multiple MCP clients to the same Blender bridge simultaneously.

## Verification

```bash
blender --version
hermes mcp list
claude mcp list
codex mcp list
opencode mcp list
```

Do not install n8n or Unreal MCP opportunistically: n8n's official MCP surface belongs to an actual configured n8n instance, while Unreal choices are version/project-dependent and largely community or experimental. Confirm the requested project and Unreal version first.
