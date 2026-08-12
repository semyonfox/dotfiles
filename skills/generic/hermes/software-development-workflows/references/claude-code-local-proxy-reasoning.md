# Claude Code through a local compatibility proxy

## Goal
Use Claude Code's UX/agent loop with explicitly selected non-Claude upstream models while preserving provider-native reasoning controls.

## Safe boundary

```text
claude   -> native Claude authentication, no proxy variables
claudex  -> ANTHROPIC_BASE_URL=http://127.0.0.1:8317 -> local proxy -> chosen provider
```

Run the proxy localhost-only. Keep its management UI/API disabled unless explicitly required. Store a generated local client token in a `0600` file. Do not send OAuth authorization URLs to group chats.

## Effort pass-through pattern

CLIProxyAPI documents thinking controls via a parenthesised model suffix:

```text
MODEL(low)
MODEL(medium)
MODEL(high)
MODEL(xhigh)
MODEL(auto)
MODEL(none)
```

For OpenAI/Codex/OpenRouter protocols it translates a level into `reasoning_effort` or `reasoning.effort`; for Gemini it uses a thinking config; for Claude it uses a thinking budget. Numeric budgets are provider-native and are not equivalent to OpenAI effort levels.

A wrapper should accept:

```bash
claudex --model MODEL --effort high
```

and invoke Claude Code with:

```bash
claude --model 'MODEL(high)'
```

Do **not** pass the same `--effort` through to Claude Code or set `CLAUDE_CODE_ALWAYS_ENABLE_EFFORT` / `CLAUDE_CODE_EFFORT_LEVEL` for that proxied run: the upstream suffix is the authoritative reasoning selection.

No `--effort` must leave the model unchanged so the provider default applies. Reject unsupported inputs (for example `max` if the proxy has no documented equivalent) rather than silently upgrading them to `xhigh`.

## Anti-patterns

- Defaulting the wrapper to `xhigh`.
- Mapping every conceptual Claude tier and subagent tier to one expensive upstream model.
- Global `ANTHROPIC_BASE_URL` settings that redirect ordinary `claude` sessions.
- Assuming a model alias implies a reasoning level.
- Treating proxy installation as success before a small authenticated request proves effective model and effort.

## Verification

1. Shell-parse the wrapper.
2. Substitute a harmless `claude` stub in `PATH` and assert:
   - `--effort medium` becomes `MODEL(medium)`;
   - no effort leaves `MODEL` untouched;
   - unsupported levels fail;
   - no Claude-local effort env vars are exported in the proxied call.
3. Confirm normal shell/native `claude` has no proxy base URL or token.
4. Confirm systemd service, listener, and local `/v1/models` authentication.
5. Complete user OAuth privately, then run one tiny request and inspect the sanitised proxy log for actual upstream model plus reasoning field.

## Sources

- CLIProxyAPI thinking configuration: https://github.com/router-for-me/CLIProxyAPIDocs/blob/main/docs/en/configuration/thinking.md
- CLIProxyAPI sample config: https://github.com/router-for-me/CLIProxyAPI/blob/main/config.example.yaml
