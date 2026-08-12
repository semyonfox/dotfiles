# T3 `claudex` → CLIProxyAPI provider profile

## Use case

T3 Code’s `claudeAgent` driver can run a separate executable (`claudex`) which points Claude Code at a localhost-only CLIProxyAPI endpoint. This makes T3 the control plane/UI while CLIProxyAPI chooses an OAuth/API-key upstream. Keep native `claude` as a separate untouched provider instance.

## Do not infer the proxy from the executable name

T3's standard Claude profile contains Claude-specific reasoning semantics. A dedicated per-instance profile (for example `compatibilityProfile: "cliproxy"`) is the clean long-term design:

- native profile: existing built-in Claude models/capabilities
- cliproxy profile: only configured custom models and provider-neutral reasoning controls

Avoid editing generated provider caches or installed `dist/bin.mjs`; they are regenerated/replaced on refresh/update. Make the source change in the tracked T3 source, build/install it deliberately, and run a post-upgrade canary.

## Reasoning semantics

CLIProxyAPI handles a model suffix:

```text
model(level)
```

Supported provider-neutral levels:

```text
minimal, low, medium, high, xhigh, auto, none
```

No selected level must result in **no suffix** and no effort field: that means provider default. `none` is an explicit override, not a default.

For a cliproxy instance, the T3 selector should expose those seven values with **no default/current value**. It must pass the selected value unchanged to the wrapper, which translates it to `model(level)`.

Do not expose or transform these Claude-specific values for proxied models:

- `max`: not a generic CLIProxyAPI effort equivalent
- `ultracode`: Claude Code setting coupled to `xhigh`
- `ultrathink`: T3 implements it as a literal `Ultrathink:` prompt prefix, not a native provider reasoning setting

T3's ordinary Claude normalization can rewrite `xhigh` to `max` for non-allowlisted models. The cliproxy profile must bypass that normalization, as well as Ultracode settings and Ultrathink prompt handling.

## Wrapper requirements

The wrapper should:

1. Require an explicit model for real work.
2. Convert a validated selected `--effort` into `model(level)`; do not also force Claude Code's own effort level.
3. Reject unknown levels and `max` loudly.
4. Unset stale `ANTHROPIC_*` and `CLAUDE_CODE_*` routing/effort overrides before setting the local proxy endpoint.
5. Support `--version` without requiring a model, proxy key, or proxy request because T3 health-checks the configured binary with that flag.

## Validation matrix

Before provider OAuth/live traffic:

- wrapper syntax check
- `claudex --version` returns the native Claude version without proxy contact
- no selection: child sees `--model model`, no `--effort`
- each supported selection: child sees `--model model(level)`, no client-local effort override
- assert `xhigh` never becomes `max`
- reject `max`, `ultracode`, `ultrathink`, and unknown values before spawning
- provider snapshot exposes only the intended custom models and seven generic levels; native Claude capability set is unchanged
- restart/refresh T3 and confirm the profile survives regenerated cache/snapshot state

Only after that, authenticate an upstream and run two bounded requests: bare model, then low effort. Inspect proxy logs for the exact upstream model/suffix and stop.

## Billing boundary

CLIProxyAPI traffic is billed to its authenticated upstream account: Codex OAuth consumes its ChatGPT/Codex quota; API-key upstreams bill their provider account. Claude Code is only the client harness on the cliproxy route. T3 background operations tied to a cliproxy thread (such as title generation) also consume that selected upstream.
