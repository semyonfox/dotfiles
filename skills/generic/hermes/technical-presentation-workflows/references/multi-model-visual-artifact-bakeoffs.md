# Multi-model visual artifact bakeoffs

Use when Semyon wants to compare models on generated visual artifacts such as SVGs, HTML slideshows, diagrams, posters, or gallery pages.

## Proven workflow

1. **Pick a fresh challenge, not a reused theme.** Keep the prompt short enough that the models are solving the visual task, not optimizing for a long private context. Include only necessary constraints:
   - artifact formats required
   - fixed size such as 1280×720
   - no external assets/CDNs
   - Semyon’s restrained dark technical style with small warm orange accents when relevant
   - exact output filenames

2. **Use multiple artifact formats.** A useful small bakeoff is:
   - `infographic.html` — single SVG/HTML visual
   - `slideshow.html` — 3-slide HTML slideshow
   - `extra_visual.html` — free-form poster/card/map chosen by the model

3. **Generate with comparable commands.** Examples:

```bash
claude -p --model sonnet --effort high --dangerously-skip-permissions "$(cat generation_prompt.txt)"
agy --model "Gemini 3.1 Pro (High)" --dangerously-skip-permissions --print-timeout 10m -p "$(cat generation_prompt.txt)"
codex --dangerously-bypass-approvals-and-sandbox --model gpt-5.5 -c model_reasoning_effort="xhigh" exec --skip-git-repo-check "$(cat generation_prompt.txt)"
```

4. **Render pixels, never judge source alone.** Use installed Chrome/Chromium headlessly:

```bash
CH=$(find ~/.agent-browser/browsers -type f -path '*/chrome' | head -1)
"$CH" --headless=new --no-sandbox --disable-gpu --hide-scrollbars \
  --window-size=1280,720 \
  --screenshot=screenshots/<model>_<artifact>.png \
  file:///path/to/<model>/<artifact>.html
```

5. **Cross-judge and exclude self scores.** Ask each model to judge the other models’ screenshots, not its own, using the same rubric. Use model-as-judge output as evidence, not gospel.

Good rubric for generated visual artifacts:

| Criterion | Points |
|---|---:|
| Instruction fit | 30 |
| Visual hierarchy / readability | 25 |
| Technical render quality | 25 |
| Taste / restraint | 20 |
| Total | 100 |

6. **Also do pairwise/ranking if possible.** Point scores help diagnose, but pairwise comparisons are usually more stable for visual preference. Aggregate non-self scores and note judge disagreement.

7. **Build a contact sheet/gallery.** For Semyon, a visual gallery is more useful than prose alone. Include screenshot paths, commands/models used, score table, and major failures. Host it briefly or tunnel it to the PC if requested.

## Interpreting results

- One prompt is not a benchmark; it is a probe. Avoid overclaiming broad rankings from a single challenge.
- Task shape matters: a model that wins a dense command-map challenge may lose a narrative slideshow challenge.
- Track failures separately from quality: timeout, wrong directory, missing file, external asset, wrong aspect ratio, clipping, invisible text, cursor artifact.
- Gemini/agy is often strongest as visual QA/critic; Claude/Opus/Sonnet often provide stronger taste/story judgement; Codex tends to be a reliable implementer. Treat these as working hypotheses, not permanent laws.

## Real benchmark shape

For a more serious local benchmark:

1. Use 20–50 prompts across artifact classes.
2. Anonymize outputs and randomize order.
3. Render every artifact through the same browser and viewport.
4. Use pairwise battles plus a diagnostic rubric.
5. Run multiple judges and exclude self-judging.
6. Compute win rates / Elo / Bradley–Terry, plus failure-mode counts.
7. Keep raw prompts, screenshots, judgments, and generation logs.

## Why pairwise matters

Vision-understanding benchmarks such as MMMU, MathVista, and MME can use ground-truth accuracy because they ask image+question tasks with known answers. Generated visual artifacts do not have a single correct answer, so pointwise scoring is noisy. Arena-style pairwise judging better matches human preference because judges only choose which of two outputs better satisfies the prompt.
