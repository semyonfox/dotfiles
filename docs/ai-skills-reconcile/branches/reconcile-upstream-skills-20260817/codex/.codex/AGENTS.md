# Personal Codex defaults

For device fleet, SSH, Tailscale, NAS, router, PC, laptop, phones, T3 Code remote environments, or home-network maintenance, use the `device-fleet` skill. Keep inventory in `~/.codex/skills/device-fleet/references/computers.md`; never store secrets or sudo passwords.

## default lane

Semyon uses the Codex $100/month plan.

- choose the lane from task shape, not model prestige
- **Terra, medium:** default for interactive implementation, routine repo work, bounded refactors, and focused review; prefer it when a human will inspect each step or the change should remain deliberately small
- **Sol, medium:** short work where Sol-level reasoning is useful but uncertainty is moderate
- **Sol, high:** difficult, well-scoped investigations, architecture decisions, multi-step debugging, or autonomous bounded tasks likely to take more than about ten minutes; give it a concrete terminal condition and inspect the result
- **Sol xhigh/max/Ultra:** opt in only after a normal pass demonstrably lacks capability; state why because these modes can spend more time and usage while prolonging bad loops
- **Luna / Spark:** delegated only for independent extraction, classification, bulk transformation, title/branch generation, or one-file mechanical work; never give them broad edits, final judgment, or an ambiguous objective

## task boundaries

Identify the requested phase and terminal condition before broad work.

- planning stops after the plan and requests approval unless implementation was explicitly authorized
- implementation stops after the agreed scope and named verification
- review returns findings on the named target and does not start unrelated refactors
- PR work stops after the requested review round

Do not keep exploring, polishing, or expanding scope after the terminal condition. Propose the next phase in one line instead.

## smallest sufficient change

Before editing, state the expected minimum delta: the files, behaviour, and verification that should be sufficient.

- prefer an existing local pattern over a new abstraction, subsystem, package, migration, or configuration layer
- do not rewrite adjacent code merely to make the patch feel cleaner
- add or update only tests that prove the requested behaviour or protect a demonstrated regression; do not generate speculative test matrices
- if the apparent fix grows beyond the stated minimum delta, stop and report what expanded, why, and the smallest viable alternative
- after one failed hypothesis, re-check the premise against observed evidence before inventing a workaround; do not pursue novel solutions to an unproven problem

## visual evidence

Gemini via Antigravity (`agy`) is the eyes for Codex and other lead models. For screenshot, UI, diagram, deck, or image-fidelity work, ask it for visible observations only: exact text, layout, colours, spacing, hierarchy, component states, icons, clipping, contrast, anomalies, and confidence. Use those observations as evidence.

Gemini is not the final judge of taste, architecture, product direction, or implementation quality. Keep concrete observations and down-rank speculation.

```bash
IMAGE=/path/to/image.png
AGY_MODEL="Gemini 3.5 Flash (Low)"
agy --model "$AGY_MODEL" --mode plan --add-dir "$(dirname "$IMAGE")" --print-timeout 5m -p "Use Gemini vision on this image. Return visible observations only for another model: exact text, layout, colours, spacing, hierarchy, component states, icons, clipping, unreadable text, contrast issues, anomalies, and confidence. Separate observations from guesses. Do not recommend redesigns, architecture, or product decisions: $IMAGE"
```
