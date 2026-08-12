# T3 Code → `claudex` → CLIProxyAPI integration

Use this when T3 Code should drive non-Claude models through a Claude Code-compatible executable shim, while ordinary `claude` remains native.

## Architecture

```text
T3 `claudeAgent` provider instance
  → user-local `claudex` wrapper
  → CLIProxyAPI on 127.0.0.1:8317
  → Codex OAuth or an explicitly configured API-key upstream
```

Keep CLIProxyAPI loopback-only when T3 runs on the same host. A `0.0.0.0` bind is unnecessary for this integration and turns the local client bearer token into a LAN credential. If remote clients are genuinely needed, put an authenticated HTTPS gateway (for example Cloudflare Access) in front of it rather than exposing raw HTTP.

## Thinking semantics

CLIProxyAPI supports a provider-neutral model suffix:

```text
model(minimal|low|medium|high|xhigh|auto|none)
```

It strips the suffix and translates it for the target provider: OpenAI/Codex/OpenRouter receive `reasoning_effort` / `reasoning.effort`; Gemini receives a thinking budget; Claude API receives a normalized thinking budget. A bare model must remain bare so the upstream provider uses its own default.

Do not treat Claude Code terms as portable:

- **`ultrathink`** is T3 prompt injection: it prefixes the user prompt with `Ultrathink:`. It is neither a skill nor a native reasoning setting.
- **`ultracode`** is a Claude-specific mode paired with `xhigh` plus Claude CLI settings.
- **`max`** has no truthful generic CLIProxyAPI level equivalent. Do not silently map it to `xhigh`.

## T3 custom-model pitfall and durable design

T3's built-in Claude model capability descriptors can remap effort values for Claude compatibility (including `xhigh → max` for some models). Do **not** add those descriptors to generic proxied custom models just to obtain a reasoning dropdown.

Instead, use explicit, optional model lanes in T3 custom-model settings:

```text
gpt-5.6-sol          # provider default, no suffix
gpt-5.6-sol@medium   # wrapper converts to gpt-5.6-sol(medium)
gpt-5.6-sol@high     # wrapper converts to gpt-5.6-sol(high)
gpt-5.6-luna@low     # cheap bounded lane
```

The wrapper must validate `@level` against the CLIProxyAPI whitelist, reject `@max`/unknown values, and reject simultaneously specifying `@level` plus `--effort`. Keep the picker short; only add lanes actually intended for use.

## Wrapper requirements

1. Require an explicit model for real runs; never silently fall back to a premium model.
2. Support `--version` before model/key/proxy checks because T3 probes provider executables with it.
3. Translate `--effort <supported-level>` and/or a trailing `@level` to exactly one CLIProxyAPI parenthesized suffix.
4. Unset inherited proxy and forced-Claude-effort variables before configuring the explicit proxy route.
5. Native `claude` must not inherit `ANTHROPIC_BASE_URL` or proxy credentials.

## Verification sequence

1. Stub the real `claude` executable and assert:
   - `claudex --version` needs no proxy/key;
   - a bare model remains bare;
   - `@low` becomes `(low)`;
   - `max`, bogus values, and double specification fail loudly.
2. Refresh/restart T3 and ensure the provider no longer shows "failed to run". Pre-auth capability checks may be a warning, but must not invoke a default model.
3. After the human completes upstream OAuth or provides a configured API provider, run only two bounded requests in a scratch directory: bare cheap lane, then cheap `@low` lane. Inspect CLIProxyAPI logs to verify suffix presence/absence and effective upstream route.
4. Re-run wrapper stub tests after T3 upgrades. Keep all integration changes in the wrapper and `~/.t3/userdata/settings.json`; do not patch the installed `t3/dist` bundle.

## Billing boundary

- A CLIProxyAPI OAuth route consumes that upstream subscription/account allowance; Claude Code is only the client harness.
- An API-key route is billed by that provider's token pricing.
- Native `claude` continues using Anthropic auth independently.
- T3 thread-adjacent operations such as title generation can use the selected thread provider, so they are small but real proxy usage.
- Audit existing native T3 defaults separately: an existing `xhigh` Codex default can consume quota regardless of this proxy integration.
