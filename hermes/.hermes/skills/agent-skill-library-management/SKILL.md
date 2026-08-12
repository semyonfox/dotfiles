---
name: agent-skill-library-management
description: "Use when centralizing or deploying Claude/Codex skills."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Agent Skill Library Management

Use when Semyon wants to inventory agent skills, choose a canonical source, simplify their layout, or deploy them to Claude and Codex without losing existing content.

## Operating principle

Start with the layout Semyon explicitly names. Do not introduce a fleet taxonomy, deployment generator, metadata schema, separate repository, or extra documentation layer unless he asks for it. A small skills setup should remain small.

For Semyon's dotfiles setup, the intended canonical form is:

```text
~/dotfiles/skills/
├── AGENTS.md
├── CLAUDE.md
└── <skill-name>/
    └── SKILL.md
```

Each skill is an ordinary folder under `dotfiles/skills`; its normal `SKILL.md` and any existing `references/`, `scripts/`, `templates/`, or assets remain inside that folder.

## Required discovery before any move

1. Inspect the live runtime roots and dotfiles source trees.
2. Classify every discovered skill by actual source and ownership:
   - already dotfiles-managed;
   - installed runtime copy that can be centralized;
   - runtime/system-managed (leave alone unless the user asks to migrate it);
   - dangling link / missing source (never invent its content).
3. Compare duplicate candidates recursively before choosing one canonical copy. Preserve the existing richer copy if they differ.
4. Check Git status, current branch, remotes, and upstream divergence before publishing.

## Safe centralization workflow

1. Create only `~/dotfiles/skills/` plus its two requested root guidance files.
2. Move/copy each selected existing skill directory wholesale into `skills/<name>/`; preserve all supplementary files.
3. Replace runtime package entries with symlinks to the canonical skill directory.
4. Deploy or directly relink live runtime entries only after their targets resolve. Preserve any replaced runtime directories in a timestamped rollback directory outside the active runtime root.
5. Validate every expected `SKILL.md` through both live runtime roots.
6. Stage only the canonical-library migration and runtime links. Run `git diff --cached --check`, commit, push, then verify the remote SHA equals the PC checkout SHA.
7. Open `~/dotfiles/skills` in the PC graphical editor for Semyon's manual authoring.

## Verification

Verify with real path resolution, not a claim based on the Git diff:

```bash
for root in ~/.claude/skills ~/.codex/skills; do
  for source in ~/dotfiles/skills/*; do
    test -d "$source" || continue
    name=${source##*/}
    test -f "$root/$name/SKILL.md"
  done
done
```

Report canonical skill count, the live resolution count per runtime, backup location if runtime copies were replaced, pushed commit SHA, and any omitted dangling/missing skills.

## Pitfalls

- Do not treat a user request to create a repo as permission to write the skill contents; create only the explicitly requested skeleton when they will author it.
- Do not conflate a skill's portability metadata with model/provider routing. A normal skill should remain ordinary Markdown; runtime/model selection belongs elsewhere.
- Do not bulk-move an installed runtime/system directory such as `.system` without an explicit instruction.
- Do not silently fix a missing/dangling skill by fabricating a replacement. Preserve/report it as unresolved.
- Avoid repeated structural pivots. When Semyon says the design is "not that deep," cut back to the smallest literal layout rather than explaining a larger architecture.
