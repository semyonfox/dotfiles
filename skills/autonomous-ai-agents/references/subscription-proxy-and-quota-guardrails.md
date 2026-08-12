# Subscription Proxy and Quota Guardrails

Use this reference when evaluating or configuring a local LLM proxy that translates one agent CLI protocol into another, especially when it can route OAuth/subscription-backed Claude Code, Codex, Gemini, or similar accounts.

## Core distinction

A protocol/account proxy is **not** a budget controller. It may unify endpoints, model aliases, credential pools, retries, cooldowns, and session affinity, but that can obscure which subscription or API account is being charged. Do not describe it as a safe "API key router" until the actual route and spend controls are verified.

## Safe design rules

1. **Keep native subscription CLIs native by default.** `claude`, `codex`, and Gemini CLI should use their own provider authentication unless a user deliberately starts an explicitly named proxy session.
2. **Use explicit routes, never ambient cross-provider rewrites.** Prefer commands/profiles such as `claude-native`, `codex-native`, `api-cheap`, and `api-review`. Do not silently set an Anthropic/OpenAI base URL in a general wrapper.
3. **Premium reasoning is opt-in.** Default to provider defaults or low/medium effort. Require an explicit per-run flag for `high`/`xhigh`; never make `xhigh` a wrapper default.
4. **Preserve model tiers.** A fast/small route and subagent route must remain cheap. Never map Opus/Sonnet/Haiku-style aliases and every subagent to the same premium model unless the user explicitly chose that for a bounded task.
5. **Cap concurrency before enabling routing.** Set a conservative worker/subagent cap, use staged waves for broad work, and avoid parallel retries against the same subscription.
6. **Install hard circuit breakers before production use.** Require per-provider/account daily and weekly caps, per-task request/token ceilings, a 429 cooldown, premium-model deny-by-default for cron/subagents, alerts before the threshold, and a hard stop at the agreed limit.
7. **Verify cost provenance with a live probe.** Before any sustained work, issue a tiny request from each intended client route, inspect proxy and provider logs with secrets redacted, and prove: client → endpoint → provider/account → model → effort → quota/billing lane.
8. **Keep management local.** Bind the proxy and management endpoints to loopback unless a separately reviewed access-control and network design exists. Treat OAuth credentials, client API keys, request logs, and management keys as secrets.

## Thinking/reasoning settings

Reasoning effort is provider- and protocol-specific. A proxy can translate, override, drop, or force fields such as `reasoning.effort`; model labels can also be aliases rather than proof of the actual upstream model. Verify the effective upstream request rather than trusting a wrapper label.

Suggested policy:

| Work | Default effort |
|---|---|
| Simple edits, search, diagnostics | provider default / low |
| Normal implementation, debugging, review | medium |
| Difficult but well-scoped investigation | high, explicitly requested |
| `xhigh` / maximum | one-off escalation with a stated stop condition |

## Failure-pattern checklist

If a user reports an implausibly fast quota burn:

- Identify the actual client wrapper and its environment variables.
- Check whether an Anthropic/OpenAI base URL was redirected to a local proxy.
- Inspect default model, fast model, subagent model, effort, tool concurrency, and delegation concurrency.
- Check whether aliases for different quality/cost tiers collapse to one premium route.
- Count retries and concurrent workers separately from successful requests.
- Inspect current service, listener, config, and logs; do not infer that a proxy is in the path because it exists on the machine.
- Immediately offer containment: stop proxy/background workers, revoke proxy route from wrappers, lower concurrency, and prevent automatic retry dogpiles. Make destructive removal only with user authorization.

## External source notes

CLIProxyAPI's official project describes OpenAI/Gemini/Claude/Codex/Grok-compatible interfaces, OAuth/CLI account support, multi-account balancing, and OpenAI-compatible upstreams. Its example config exposes retry/cooldown and payload rules, but those are routing mechanics rather than user budget guarantees. Official docs: <https://github.com/router-for-me/CLIProxyAPI>, <https://github.com/router-for-me/CLIProxyAPI/blob/main/config.example.yaml>, <https://help.router-for.me/management/api>.
