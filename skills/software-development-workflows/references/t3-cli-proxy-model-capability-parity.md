# T3 Code + CLIProxyAPI: capability parity without unsafe defaults

## Problem

A local proxy exposed OpenAI/Codex models through Claude Code (`claudex`) inside T3. A generic proxy reasoning list initially exposed only `low`, `medium`, and `high`, even though T3's live Codex provider advertised model-specific levels. That made the proxy UI inconsistent and tempted unsafe semantic translations from Claude-specific effort controls.

## Rule

Treat the target provider's **live model capability snapshot** as the source of truth for the proxy model picker. Do not copy Claude model capabilities and do not use one global effort list when models differ.

At the time captured here, the locally authenticated Codex provider advertised:

| Model | levels | native default |
|---|---|---|
| `gpt-5.6-sol` | `low`, `medium`, `high`, `xhigh`, `max`, `ultra` | `low` |
| `gpt-5.6-terra` | `low`, `medium`, `high`, `xhigh`, `max`, `ultra` | `medium` |
| `gpt-5.6-luna` | `low`, `medium`, `high`, `xhigh`, `max` | `medium` |

The proxy selector should expose the matching levels per model, but must have **no selected/default effort**. An absent selection is meaningful: send no effort suffix and preserve the upstream/provider default. Do not set the picker default merely because native Codex has one; that turns browsing/starting a session into an explicit override.

## Implementation shape

1. Keep a distinct T3 compatibility profile such as `cliproxy`; do not overload the native Claude profile.
2. Use a per-model capability map and construct each custom model's picker separately. A single `proxyReasoningLevels` config can act as an allowlist, but intersect it with that model's supported set.
3. Preserve native Claude provider behavior unchanged. Never expose `ultrathink`/`ultracode`, Claude context-window controls, or Claude normalization (for example `xhigh → max`) in the proxy profile.
4. The shim should forward the selected provider level literally as `MODEL(LEVEL)` and should not also set Claude Code's effort env/flag.
5. When a T3 cache was populated before a capability change, back it up/remove only the derived provider cache, restart the T3 service, and read the regenerated snapshot. Do not assume an existing cache will shrink stale built-in models on its own.

## Verification

- Inspect the regenerated T3 provider cache and assert exact model-to-level arrays.
- Assert no `currentValue` is emitted for the proxy effort descriptor.
- Test the wrapper with a stub `claude` executable first in `PATH`; verify both no-level and explicit-level argv, then syntax-check it with `bash -n`.
- Typecheck, format/lint, run the server tests, build, deploy the built distribution, restart the user service, and check active status.
- Do not make a billable upstream request until credentials are deliberately authorized; offline forwarding verification is still useful.
