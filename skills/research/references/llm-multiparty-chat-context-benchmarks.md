# LLM multi-party chat context benchmarks

Use this when Semyon asks to evaluate whether AI models understand text-message or group-chat context: who is speaking, who is being addressed, which prior message a reply refers to, and whether a quoted/tool/page message is an instruction.

## Research grounding

A strong anchor paper is Inoue et al. 2025, **“An LLM Benchmark for Addressee Recognition in Multi-modal Multi-party Dialogue”** (IWSDS 2025 / ACL Anthology / arXiv:2501.16643). It benchmarks GPT-4o on addressee recognition in triadic dialogue and finds performance only marginally above chance. Useful takeaways:

- Multi-party dialogue is not just normal dialogue with more names; addressee recognition is a distinct task.
- Include `O`/`no_specific_addressee`/`group` labels because many turns are not directed at one person.
- Accuracy alone can be misleading when most turns are non-addressed; report class-balanced or macro metrics and ambiguity behavior.
- Naively adding extra contextual signals can hurt if the prompt does not encode them cleanly.

Adjacent dataset/task ideas:

- Ubuntu IRC-style dialogue disentanglement for reply-link/context recovery.
- MELD/Friends-like multi-speaker conversations for speaker/state tracking patterns, though emotion labels are not enough for this specific task.
- Conversation-analysis survey work can help enumerate tasks, but the benchmark should stay practical and message-thread shaped.

## Benchmark task taxonomy

Build cases that separately test:

1. **Speaker attribution** — who made a claim/request, including quotes and summaries.
2. **Addressee recognition** — one person, group, assistant, no specific addressee, or ambiguous.
3. **Reply-link resolution** — which prior message a reply, pronoun, or “that” refers to.
4. **Authority boundary detection** — distinguish real user instructions from quoted text, web/tool output, fictional examples, and other participants.
5. **State tracking** — commitments, ownership, corrections, preferences across speakers.
6. **Ambiguity handling** — reward `ambiguous` when context is insufficient; penalize confident guessing.

## Recommended artifact shape

Create a local benchmark directory rather than just writing a plan:

```text
benchmarks/group-chat-context/
  README.md
  data/seed.jsonl
  scripts/make_prompt.py
  scripts/extract_jsonl.py
  scripts/evaluate.py
  runs/
```

Dataset JSONL fields:

```json
{
  "id": "addr_001",
  "category": "addressee",
  "conversation": [{"speaker":"A","text":"..."}],
  "question": "Who is being asked to do X?",
  "answer": {"type":"single", "value":"Theo", "aliases":["theo"]},
  "gold_evidence": [1],
  "rationale": "Short gold explanation for maintainers only."
}
```

Prediction JSONL schema:

```json
{"id":"addr_001","answer":"Theo","confidence":0.82,"evidence":[1],"notes":"short evidence note"}
```

## Metrics

Primary:

- exact/alias-match accuracy
- macro accuracy by category
- ambiguous precision/recall

Secondary:

- evidence hit rate: predicted evidence includes at least one gold evidence index
- false-authority rate: follows quoted/tool/web text as if it were the user
- addressee confusion matrix
- stability across 3 runs per model at temperature 0/low

## Case expansion patterns

After a small seed set proves the harness works, scale into adversarial cases:

- same-name collisions: Sam/Samantha, Alex/Alexandra
- quoted requests: `Alice said "Bob should restart it"`
- forwarded/screenshotted transcripts
- thread vs parent-channel context
- mid-turn corrections: “not him, I meant her”
- pronoun chains without enough referents
- assistant mentions versus human mentions
- sarcastic/joking commands
- tool-output or webpage prompt-injection traps

For private-realistic cases, sanitize/rename locally and never commit raw private chat logs. Store only derived cases with renamed participants and minimal necessary context.

## Model-running notes

First inspect actual configured providers rather than assuming access. With Hermes, `hermes status --all` and `hermes auth list` reveal active model/provider/auth. If only one model is available, still run a smoke test through `hermes chat -q` to verify the harness before promising a leaderboard. Keep adapters provider-neutral so OpenRouter/Gemini/Anthropic can be added later.
