# Model visual bakeoff workflow

Use this when Semyon wants to compare models on visual artifacts, screenshots, SVGs, slides, landing pages, or “which model is better at seeing/making this?” tasks.

## Core lesson

Do not judge visual work from source/code or model self-report. Generate the artifact, render it in a browser, capture screenshots, then compare pixels.

Best observed division of labour:

- **Gemini via `agy`**: strongest visual eyes and first-pass spatial composition; good at dense screenshot/layout inventory, diagrams, UI structure, and “what is physically on screen”. It can drift into dashboard/consultant aesthetics.
- **Opus/Claude**: stronger taste, prose, prioritisation, and “is this shippable or cringe?” judgement once screenshots exist. Still needs rendered visual QA for generated HTML/SVG/decks.
- **Codex GPT-5.5**: reliable engineering implementation and clean restrained SVG/layouts; often safer and less flashy, but less visually ambitious.
- **Sonnet**: useful for prose/review, but complex visual generation can miss rendered scale/layout failures unless forced through screenshots.

## Headless model call patterns

### Gemini / Antigravity visual QA

Call `agy` directly. Do not create wrapper scripts unless Semyon explicitly asks.

```bash
IMAGE=/path/to/screenshot.png
AGY_MODEL="Gemini 3.1 Pro (High)"   # or Gemini 3.5 Flash (Low/Medium/High)
agy --model "$AGY_MODEL" --mode plan --add-dir "$(dirname "$IMAGE")" --print-timeout 8m -p \
  "Review this rendered screenshot as a visual artifact. Judge layout fit, readability, hierarchy, theme match, technical polish, and defects. Image: $IMAGE"
```

Use Flash Low/Medium for normal screenshots; Flash High or Pro High for dense diagrams, small text, side-by-side comparisons, or when visual extraction itself needs more reasoning.

### Claude / Opus visual judgement or generation

```bash
claude -p --model opus --effort high --add-dir /tmp/work --allowedTools "Read,Write" \
  "Create/review ..."
```

If `--effort max` stalls, fall back to `high` and label the run honestly. Do not wait forever just because the model is stronger.

### Codex GPT-5.5 xhigh artifact generation

```bash
codex --model gpt-5.5 -c model_reasoning_effort="xhigh" \
  -s workspace-write -a never exec --skip-git-repo-check "Create ..."
```

If Codex sandboxing blocks writes in a disposable scratch directory, rerun with `--dangerously-bypass-approvals-and-sandbox` only when the workdir is explicitly throwaway and externally safe.

## Browser render / screenshot loop

For self-contained HTML/SVG artifacts:

```bash
CH=$(find ~/.agent-browser/browsers -type f -path '*/chrome' | head -1)
"$CH" --headless=new --no-sandbox --disable-gpu --window-size=1280,720 \
  --screenshot=/tmp/artifact.png file:///tmp/work/index.html
```

For slides/decks, capture representative states/slides, not only slide 1.

## Gallery handoff pattern

When comparing multiple outputs, make a tiny local evidence board:

1. Copy rendered screenshots into `assets/`.
2. Build an `index.html` with model name, prompt/task, caveats, and notes per artifact.
3. Serve locally:

```bash
python3 -m http.server 8765 --bind 127.0.0.1
```

4. Verify with `curl -I` and a browser screenshot.

## Ranking discipline

Separate these axes in the final answer:

- visual extraction / “eyes”;
- first-pass visual generation;
- implementation reliability;
- taste/prose/final judgement;
- best iterative pipeline.

A good final comparison says which model won **for the pixels**, which won **for taste**, and which workflow would produce the best final artifact.

## Pitfalls

- Do not let model self-reports substitute for screenshots.
- Do not persist a wrapper command for `agy` unless Semyon asks; he prefers direct headless calls.
- Do not overstate one run as universal truth. Treat it as evidence for that class of artifact and note caveats.
- Do not encode transient tool setup failures as durable “tool broken” rules. Capture only reusable recovery patterns such as “render and screenshot before judging” or “fallback from max to high if max stalls”.
