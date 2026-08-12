# Security-sensitive PR review notes

Use this when triaging or merging PRs that affect authentication, rate limiting, abuse controls, secrets, logging, or externally visible error responses.

## Public response vs internal observability

When a PR changes defensive controls, check both sides explicitly:

- **Public/client response:** should be generic and avoid exposing internal control state. Avoid messages like `rate limiting backend unavailable`, `Redis unavailable`, `token store failed`, or `abuse protection disabled`. Prefer a boring message such as `Service temporarily unavailable. Please try again shortly.`
- **Status/headers:** use appropriate semantics (`503` + `Retry-After` for temporary defensive-control outage; `429` + rate-limit headers for actual limit exhaustion).
- **Internal logs:** should keep the actionable detail: category/control name, underlying error, public status, retry-after, and any non-PII identifiers. Hash or omit PII.
- **Metrics:** record a machine-actionable event, e.g. `password-reset:store-unavailable`, so monitoring can distinguish control outage from normal user throttling.
- **Tests:** assert both the non-revealing public response and the detailed internal logger/metric call.

## Fail-closed rate limiting pattern

For security-sensitive flows, fail closed when the shared rate-limit store is unavailable instead of falling back to per-process memory:

- good candidates: register, password reset, password token verify, destructive vault/account operations
- usually fail open/fallback candidates: chat, extraction, normal uploads, lower-risk UX actions

Patch shape:

```ts
if (rule.failClosedOnStoreError) {
  logger.error("redis rate limit failed for fail-closed category", {
    category,
    error,
    publicStatus: 503,
    retryAfterSeconds: 30,
  });
  void Metrics.rateLimitViolation(`${category}:store-unavailable`);
  return NextResponse.json(
    { error: "Service temporarily unavailable. Please try again shortly." },
    { status: 503, headers: { "Retry-After": "30" } },
  );
}
```

Do not expose `Redis`, `rate limiting`, `store unavailable`, or equivalent implementation details in the response body.