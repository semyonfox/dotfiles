# T3 Code → CLIProxyAPI reasoning pass-through

## Purpose

Use a local Claude-agent-compatible proxy route without contaminating native Claude use or silently forcing expensive reasoning:

```text
T3 `claudex` instance → wrapper → localhost CLIProxyAPI → authenticated upstream
```

Keep native `claude` as a separate T3 provider instance and keep CLIProxyAPI loopback-only unless remote access is explicitly required.

## Semantics

CLIProxyAPI documents `model(level)` suffixes. It strips the suffix and translates it into the target provider's native thinking/reasoning field. No suffix means **no override**. For OpenAI/Codex Responses, the intended result is `reasoning.effort=<level>`.

Portable documented levels: `minimal`, `low`, `medium`, `high`, `xhigh`, `auto`, `none`. Do not offer every value blindly: providers/models validate supported levels and can reject unsupported values. Start with levels verified for the selected upstream/model, then expand after a bounded live test.

Do not leak Claude-only semantics into the proxy profile:

- `ultrathink` is prompt injection, not a provider reasoning field.
- `ultracode` is a Claude Code workflow setting paired with `xhigh`.
- `max` is not a generic portable level for the proxy UI.
- T3's normal Claude driver can remap `xhigh` to `max` for non-Claude model IDs; proxy routes must bypass that mapping.

## Durable T3 implementation shape

A real reasoning selector needs a dedicated compatibility profile in the T3 Claude driver because ordinary `customModels` have empty capabilities. The profile should:

1. expose custom proxy models only;
2. give each one a non-default `effort` descriptor with its approved levels;
3. pass selected effort unchanged to the wrapper;
4. suppress Claude-specific effort/context/workflow options;
5. make `--version` work without model, proxy key, or upstream auth so T3 health checks do not fail;
6. report local provider readiness separately from upstream authentication, which is only proven by a bounded real request.

Never patch a derived T3 cache file. Persist config in T3 settings and maintain the source patch/build separately from the installed package. After an upstream T3 update, rebuild/redeploy and rerun the probes below.

## Offline verification

Use a fake `claude` executable in `PATH` and assert:

```text
wrapper --version                         → native version, no proxy contact
wrapper --model MODEL                     → MODEL, no suffix
wrapper --model MODEL --effort medium     → MODEL(medium)
wrapper --model MODEL --effort max        → loud rejection
```

Then restart T3 and inspect its regenerated provider cache/snapshot. Confirm:

- status is `ready` or an explicit local-health state;
- only proxy custom models appear;
- effort choices have **no** `currentValue`/default;
- no `max`, `ultracode`, or `ultrathink` appears.

After private upstream login, perform only two bounded requests: one no-override request and one low/medium request. Verify proxy logs show suffix absence/presence and the upstream accepted it before enabling further levels.
