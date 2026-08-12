# Security-sensitive rate-limit fail-closed pattern

Use this when reviewing rate limiting for authentication, destructive actions, or abuse-sensitive public endpoints.

## Policy

Fail-open in-memory fallback is acceptable for ordinary resource protection when the shared store is unavailable. For security-sensitive categories, fail closed instead: block the protected action with a temporary-unavailable response rather than weakening abuse protection across app instances.

Typical fail-closed categories:

- registration
- password reset/request/verify
- account deletion or vault deletion
- other destructive or credential-related actions

## Public response

Do not expose internal control state to clients. Avoid messages like:

```json
{ "error": "Rate limiting is temporarily unavailable" }
```

That tells attackers which defensive layer is degraded. Prefer generic copy:

```json
{ "error": "Service temporarily unavailable. Please try again shortly." }
```

Use:

- HTTP `503`
- `Retry-After` header
- no internal component names in the response body

## Internal observability

Keep detailed logs and metrics internally:

- category
- underlying store error message
- public status returned
- retry-after seconds
- a metric/tag such as `<category>:store-unavailable`

Do not log raw PII identifiers; hash or omit identifiers consistently with the project logging policy.

## Verification

Tests should assert both sides:

1. The public body is generic and does not mention rate limiting, Redis, store, cache, database, or internals.
2. The internal logger receives category/error/status/retry metadata.
3. Metrics are emitted for the store-unavailable condition.
4. Non-sensitive categories still use the intended fallback path.
