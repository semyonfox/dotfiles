---
name: editor-mcp-integration
description: "Use for Blender, Unity, or Unreal MCP setup."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Editor MCP Integration

## Purpose

Set up MCP bridges for stateful creative/game editors across Hermes, Claude Code, Codex, OpenCode, and compatible clients. Use this for Blender, Unity, and Unreal requests where the user wants an AI agent to inspect or control an already-running editor.

## Operating Model

1. **Separate editor bridges from build automation.** MCP is for scene, asset, viewport, and editor-state work. Use the native CLI, Python/C# tooling, commandlets, CI, or reproducible scripts for builds, renders, cooking, packaging, tests, and bulk conversion.
2. **Prefer official editor distributions.** Validate download source and checksum when published. Do not represent a community MCP as vendor-official.
3. **Choose a maintained bridge with explicit client support.** Inspect its repository/release cadence, license, supported editor versions, client configuration, and transport model before installing.
4. **Configure every requested client using its native configuration mechanism.** Never hand-copy one client’s JSON shape to another.
5. **Verify the full stack in layers:** binary/version → bridge package/server startup → each client’s MCP listing/health → actual editor add-on/package connection. Do not claim editor control works if only server discovery succeeded.

## Supported Client Registration Patterns

Use absolute executable paths for GUI/agent clients where PATH may differ from an interactive shell.

| Client | Preferred registration |
|---|---|
| Hermes | `hermes mcp add` where non-interactive, otherwise `mcp_servers` in `~/.hermes/config.yaml`; restart/reset the consuming agent after config changes. |
| Claude Code | `claude mcp add --scope user <name> -- <command> <args...>` for system-wide user registration. |
| Codex | `codex mcp add <name> -- <command> <args...>`; inspect with `codex mcp list`. |
| OpenCode | Update the top-level `mcp` map in its JSON config or use its MCP command; inspect with `opencode mcp list`. |

For every stdio bridge, configure only narrowly-scoped environment variables. Do not forward an agent’s complete environment or unrelated credentials.

## Blender

### Recommended bridge

Use `ahujasid/blender-mcp` when a full scene-control bridge is wanted. It is widely maintained and exposes an add-on plus a Python `uvx` MCP server, but it is **community software**, not a Blender Foundation release.

### Setup

1. Install a current official Blender release and make the executable available consistently (for example through `~/.local/bin/blender`).
2. Install its `addon.py` through Blender Preferences and enable it. Confirm persistence by starting Blender again and importing/enabling the add-on.
3. Register the MCP server with an absolute `uvx` path:

```text
<uvx> --python 3.11 blender-mcp
```

4. Pass only `BLENDER_HOST=localhost` and `BLENDER_PORT=9876` if defaults are not sufficient.
5. Start Blender normally with a GUI and activate the BlenderMCP connection from its sidebar. Headless Blender can validate import/installation but cannot serve interactive editor commands.

### Safety

The bridge provides arbitrary Blender Python execution. Save/version the `.blend` before broad edits and prefer narrow requests. Do not attach multiple simultaneous clients to a single Blender bridge.

## Unity

### Recommended bridge

Use `CoplayDev/unity-mcp` / **MCP for Unity** for a maintained open-source editor bridge. It is MIT-licensed, supports Unity 2021.3 LTS through Unity 6.x, and has dedicated configurators for Claude Code, Codex, and OpenCode. It is not affiliated with Unity Technologies.

### Setup

1. Install Unity Hub and then a licensed Unity LTS or Unity 6 editor through the Hub. Hub presence alone does not provide an editor.
2. In **each Unity project**, install the UPM package, pinned to a tested release:

```text
https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#v10.0.0
```

3. Start the project and use **Window → MCP for Unity → Configure All Detected Clients**, or register the stdio bridge explicitly:

```text
<uvx> --from mcpforunityserver mcp-for-unity --transport stdio
```

4. For concurrent agents or multiple Unity Editor instances, use MCP for Unity’s HTTP/multi-instance transport rather than competing stdio servers.
5. Confirm a live Unity instance is selected before mutating scenes or assets. Server tool discovery by itself does not prove the Unity package is connected.

## n8n and Unreal Boundaries

- **n8n:** its official MCP capability is typically exposed by the user’s own n8n instance/workflow endpoint. Do not install a generic workflow-writing MCP and present it as an official n8n control plane. A node/documentation bridge may be useful separately, but credentials, environment, deployment and backups remain instance-specific.
- **Unreal:** treat editor-control MCP plugins as community/experimental unless the user identifies a supported official Epic integration and exact UE version. Prefer Unreal Python, commandlets, Unreal Automation Tool, and native project plugins for repeatable production automation.

## Verification Checklist

- [ ] Editor binary exists and its version was actually run.
- [ ] Add-on/package is installed in the target editor/project.
- [ ] The bridge command starts and exposes expected tools.
- [ ] Hermes, Claude Code, Codex, and OpenCode report the configured bridge enabled/connected as requested.
- [ ] A running editor instance accepts a harmless read-only command before mutations.
- [ ] Client/editor concurrency matches the bridge transport model.

## Reference

See `references/client-config-and-validation.md` for concrete command forms and the distinction between server discovery and live editor connectivity.
