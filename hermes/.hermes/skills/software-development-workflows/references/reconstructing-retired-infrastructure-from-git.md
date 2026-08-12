# Reconstructing retired infrastructure from Git history

Use when a repo has migrated away from an old hosting/provider setup but the user needs an accurate architecture/config diagram or report for the retired system.

## Workflow

1. **Start from current truth**
   - Read current agent/project docs first (`AGENTS.md`, `README`, `docs/README`, `infra/*`, deploy files, env templates).
   - Identify what is live now vs explicitly historical/fallback. Do not treat old docs as current just because they are detailed.

2. **Find the migration boundary**
   - Search Git history for provider/deploy terms: `AWS`, `Amplify`, `RDS`, `SQS`, `ECS`, `S3`, `Secrets Manager`, `Cloudflare`, `homelab`, `migration`, `deploy`.
   - Pick a commit just before the cleanup/migration rewrite, plus the current head. The useful point is usually before files were deleted or docs were rewritten, not the newest mention of the old provider.

3. **Inspect historical files without disturbing the working tree**
   - Prefer `git show <commit>:<path>` and `git grep <commit> -- <paths>` for targeted extraction.
   - Use `git ls-tree -r --name-only <commit>` to discover old infra files.
   - Only create a separate worktree if broad interactive exploration/building is needed. Never switch branches in the user’s dirty repo.

4. **Triangulate from multiple evidence classes**
   - Build/deploy config: CI workflows, buildspecs, Dockerfiles, deploy scripts.
   - Runtime config: env templates, secrets names, provider-specific env vars.
   - App integration code: queue clients, storage providers, email clients, OCR/worker lifecycle code.
   - Ops docs/pricing docs: often contain names, regions, costs, and intended topology.
   - Migration docs: useful for replacement mapping, but verify against current config.

5. **Mark status explicitly in diagrams**
   - Use visual classes or labels for `current`, `historical/retired`, `target/future`, `external`, `config`, and `data`.
   - Include a migration map from old services to new replacements.
   - Separate “AWS used historically” from “AWS retained/fallback now” so the diagram does not accidentally resurrect retired services.

6. **Deliver a reusable artifact**
   - For large Mermaid diagrams, write a Markdown attachment/file rather than dumping walls of diagram text into chat.
   - Include a short provenance section listing current files and historical commits inspected.
   - Add a short plain-English readout after the diagram.

## Pitfalls

- Do not rely on current docs alone after migrations; they often intentionally remove the old topology.
- Do not rely on historical docs alone; they may contain stale costs, placeholder resource names, or plans that were never deployed.
- Do not switch branches or reset when the repo is dirty. Use `git show`/`git grep` against commits, or a separate worktree if necessary.
- Be careful with secrets: env templates and scripts may show variable names; never expose real env-file values unless explicitly asked and safe.
