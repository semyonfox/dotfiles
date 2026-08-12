# Multimodel visual bakeoff and QA pattern

Use when Semyon asks to compare Claude/Opus/Sonnet, Codex, Gemini/Antigravity, or other agents on visual artifacts such as SVGs, HTML slides, posters, infographics, or screenshots.

## Model/CLI notes from the session

- Latest local `claude --model sonnet` alias reported itself as `Claude Sonnet 5 / claude-sonnet-5`.
- `claude --model opus --effort max` can be slow/hang in automation; if it stalls, retry with `--effort high` and record the caveat rather than calling it a model failure.
- If Claude/Node tooling emits `nvm is not compatible with NPM_CONFIG_PREFIX`, run through `env -u NPM_CONFIG_PREFIX ...` for a fair retry. Capture the fix, not a negative claim about the tool.
- Codex non-interactive visual generation worked with:
  `codex --dangerously-bypass-approvals-and-sandbox --model gpt-5.5 -c model_reasoning_effort="xhigh" exec --skip-git-repo-check "<prompt>"`
- Gemini/Antigravity visual generation/review worked with:
  `agy --model "Gemini 3.1 Pro (High)" --mode accept-edits|plan --print-timeout 8m -p "<prompt>"`
  It may write outputs into an Antigravity scratch directory instead of the requested cwd; copy them into the run directory if needed.

## Good bakeoff workflow

1. Create a fresh run directory under `/tmp`.
2. Use one clear prompt, but let the delegated agent pick a fresh visual theme if the user asks for novelty.
3. Require multiple artifact formats when useful:
   - single SVG/HTML infographic
   - 3-slide HTML slideshow
   - an extra visual format such as poster/card/system map/passport/trace blueprint
4. Keep prompts minimal but explicit:
   - no external assets/CDNs
   - fixed 1280x720 render target where applicable
   - restrained dark technical style, small warm orange accents for Semyon-style artifacts
   - fit cleanly, no clipping, readable text
5. Render every artifact to screenshot with Chrome before judging. Do not judge only from source.
6. Build a contact sheet or hosted gallery so Semyon can inspect side-by-side results quickly.
7. Get cross-model judgments, excluding self-judgment from final averages.
8. Report commands, model aliases, exact paths, screenshots, failures, and caveats.

## Scoring rubric that worked

Use a 100-point rubric for diagnosis:

- Instruction fit: 30
- Visual hierarchy/readability: 25
- Technical render quality: 25
- Taste/restraint: 20

For final ranking, prefer non-self averages or pairwise battles over self-scores.

## Better benchmark shape

Real visual-understanding benchmarks usually use fixed image+question datasets and ground-truth scoring: exact match, multiple-choice accuracy, or task-specific accuracy. Examples include MMMU, MathVista, and MME.

Visual-generation/design quality is different because there is rarely one right answer. Better practice is:

- anonymized pairwise comparisons rather than only pointwise scores
- randomized model order
- multiple prompts, not one
- multiple independent judges, ideally including human preference
- Elo/Bradley–Terry/win-rate aggregation
- separate failure tags for render failure, clipping, illegible text, prompt miss, external assets, wrong aspect ratio

GenArena-style findings support pairwise judging over absolute scalar pointwise scoring for visual generation because pairwise judgments tend to be more discriminative and human-aligned.

## Observed capability pattern

Treat this as a starting hypothesis, not a permanent ranking:

- Gemini/Antigravity: strong visual QA/screenshot inventory; good at dense visual extraction; generation can be clean but may become generic/sparse depending on task.
- Claude/Sonnet/Opus: strong taste, wording, and final judgement once pixels are visible; can generate strong visuals, but still must be rendered and checked.
- Codex: reliable implementation and structured HTML/SVG; often a good workhorse for patching and producing clean deterministic artifacts.

Best loop:

`reasoning/implementation model builds → Chrome renders screenshot → Gemini/visual judge reviews pixels → reasoning model applies taste and patches → repeat`.
