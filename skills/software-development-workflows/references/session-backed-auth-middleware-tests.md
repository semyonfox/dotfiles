# Session-backed auth middleware tests

Use this when DB-backed auth middleware fails in CI even though token-only/unit tests look valid.

## Symptom

A DB-enabled server test job fails auth middleware tests with assertions like:

```text
expected "vi.fn()" to be called at least once
```

for tests such as:

- `should authenticate valid token`
- `should set expiring header for soon-to-expire token`
- `should include extra token claims in user object`

The middleware returns `401 TOKEN_STALE` instead of calling `next()`.

## Root cause pattern

Modern auth middleware may no longer trust JWT claims alone. If it loads current claims from the database, valid tokens need both:

- a `sessionId` claim in the access token
- a matching active row in the refresh/session table, e.g. `auth.refresh_sessions`

Typical lookup constraints:

```sql
rs.session_id = decoded.sessionId
rs.revoked_at IS NULL
rs.expires_at > NOW()
```

Old tests that call `generateTestToken({ userId, email, roles })` without creating a refresh session are stale. The token verifies cryptographically, but the middleware correctly treats it as no longer active.

## Fix pattern

Create an active test refresh session and generate the token from that session:

```js
import {
  createTestRefreshSession,
  generateTestToken,
} from '../utils/testHelpers.js';

const generateActiveToken = async (user, payload = {}) => {
  const session = await createTestRefreshSession({
    userId: user.user_id,
  });

  return generateTestToken({
    userId: user.user_id,
    email: user.email,
    roles: user.roles,
    sessionId: session.sessionId,
    ...payload,
  });
};
```

Then use it in passing-auth tests:

```js
const token = await generateActiveToken(testUser);
```

For near-expiry behavior:

```js
const token = await generateActiveToken(testUser, {
  exp: Math.floor(Date.now() / 1000) + 240,
});
```

For blacklist/revocation tests, blacklist a token that otherwise has an active session so the failure exercises the intended branch.

## Assertion update

If middleware now derives `req.user` from database state, do not assert that arbitrary extra JWT payload claims are copied into `req.user`. Instead, assert that stale token claims are ignored and database-backed claims win:

- roles come from active `auth.user_roles`
- athlete/profile IDs and public identifiers come from profile tables
- revoked/missing sessions return a stale-token error

## PR triage note

If this auth-test repair appears bundled inside an unrelated dependency bump, prefer splitting/cherry-picking the test repair into its own small PR before merging the feature/API PR that is blocked by DB CI. A mixed bump may still be safe if all real CI is green, but the cleaner fix is a test-only PR followed by a rerun of the blocked PR.