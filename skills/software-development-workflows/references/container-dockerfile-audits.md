# Dockerfile and container-build audit workflow

Use this for an evidence-backed audit or optimisation of several local projects' Dockerfiles.

## Scope safely

1. Enumerate Dockerfiles under normal project roots, excluding `.git`, dependencies, generated output, backup/archive trees, reference clones, and disposable worktrees.
2. Identify canonical repositories before interpreting duplicate Dockerfiles. Check Git status; do not edit over user work without an explicitly scoped change.
3. For each canonical image, read its Dockerfile, the **effective** `.dockerignore`, build context, Compose/Jenkins/GitHub Actions invocation, lockfiles, and runtime health checks. A nested `.dockerignore` does not apply if the configured context is the repository root.

## Review order

1. **Context and secrets:** determine the actual build context and exclude `node_modules`, VCS metadata, build outputs, logs, `.env`/`.env.*`, credentials/certificates, and large local audit artifacts. Context-local ignore files matter for subdirectory builds. Prefer an allow-list when it remains maintainable.
2. **Cache layers:** copy manifests/lockfiles before dependency installation; copy frequently changing source afterwards. Use BuildKit package cache mounts where the builder supports them. For Rust, consider `cargo-chef` or Cargo cache mounts rather than rebuilding dependencies after ordinary source edits.
3. **Runtime shape:** keep multi-stage copies limited to runtime artifacts. Do not add stages reflexively when a one-stage runtime genuinely has no build artifact. Keep GPU/CUDA stacks cautious: prove wheel/runtime-library and actual inference compatibility before removing toolchains or changing users.
4. **Base choice:** default Node/Python services and native dependency builds to Debian slim. Alpine is a valid exception only after the actual project build/runtime chain is exercised; a static nginx artifact can qualify, but record the measured size and compatibility trade-off.
5. **Reproducibility:** pin production `FROM` and third-party Compose images by tag plus digest. Do not present pinning as security maintenance by itself: use Dependabot Docker updates (or another reviewable updater), then rebuild/test/scan the proposal. Deploy application images by immutable commit/version tag or digest, not `latest`.
6. **Runtime safety:** do not bake secrets/default credentials into images. Prefer non-root runners, minimal packages, health checks when the platform uses them, and testable runtime restrictions (`read_only`, dropped capabilities, `no-new-privileges`) applied incrementally.

## Experiment protocol

- Do not mutate a user checkout merely to compare architectures. Put a temporary Dockerfile outside the repo, build it with the original context, and tag it clearly as local/audit-only.
- Measure both final image size and build duration. Compare the same app and smoke-test **each image with an explicit host port** (`docker run -p 127.0.0.1::80 ...`); do not treat a `curl` to an un-published container port as evidence.
- Distinguish cold-pull time from cache performance. Preserve raw timing/log evidence only as needed for the report.
- Remove temporary Dockerfiles, audit image tags, and test containers after recording results. Never run broad `docker system prune` on a machine with active services.

## Current authoritative Docker guidance

- Cache ordering, context minimisation, bind/cache mounts: https://docs.docker.com/build/cache/optimize
- General build practices, multi-stage images, digest trade-off: https://docs.docker.com/build/building/best-practices
- Dockerfile-specific ignore files and context rules: https://docs.docker.com/build/concepts/context
- Docker Scout's GitHub integration was retired in July 2026. For digest update PRs use Dependabot with `package-ecosystem: docker`; build provenance with `--provenance=mode=max`: https://docs.docker.com/scout/integrations/source-code-management/github

## Reporting

Report the effective build context/command, evidence-backed finding, proposed change, verification status, and trade-off per image. Separate immediate low-risk hygiene work (ignore files, dead installs, non-secret configuration) from production/deployment or GPU changes that require a staged test path.