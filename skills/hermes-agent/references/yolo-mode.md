# Persistent YOLO mode

Use this when the user wants Hermes to stop asking for command approvals by default.

Recommended setup:
- `hermes config set approvals.mode off`
- Add `HERMES_YOLO_MODE=1` to `~/.hermes/.env` for new shells / future sessions
- Start a fresh Hermes session or restart the gateway/CLI so the setting is picked up

Notes:
- This disables command approval prompts, not secret redaction.
- `hermes --yolo ...` is the one-shot equivalent for a single invocation.
- If a session still prompts after the config change, assume it is an already-running process and restart it rather than re-toggling config.
