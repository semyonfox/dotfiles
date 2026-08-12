# Swim CI failure pattern: DB-backed auth sessions and date-sensitive seeded E2E

Use this as a concrete reference when triaging Swim PRs where `test-server-db` or seeded E2E fails after an otherwise unrelated backend/API change.

## Symptom: `test-server-db` fails in `tests/auth/middleware.test.js`

Typical CI failure:

```txt
tests/auth/middleware.test.js > Auth Middleware > authenticate
× should authenticate valid token
× should set expiring header for soon-to-expire token
× should include extra token claims in user object
AssertionError: expected "vi.fn()" to be called at least once
```

Root cause: `authenticate()` no longer trusts bare JWT payload claims. It calls `loadActiveUserClaims(decoded)`, which requires:

- `decoded.userId`
- `decoded.sessionId`
- a matching non-revoked, unexpired row in `auth.refresh_sessions`

Old tests that generated only `{ userId, email, roles }` tokens now get `401 TOKEN_STALE` instead of `next()`.

## Fix pattern

Patch auth middleware tests to create an active refresh session before generating tokens expected to authenticate:

```js
import {
  createTestBlacklistedToken,
  createTestRefreshSession,
  createTestUser,
  generateExpiredToken,
  generateMalformedToken,
  generateTestToken,
  mockRequest,
  mockResponse,
} from '../utils/testHelpers.js';

const generateActiveToken = async (payload = {}) => {
  const session = await createTestRefreshSession({
    userId: testUser.user_id,
  });

  return generateTestToken({
    userId: testUser.user_id,
    email: testUser.email,
    roles: testUser.roles,
    sessionId: session.sessionId,
    ...payload,
  });
};
```

Then:

- use `await generateActiveToken()` for valid-token, blacklist, and expiring-token tests
- add a stale-token test with a random/missing `sessionId` expecting `401 TOKEN_STALE`
- update old “extra token claims” assertions: DB-backed claims should win; arbitrary JWT claims such as `teamId` should not be trusted

Focused verification:

```bash
RUN_DB_TESTS=true \
PG_HOST=localhost PG_PORT=55432 PG_USER=swim_e2e PG_PASSWORD=swim_e2e PG_NAME=swim_e2e PG_SSL_MODE=disable \
TEST_PG_HOST=localhost TEST_PG_PORT=55432 TEST_PG_USER=swim_e2e TEST_PG_PASSWORD=swim_e2e TEST_PG_NAME=swim_e2e \
REDIS_ENABLED=false \
corepack pnpm --filter swim-server exec vitest run tests/auth/middleware.test.js
```

CI-style DB flow includes migrations before full DB tests:

```bash
PG_HOST=localhost PG_PORT=55432 PG_USER=swim_e2e PG_PASSWORD=swim_e2e PG_NAME=swim_e2e PG_SSL_MODE=disable \
REDIS_ENABLED=false corepack pnpm --filter swim-server migrate
```

## Symptom: seeded E2E cannot find `E2E Race Pace`

Typical failure:

```txt
seeded data renders on low-risk coach UI pages
Expected substring: E2E Race Pace
Received: Week of <current week> ... No sessions planned
```

Root cause: seeded training sessions are dated in a fixed historical week (`2026-06-18`). UI tests that navigate to `/dashboard/team/training` use the browser's current week, so they drift as real time advances.

## Fix pattern

Freeze browser time for the specific seeded UI test before auth/navigation:

```ts
async function freezeBrowserDate(page: Page, isoDate: string) {
  await page.addInitScript((fixedIsoDate) => {
    const fixedTime = new Date(fixedIsoDate).getTime();
    const RealDate = Date;

    class FixedDate extends RealDate {
      constructor(...args: ConstructorParameters<DateConstructor>) {
        if (args.length === 0) {
          super(fixedTime);
          return;
        }
        super(...args);
      }

      static now() {
        return fixedTime;
      }
    }

    FixedDate.UTC = RealDate.UTC;
    FixedDate.parse = RealDate.parse;
    window.Date = FixedDate as DateConstructor;
  }, isoDate);
}

test('seeded data renders on low-risk coach UI pages', async ({ page }) => {
  await freezeBrowserDate(page, '2026-06-18T12:00:00+01:00');
  await signInAsCoach(page);
  // ...
});
```

Focused verification:

```bash
corepack pnpm e2e:db:reset
corepack pnpm exec playwright test --config e2e/playwright.config.ts \
  e2e/seeded-processes.spec.ts -g 'seeded data renders on low-risk coach UI pages'
```

## CI discipline lesson

After fixing the first failing job, push and watch the full GitHub run. A later job may expose a separate deterministic test drift. Do not call the PR ready until the actual latest run has green `test-server`, `test-server-db`, `test-client`, `test-e2e`, and `build-client`.