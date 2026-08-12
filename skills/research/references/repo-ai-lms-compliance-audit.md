# Repo AI/LMS Compliance Audit Notes

Use this when auditing a software repo for AI, LMS, Canvas, GDPR, EU AI Act, or third-party data-processing compliance. This is not legal advice; it is a technical/legal risk reconnaissance workflow to identify launch blockers and questions for counsel/institution review.

## Audit shape

1. Inspect the actual code paths before giving a legal answer.
   - Search for provider names and generic terms: `openai`, `openrouter`, `anthropic`, `llm`, `embedding`, `rerank`, `rag`, `prompt`, `chat`, `canvas`, `lms`, `token`, `oauth`, `privacy`, `terms`, `delete`, `export`.
   - Read API routes, provider clients, token/credential storage, deletion/export routes, settings toggles, and env templates/runtime env summaries.
   - Map what leaves the app: user message, note chunks, files, metadata, chat history, grades, course data, tokens, etc.

2. Separate three layers:
   - Technical implementation: what data is collected, stored, sent, deleted, exported.
   - Provider contract posture: DPA, subprocessors, retention/training policy, SCC/adequacy/third-country transfer basis, OAuth/developer-key policy.
   - User-facing disclosures: privacy policy, terms, in-product consent/disclosure, AI warnings, opt-out, deletion/export wording.

3. For GDPR/Ireland/EU:
   - Use official DPC/EU sources first for transfers, data-subject rights, and AI Act timelines.
   - Check whether third-country transfers are covered by adequacy, SCCs, BCRs, or other safeguards.
   - Check whether deletion is real hard deletion across DB, object storage, vector DB, queues/jobs/logs, backups, and provider-side retention where supported.
   - Check whether export/access covers all personal data, not just user-created documents.

4. For AI integrations:
   - Identify LLM, embedding, rerank, OCR/extraction, and analytics providers separately.
   - Verify whether code enforces provider restrictions (ZDR/no-training/allowlist) or merely relies on dashboard settings.
   - Watch for user content being embedded/reranked as well as sent to chat completion.
   - If notes/files may contain special-category data, flag sensitive-data processing and provider terms.

5. For Canvas/LMS integrations:
   - Canvas manual API-token collection is usually only acceptable for personal/testing use. Canvas docs say multi-user applications must use OAuth2; asking users to manually generate tokens is a policy violation.
   - Prefer OAuth2 developer keys with scoped endpoints and institution/admin approval.
   - Treat Canvas access tokens as password-equivalent. Check encryption, no frontend echoing, no URL/query-string leakage, no-store responses, revocation/disconnect, and rate limiting.
   - For AI access to LMS data, use a positive read-only allowlist. Do not rely on a subtractive blocklist of dangerous tools.
   - Flag tools that can send messages, submit assignments, post discussions, change profile/settings, mark work complete, create/update/delete events, or otherwise act externally as the user.

## Useful source anchors

- Irish DPC international transfers: transfers outside the EEA must comply with GDPR Chapter V; adequacy or appropriate safeguards such as SCCs are typical paths.
- EU AI Act official timeline: AI Act provisions apply progressively; transparency rules and high-risk classifications have separate timelines.
- EU GPAI obligations: mostly apply to GPAI model providers, but downstream app providers still need transparency and risk classification for their system.
- Instructure Canvas OAuth docs: applications used by multiple users must implement OAuth2; manual access-token generation is for testing before OAuth is implemented.
- Canvas developer-key docs: scoped developer keys can restrict tokens to specific endpoint scopes in `url:<VERB>|<PATH>` form.
- Instructure API Policy: do not surprise users; be transparent and respect privacy; disclose generative AI use, storage, and training implications.

## Report style

- Lead with a clear verdict: compliant / not compliant / lawful in principle but launch-blocked.
- Distinguish private/dev use from invite beta, public launch, and institutional/school sales.
- List exact repo files inspected and exact data flows found.
- Use blunt risk levels and concrete must-fix items.
- Avoid pretending to provide legal advice; identify technical facts, policy blockers, and counsel/institution questions.
