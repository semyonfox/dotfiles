# AI/GDPR Compliance Audit for EU/Ireland SaaS

Use when auditing a product that sends user content to LLM, embedding, rerank, OCR, or other AI providers.

## Repo-first evidence to collect

1. Find all AI provider env vars and runtime endpoints:
   - `LLM_API_URL`, `LLM_MODEL`, `LLM_THINKING`
   - `EMBEDDING_API_URL`, `EMBEDDING_MODEL`
   - `RERANK_API_URL`, `RERANK_MODEL`
   - OCR/document services such as `MARKER_API_URL`, `DATALAB_API_KEY`
2. Trace what payload leaves the app:
   - Chat message and prior chat history
   - Retrieved note chunks / file excerpts
   - Full note reads via tools
   - Embedding inputs for notes and queries
   - Reranker `query` plus candidate `documents`
   - Quiz/flashcard generation prompts
   - OCR uploads
3. Trace storage and deletion:
   - Chat sessions/messages
   - Notes/files/object storage
   - Chunks/vector stores such as Qdrant/pgvector
   - Account deletion endpoint and any hard-delete job
   - Export/download jobs and generated zip retention
4. Read public legal pages in the app:
   - `/privacy`, `/terms`, `/cookies`
   - Launch/admin docs that mention privacy, deletion, providers, or subprocessors

## Legal/source checks

Prefer official/current sources first:

- Irish DPC guidance for GDPR transfers. For third-country transfers, look for adequacy, SCCs, BCRs, or another Chapter V mechanism.
- EU AI Act official pages/timeline. For study assistants, distinguish general support from high-risk education uses such as admission, grading, official learner assessment, or access decisions.
- Provider docs for DPA, subprocessors, data retention, training use, ZDR/no-retention controls, deletion requests, and geographic processing.

## Practical findings to look for

Launch blockers commonly include:

- User content is sent to non-EEA or unclear-region providers with no documented DPA/SCC/TIA.
- Routing providers such as OpenRouter are used without per-request or account-level enforcement of ZDR/no-training/allowed providers.
- Privacy policy only says “AI providers may receive excerpts” but omits controller identity, lawful basis, subprocessors, transfer basis, retention, user rights, DPC complaint right, and provider training/retention details.
- Account deletion only soft-deletes login state and does not purge notes, files, vectors, chat, quiz/study data, tokens, exports, or backups.
- Data export covers only notes/files rather than broader GDPR access/portability data.
- Terms do not warn that AI output may be wrong or not authoritative.
- The product accepts student notes without policy around special-category data.

## Answer shape

Use a clear verdict, not lawyerly fog:

- “Likely lawful in principle, not launch-compliant as implemented” is often the right distinction.
- Separate technical legality from GDPR operational compliance.
- Give risk levels by deployment stage: internal/dev, closed beta, public EU launch, school/university sales.
- List exact code files/endpoints checked and exact providers/models configured, redacting secrets.
- Avoid claiming “fully compliant” unless there is evidence of contracts, transfer mechanism, privacy notice coverage, deletion/export implementation, and provider enforcement.

## Recommended remediation categories

1. Provider controls: DPA/SCC/TIA, ZDR/no-training, model/provider allowlist, EU/self-hosted alternatives.
2. Transparency: privacy policy, terms, in-product AI disclosure, subprocessors list.
3. Data subject rights: full export, hard deletion, provider-side deletion procedure.
4. Data minimisation: scoped notes, opt-out/disable AI, BYOK where useful, avoid raw prompt logging.
5. AI Act posture: transparency, AI literacy, avoid official educational decisioning unless high-risk controls are ready.
