# Prompt/context audit for T3 Code vs Hermes

Use this when Semyon asks what T3 Code, Codex, or Hermes is injecting into the model, or asks for rough token counts side-by-side.

## Key local state paths

Hermes:

- Session DB: `~/.hermes/state.db`
- Logs with actual API token counts: `~/.hermes/logs/agent.log`
- Useful table: `sessions(system_prompt, input_tokens, output_tokens, cache_read_tokens, api_call_count, model, source, title, started_at)`

T3 Code / Codex:

- T3 state DB: `~/.t3/userdata/state.sqlite`
- T3 provider logs: `~/.t3/userdata/logs/provider/*.log`
- Codex rollout JSONL: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`
- T3 caches: `~/.t3/caches/{codex,claudeAgent,opencode,grok,cursor}.json` describe provider/model availability, not usually prompt payloads.

## Hermes extraction pattern

1. Find the relevant Hermes session:

```bash
python3 - <<'PY'
import sqlite3, os
con = sqlite3.connect(os.path.expanduser('~/.hermes/state.db'))
con.row_factory = sqlite3.Row
for r in con.execute("""
  select id, source, title, model, length(system_prompt) sp_len,
         input_tokens, output_tokens, cache_read_tokens, api_call_count,
         datetime(started_at,'unixepoch') started
  from sessions order by started_at desc limit 15
"""):
    print(dict(r))
PY
```

2. Split the stored prompt by known headings. Rough token count can be `round(chars / 4)` if no tokenizer is installed. Actual API input/cache counts come from `agent.log`:

```bash
grep '<session_id>.*API call' ~/.hermes/logs/agent.log
```

3. Remember: Hermes tool schemas are sent separately from `system_prompt`, so first-call `input_tokens` can be much higher than the stored prompt size when many toolsets are enabled.

## T3/Codex extraction pattern

1. Find the active/recent T3 provider log and Codex rollout path:

```bash
python3 - <<'PY'
from pathlib import Path
base = Path.home()/'.t3/userdata/logs/provider'
for p in sorted(base.glob('*.log*'), key=lambda p: p.stat().st_mtime, reverse=True)[:10]:
    print(p, p.stat().st_size)
PY
```

Search the selected provider log for `thread/started`; its payload usually contains the Codex rollout JSONL path under `thread.path`.

2. In the rollout JSONL, the useful early records are usually:

- line/type `session_meta`: `payload.base_instructions.text` (large Codex base prompt)
- first developer `response_item`: permissions, collaboration mode, apps, skills, plugins
- following user `response_item`: `AGENTS.md` payloads
- `turn_context`: metadata such as cwd, model, date, context window; record it separately because it is not always a direct model message
- first `event_msg` with `type=token_count`: actual input/cached/output token counts

3. Minimal parser skeleton:

```bash
python3 - <<'PY'
import json
from pathlib import Path
p = Path('/path/to/rollout.jsonl')
objs = [json.loads(line) for line in p.open(errors='replace')]

def rough(name, text):
    print(f'{name}: chars={len(text)} rough_tokens={round(len(text)/4)}')

rough('Codex base_instructions', objs[0]['payload']['base_instructions']['text'])
for i, c in enumerate(objs[2]['payload']['content']):
    rough(f'Developer content {i}', c.get('text',''))
rough('AGENTS payload', objs[3]['payload']['content'][0]['text'])
rough('Turn context metadata', json.dumps(objs[4]['payload'], ensure_ascii=False))
for o in objs:
    if o.get('type') == 'event_msg' and o['payload'].get('type') == 'token_count':
        print('first token usage', o['payload']['info']['last_token_usage'])
        break
PY
```

## Interpretation rules

- Use both rough static counts and actual runtime token counts. Static prompt text alone is misleading.
- Hermes often has a smaller stored system prompt but large tool schema overhead if many toolsets are enabled.
- T3/Codex often has large built-in `base_instructions` and `skills_instructions`; these are app/upstream controlled and may exceed Hermes' visible prompt text.
- Do not paste raw personal memory, user profile, credentials, or full private AGENTS files into a public chat. Summarize section names and counts instead.
- For side-by-side reports, include: source paths, rough chars/tokens per section, actual first input tokens if available, cached tokens, and the biggest contributors.
