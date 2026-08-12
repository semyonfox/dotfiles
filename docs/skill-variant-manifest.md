# Skill variant manifest

`docs/agent-skill-inventory.json` is the authoritative map of canonical package provenance and `metadata.harness` values.

## Retained harness variants

| Variant | Base package | Why it stays separate |
|---|---|---|
| `cloudflare--claude-codex-opencode` | `cloudflare` | The source/deployment harness set is different from the Hermes-oriented package. |
| `cloudflare-email-service--claude-codex-opencode` | `cloudflare-email-service` | The source/deployment harness set is different from the Hermes-oriented package. |
| `web-perf--hermes` | `web-perf` | Hermes browser/CDP tooling requires distinct operational commands and verification. |
| `wrangler--hermes` | `wrangler` | Hermes tool invocation/deployment flow differs from the general Wrangler CLI flow. |

## Duplicate decision

No packages were removed. Candidate overlaps were retained unless their source map, harness, references, commands, and failure boundaries were all equivalent. This is deliberately conservative: package names alone are not proof of a mergeable workflow.
