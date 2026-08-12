# Repo secret validation and env migration

Use when a private repo contains hardcoded API keys, project IDs, service-account paths, or credential-looking literals and Semyon asks whether they are valid or whether env handling should be improved.

## Principles

- Private repo is not enough protection for committed secrets. If a real credential is tracked or present in reachable history, treat it as compromised and recommend rotation even if the repo is private.
- Validate without printing secrets. Report only provider, file path, tracked/history status, sanitized prefix/suffix if needed, HTTP status, and provider error code/type.
- Separate three states:
  - **auth-valid**: provider accepts the key/token for authentication.
  - **usable for the intended operation**: a minimal real API call succeeds for the exact endpoint/model/service tier.
  - **configured locally**: local ADC/env/service account/project variables are present.
- Do not confuse quota/billing failures with invalid credentials. For OpenAI, `insufficient_quota` means the key authenticated but the account/project cannot currently run the requested call.
- For Google Cloud client libraries, absence of an API key may be normal: many projects use Application Default Credentials or service-account JSON via `GOOGLE_APPLICATION_CREDENTIALS`.

## Safe validation workflow

1. Locate candidate secrets with secret-shaped regexes and config literals, excluding dependency/build directories. Do not dump full matches.
2. Check whether files are tracked and whether the secret/config literal exists in `HEAD` or reachable history.
3. Validate provider auth with the least invasive endpoint:
   - OpenAI: `GET /v1/models` confirms key authentication.
   - Then run a tiny intended-surface call only if needed, with small token/output limits.
4. Parse and report provider error `type`/`code`, not raw response bodies if they may contain request details.
5. For Google Cloud, check `GOOGLE_APPLICATION_CREDENTIALS`, ADC availability, project ID, and whether `gcloud`/ADC can produce an access token. Do not print token values.
6. Recommend env migration and rotation:
   - code reads `process.env.OPENAI_API_KEY`, `GOOGLE_CLOUD_PROJECT_ID`, `GOOGLE_CLOUD_LOCATION`, etc.
   - add `.env.example` with empty placeholders.
   - `.gitignore` includes `.env`, `.env.*`, service-account JSON and credentials JSON, while allowing `!.env.example`.
   - rotate any committed API key.

## Report shape

Keep the user-facing report compact:

- `Credential`: provider + file path + tracked/history status.
- `Validity`: auth-valid? intended operation usable? exact sanitized error code.
- `Local config`: relevant env/ADC/project state.
- `Action`: rotate / move to env / add `.env.example` / add ignore rules.

Avoid exposing the secret value, even partially beyond a short prefix/suffix already visible from tooling redaction.