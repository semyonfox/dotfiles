# Production coach access / invite handoff

Use this when Semyon needs a real coach/admin user to get into a live club app quickly and safely.

## Pattern

1. Verify live service first, not just repo state:
   - production URL responds over HTTPS
   - backend health endpoint responds
   - relevant containers/tunnel are running if locally hosted
   - the club lookup/invite API returns the intended club name
   - the public join page visibly shows the right club and no obvious error
2. Inspect the account state before creating anything:
   - Does the coach already have a claimed user row?
   - What roles are active? `coach`, `head_coach`, `admin`, etc.
   - Is the user in the intended club?
3. Pick the right access mechanism:
   - New/unclaimed coach: create an email invite or setup token with `role_to_grant = 'coach'`/`head_coach`.
   - Existing claimed coach: do **not** make a normal onboarding invite for the same email/account; it may fail or conflict. Generate/request a password-reset/setup link for the existing account instead.
   - Public swimmer/member onboarding: create a share-code invite and use `/join/<code>`; verify `/api/onboarding/clubs/by-code/<code>` resolves to the intended club.
4. Keep sensitive links out of group/public chat:
   - A reset/setup token is a credential-equivalent secret.
   - Send the sensitive link through a private channel when available.
   - In the public/group thread, paste only a safe version that says “use the setup link I sent”.
5. Draft the human message for the recipient:
   - Friendly, not corporate.
   - Include the coach login/setup link privately.
   - Include the share-code join link if they need to invite swimmers/members.
   - Mention the app is early and feedback is welcome.

## Verification checklist

- [ ] Club row exists and is the intended club.
- [ ] Coach account has the correct role and club scope.
- [ ] Share-code invite has expected max uses/expiry and `uses` starts as expected.
- [ ] `/join/<code>` returns 200.
- [ ] Club lookup API returns the intended club name.
- [ ] Browser-rendered join page title/header matches the club.
- [ ] Sensitive token link delivered privately, not in a public group thread.

## Pitfalls

- Do not assume “invite him” means a share-code join link. For a coach, determine whether he needs a coach setup token, a password reset for an existing account, or a role grant.
- Do not send raw reset/setup tokens into a group chat. Treat them like passwords.
- Do not rely on email delivery alone when the user explicitly wants a link today; generate or retrieve a one-time setup/reset link if the app supports it, then verify the token/hash exists and is unexpired.
- If generating a reset token manually, verify it with the application’s token verifier and insert/store only its hash in the reset-token table, matching the app’s normal flow.
