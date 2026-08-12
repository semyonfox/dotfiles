# Git-hosted executable runner concept checks

Use this when evaluating or shaping a tool idea like “npx, but for Git/GitHub repos”.

## First check: is the basic idea already solved?

Search for both platform-native behavior and small adjacent tools before judging novelty:

- `npx` / `npm exec` can already run package specs from npm, git URLs, GitHub shorthand, tarballs, local paths, and gists in many cases.
- Small wrappers exist that clone a GitHub repo/subpath and run `npx` inside it.
- Blog/tutorial patterns exist for running MCP servers or CLIs directly from GitHub via `npx`.

So “run GitHub code like npx” is not enough differentiation by itself.

## Useful wedge

The durable product wedge is safer execution, not raw convenience:

- inspect before run
- pin and display resolved commit hashes
- manifest-declared runtime and entrypoint
- manifest-declared permissions: network, read/write paths, env vars, subprocess
- cache/reproducibility story
- policy decisions: allow, require confirmation, deny
- human- and agent-readable risk report
- explicit surfacing of dangerous asks such as `GITHUB_TOKEN`, broad filesystem write access, or arbitrary subprocess/network rights

A good framing is:

> permission-aware preflight and execution policy for Git-hosted tools

Not:

> npx backed by GitHub

## Local repo readiness check

For a candidate implementation repo:

1. Run the project-native tests first (`cargo test`, `pnpm test`, etc.).
2. Identify what is implemented versus documented. Passing tests on parser/inspector code means “MVP seed”, not “usable runner”.
3. Verify whether the tool actually executes remote tools; if not, report it as inspect/preflight-only.
4. Compare against adjacent tools and update the roadmap to emphasize the unique wedge.

## Verdict language

- **Not worth it** if the scope is only “run GitHub repos like npx”.
- **Worth exploring** if the scope is “manifest-driven, permission-aware preflight and execution for Git-hosted tools, especially for agents/MCP/one-off CLIs”.
