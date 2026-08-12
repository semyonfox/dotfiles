# LMS / Canvas integration compliance review notes

Use when reviewing edtech/LMS integrations in a codebase, especially Canvas/Moodle/Blackboard/Brightspace imports, AI over course material, or student-facing OAuth flows.

## Key distinction

Separate three questions that users often conflate:

1. **Law/GDPR**: data controller/processor duties, privacy notice, deletion/export, security, AI disclosures, data residency/subprocessors.
2. **Platform policy**: Canvas/Instructure or LMS terms. This can block launch even when the legal position is otherwise manageable.
3. **Institution approval**: university LMS admins usually control developer keys, OAuth scopes, LTI tools, and tenant consent.

A concise answer should name the actual blocker first, then explain why and the practical route around it.

## Canvas-specific lessons

- Canvas manual/personal API tokens are acceptable for a user's own testing and possibly very private dev work, but they are not a public multi-user launch foundation.
- Canvas OAuth docs state that asking other users to manually generate tokens and enter them into an app violates Canvas API policy; multi-user apps must use OAuth.
- OAuth uses Developer Keys: `client_id`, `client_secret`, redirect URI, scopes, and institution/global enablement.
- Developer keys can be root-account/institution-specific or global. Global keys are created by Instructure and still may need each institution to enable them.
- Scoped keys should request the minimum read-only endpoints needed. If the product needs `include[]` data, confirm the key has Canvas' "Allow Include Parameters" behavior enabled where relevant.
- If a university rejects Canvas OAuth, do not treat Microsoft/Azure SSO as equivalent: Entra/OIDC only solves app login, not LMS data access.

## Safer launch sequencing for student study apps

1. Keep API-token mode hidden/dev-only, not marketed as launched.
2. Provide manual upload as the universal legal/product fallback.
3. Add normal app auth via Microsoft/Google OIDC with only `openid profile email` where useful.
4. Build Canvas OAuth against a test/local Canvas or one approved campus key.
5. For institution-friendly pilots, consider LTI Advantage, but note it changes product shape: launched from inside LMS and not automatically a bulk file importer.
6. Approach global/institutional approvals with a working demo, exact scopes, privacy terms, data-flow diagram, deletion/revocation story, subprocessors, and clear AI controls.

## Code review checklist for LMS + AI imports

- Locate auth flow: pasted tokens vs OAuth vs LTI vs SSO-only.
- Identify where tokens are stored; require encryption, no frontend return, no URL tokens, revoke/delete on disconnect.
- Trace imported LMS data into storage, extracted text, embeddings/vector DB, logs, queues, backups, and AI prompts.
- Check account deletion and LMS disconnect semantics: disconnect removes credentials; deletion should remove imported files/text/chunks/vectors/jobs/logs or clearly document retention.
- Prefer explicit read-only allowlists for AI tools over subtractive "disabled tools" lists.
- Disable or require human confirmation for LMS side effects: submit, send/reply, post, create, update, delete, mark complete/read, grade, profile/settings changes.
- Update privacy/terms with LMS-specific data categories, AI/provider disclosure, training/storage statements, user rights, and independence from the institution/LMS vendor.
- Flag copyright/course-material terms: user may import only material they are allowed to process; no redistribution/public sharing.

## Answer style for Semyon

For quick risk triage, be blunt and short: blocker, why it matters, what to do. Avoid legal theatre unless he asks for depth.