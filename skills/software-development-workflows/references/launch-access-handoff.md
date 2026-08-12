# Live launch/access handoff checklist

Use when Semyon asks for a production app to be ready for someone external today, especially with invite links, coach/admin access, or a club/team workspace.

## Workflow

1. **Identify live surface and deployment path**
   - Locate the repo and stack/deploy files.
   - Check live containers/processes and the public URL before editing.
   - Prefer verifying the already-running service first; do not disturb working services unnecessarily.

2. **Check production health, not just local code**
   - Hit the public app over HTTPS.
   - Hit a known public API route and a known authenticated/expected-failure route so proxying is confirmed.
   - Inspect recent production logs for fresh errors after the checks, redacting tokens/secrets in any report.

3. **Prepare access with least disclosure**
   - For group/member onboarding, create or reuse a share-code/join link with sane expiry/usage limits.
   - For a specific existing coach/admin, prefer triggering password reset or normal setup email over pasting raw setup tokens, reset tokens, or passwords into chat.
   - If a raw invite/setup URL is unavoidable, treat it as a secret and avoid posting it in public/group channels.

4. **Verify the invite path end-to-end without consuming it**
   - Query the public lookup endpoint for the invite/share code and confirm it resolves to the right club/team.
   - Open the actual `/join/<code>` or equivalent page in the browser and visually confirm the page names the correct organization and has no obvious error state.
   - If the flow requires approval, confirm the UI explains that clearly.

5. **Verify workspace readiness**
   - Count relevant club/team data directly from production DB/API: athletes/members, coaches/admins, pending requests.
   - Confirm the intended coach/admin account exists and has the expected role.
   - If you trigger a password reset email, verify delivery was accepted/logged and that an unconsumed reset token exists, but do not expose the token.

6. **Final handoff format**
   - Keep it short: live URL, invite/join link, invite code, what was verified, and any time-sensitive action such as reset-link expiry.
   - Avoid dumping commands or logs unless asked; this is a launch handoff, not a forensic report.

## Pitfalls

- Do not create a new club if the production club already exists under a slightly different name.
- Do not confuse a share-code join link for athlete/member requests with an email setup token for a specific coach.
- Do not post password reset/setup tokens in Discord or other shared chat surfaces.
- Do not claim readiness from repository tests alone; external users care about the deployed URL, deployed data, and access path.
