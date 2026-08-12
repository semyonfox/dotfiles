# Performance-sensitive ML pipeline policy changes

Use when optimizing an expensive document/ML pipeline where cheap provider data can sometimes avoid model calls, but accuracy-sensitive fallbacks still matter.

## Pattern

1. Identify the decision point that gates expensive model work.
   - Example classes: OCR fallback, table-cell OCR, layout detection, error-classifier passes.
2. Split the decision into explicit policies instead of one boolean.
   - Keep the current behavior as `auto`.
   - Add narrower policies such as `missing_text_only`, `empty_text_only`, or `never` only when they describe real user-facing tradeoffs.
3. Validate config values at construction time with a clear `ValueError`.
4. Preserve the default path unless the user explicitly opts into the faster/riskier policy.
5. Short-circuit before expensive checks:
   - If there is no provider text, do not run a text-quality/error model whose result cannot change fallback.
   - If an error classifier already marked the input bad, do not run layout/geometry checks that cannot rescue it.
   - If no pages/cells need detection, return early instead of calling the model with an empty batch.
6. For partial provider extraction, distinguish whole-block fallback from missing-item fallback.
   - `missing_text_only` should try cheap extraction first, then OCR only cells/items still missing text.
   - Avoid a stale page/table-level `ocr_block` flag suppressing OCR of partially empty cells.
7. Test with mocks first so the suite does not require model weights or gated datasets.
   - Assert expensive models are *not called* for skip paths.
   - Add one test per policy semantic boundary.
   - Run the dataset-backed integration tests separately and report access/model-weight blockers honestly.

## Pitfalls

- Do not use eager `all([...])` around expensive checks; Python evaluates every list element. Use explicit early returns.
- Do not let a new `never` policy disable only late-stage OCR while earlier flags still say OCR is needed; keep page/table flags and execution gates aligned.
- Do not claim the real speedup until a representative benchmark has run. Unit tests prove the gating logic, not wall-clock performance.
- If a full test file fails because a gated Hugging Face dataset is unavailable, rerun a focused mock/test selection and label the integration blocker separately.
