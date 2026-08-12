# Client config and validation notes

## Known-good stdio commands

Use the real absolute `uvx` path when agent clients are launched outside an interactive shell.

```text
# BlenderMCP
/home/semyon/.local/bin/uvx --python 3.11 blender-mcp

# MCP for Unity
/home/semyon/.local/bin/uvx --from mcpforunityserver mcp-for-unity --transport stdio
```

The Blender bridge can optionally use:

```text
BLENDER_HOST=localhost
BLENDER_PORT=9876
```

## Native client forms

```bash
# Claude Code: user-wide registration
claude mcp add --scope user blender -- /absolute/path/to/uvx --python 3.11 blender-mcp
claude mcp add --scope user unity -- /absolute/path/to/uvx --from mcpforunityserver mcp-for-unity --transport stdio

# Codex
codex mcp add blender --env BLENDER_HOST=localhost --env BLENDER_PORT=9876 \
  -- /absolute/path/to/uvx --python 3.11 blender-mcp
codex mcp add unity -- /absolute/path/to/uvx --from mcpforunityserver mcp-for-unity --transport stdio

# Hermes config shape (lists/maps must be YAML values, not quoted JSON strings)
mcp_servers:
  blender:
    command: /absolute/path/to/uvx
    args: [--python, '3.11', blender-mcp]
    env: {BLENDER_HOST: localhost, BLENDER_PORT: '9876'}
  unity:
    command: /absolute/path/to/uvx
    args: [--from, mcpforunityserver, mcp-for-unity, --transport, stdio]
```

## What verification proves

- `claude mcp list`, `codex mcp list`, `opencode mcp list`, and `hermes mcp list` prove client registration and server discovery.
- A BlenderMCP server can enumerate its tools even while no Blender GUI is connected. It cannot perform scene work until the Blender add-on is active in a GUI session.
- MCP for Unity can enumerate its tools even with no Unity Editor attached. It cannot safely mutate a project until the package is installed in that project and an active instance is selected.
- Do a harmless read-only tool call against the actual running editor before claiming installation is complete.
