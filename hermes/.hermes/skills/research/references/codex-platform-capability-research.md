# Codex platform capability research notes

Use this when Semyon asks whether OpenAI Codex/ChatGPT desktop/CLI/app capabilities work across Linux, Windows, macOS, browser use, or Computer Use.

## Source priority

1. Official OpenAI developer docs first:
   - `developers.openai.com/codex/cli`
   - `developers.openai.com/codex/app`
   - `developers.openai.com/codex/app/computer-use`
   - `developers.openai.com/codex/app/browser`
2. Official OpenAI help/release notes for plan/region/platform rollout caveats.
3. `openai/codex` GitHub README/issues for current CLI install/runtime details and platform feature requests.
4. OpenAI community forum for anecdotal Linux ports/workarounds only; label them as unofficial.
5. Third-party blogs/forums only as supplemental leads, not final authority.

## Answer shape

Separate surfaces explicitly. Do not collapse “Codex works on Linux” into “Codex app Computer Use works on Linux.” Use a matrix:

- Codex CLI
- Codex desktop app
- in-app/browser/Chrome extension workflow
- full Computer Use / desktop control
- background vs foreground behavior

For each OS, distinguish:

- Linux: CLI is supported and useful for code-agent workflows; official desktop app and official Computer Use are not first-class unless docs now say otherwise. Workarounds include CLI + Playwright/MCP/browser automation, unofficial ports, or open-source computer-use stacks; mark these as workarounds.
- Windows: official desktop app and Computer Use may be supported, but Computer Use runs on the active foreground desktop; a VM can reduce disruption by letting Codex take over the VM instead of the main session.
- macOS: usually the most polished desktop/Computer Use path; note permissions such as Screen Recording and Accessibility and any region/plan caveats from docs.

## Local verification pattern

If asked whether Codex is installed/running locally, run the real diagnostics rather than relying on docs:

```bash
codex --version
codex --help
codex doctor
codex features list
codex plugin list
```

Report actionable health findings, but avoid preserving transient local setup issues as durable rules. If there is a PATH/npm mismatch or stale session DB row, treat it as local cleanup, not a product limitation.

## Recommendation heuristics

- For Linux-primary users who need official Computer Use, recommend Linux main OS + Codex CLI for repo work + Windows VM/dual boot for official desktop Computer Use before recommending Hackintosh.
- For browser QA on Linux, prefer Playwright/MCP/devtools-style automation before dubious unofficial desktop ports.
- For Hackintosh suggestions, treat it as a separate hardware/maintenance project. Emphasize that it may be plausible on some AMD Ryzen + supported AMD dGPU builds, but is usually not worth doing solely for Codex Computer Use.
