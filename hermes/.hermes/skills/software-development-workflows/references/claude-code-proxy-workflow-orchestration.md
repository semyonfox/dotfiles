# Claude Code UI with a local multi-provider proxy

## Scope

Use this when Claude Code is retained as the **client/agent surface** (its TUI, system prompt, tool loop, context handling, CLAUDE.md, hooks, skills, subagents and workflows), while a local proxy routes requests to a non-Claude upstream model.

## Separate the two controls

There are two fundamentally different knobs. Never conflate them.

1. **Upstream model reasoning** — provider/model-specific. With CLIProxyAPI, ordinary levels are encoded in the model identifier, for example `gpt-5.6-sol(high)`. Only expose levels actually supported by that specific upstream model.
2. **Claude Code workflow orchestration** — client-side. `ultracode` is not a model suffix or an upstream reasoning tier. It enables Claude Code dynamic workflows and pairs them with the client’s high-reasoning workflow mode.

Do not translate `ultracode` into `ultra`, `max`, or any other provider effort. Those are different products and can compound cost.

## Wrapper contract

A robust explicit wrapper should accept one effort argument but dispatch by class:

```text
claudex --model MODEL --effort high
  -> claude --model MODEL(high)

claudex --model MODEL --effort ultracode
  -> claude --model MODEL --effort ultracode
```

The latter must leave `MODEL` unsuffixed. Test this using a stub `claude` binary placed first in `PATH`; assert the exact argv without sending a billable request.

## Model-aware capability menus

Do not expose a single generic list for a routed family if the native provider has per-model differences. Use the current native provider capabilities as the local source of truth, then represent the intersection of:

```text
configured proxy-allowed levels ∩ levels supported by selected model
```

Keep the proxy provider’s default effort unset unless the user explicitly chooses a default. A UI default can silently become a billable request override.

## Usage guidance

- Ordinary TUI session: run the wrapper with a selected model and no effort override.
- Hard bounded task: select an explicit provider reasoning level.
- Broad audit, migration, or independent verification lanes: start `ultracode` in the Claude Code client, then give a bounded task with a clear stop condition.
- Do not leave workflow orchestration on for routine edits. It can fan out and consume substantially more usage.

## Verification boundary

A CLI parse probe (`claude --effort ultracode --version`) only proves client support. A fake executable proves wrapper argv. Neither proves that a proxy and an authenticated upstream accept the resulting live request. Before declaring the route complete, make a small explicitly approved request and inspect sanitized proxy logs/effective payloads.
