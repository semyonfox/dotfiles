# SpiderFoot OSINT API setup with Bitwarden/Vaultwarden

Use this when setting up free/free-tier OSINT provider accounts for SpiderFoot and storing credentials safely.

## Durable workflow

1. **Unlock the vault before account creation.** Do not generate service passwords or API keys unless Bitwarden/Vaultwarden is unlockable and a safe destination exists.
   - Install/verify `bw` if needed.
   - Confirm `bw status --raw` shows the expected server and user, without printing secrets.
   - Keep `BW_SESSION` in a restrictive temp/session file only for the run; delete it at the end.
2. **Create a provider folder first**, e.g. `SpiderFoot OSINT APIs`.
3. **Create one vault item per provider** before or during signup:
   - login URI
   - username/email
   - generated unique password
   - SpiderFoot setting name as a custom field
   - API key as a hidden/custom field, initially `PENDING` if signup/key retrieval is not complete
4. **Prefer direct manual completion for CAPTCHA/email-gated sites.** Security/OSINT providers commonly block headless browsers, require reCAPTCHA, or trigger anti-scraping pages. Do not fight those checks or leave generated credentials stranded.
5. **When API keys are available, configure SpiderFoot with colon-form keys.** SpiderFoot UI `/optsraw` displays names such as `module.sfp_alienvault.api_key`, but `/savesettingsraw` expects keys in serialized form:
   - global: `_maxthreads`
   - module options: `sfp_alienvault:api_key`, `sfp_abstractapi:phonevalidation_api_key`, etc.
6. **Verify without leaking secrets.** Fetch `/optsraw` and report only whether each API field is `SET` or `empty`.
7. **Clean temporary secret files.** Remove generated password scratch files, `BW_SESSION` files, and exported vault JSON/base64 payloads after creating vault entries or applying config.

## High-value free/free-tier SpiderFoot APIs

Phone-number focused:

- AbstractAPI Phone Validation → `sfp_abstractapi:phonevalidation_api_key`
- NumVerify/APILayer → `sfp_numverify:api_key`
- IPQualityScore → `sfp_ipqualityscore:api_key`
- SEON → `sfp_seon:api_key`
- Intelligence X → `sfp_intelx:api_key`
- HaveIBeenPwned → `sfp_haveibeenpwned:api_key` (usually not meaningfully free for API use)

General OSINT/threat-intel:

- AlienVault OTX → `sfp_alienvault:api_key`
- AbuseIPDB → `sfp_abuseipdb:api_key`
- VirusTotal public API → `sfp_virustotal:api_key`
- Shodan → `sfp_shodan:api_key`
- GreyNoise Community → `sfp_greynoise:api_key`
- SecurityTrails → `sfp_securitytrails:api_key`
- FullHunt → `sfp_fullhunt:api_key`
- URLScan may work anonymously in SpiderFoot 4.0; this install exposed `sfp_urlscan:verify` but no API-key field.

## Pitfalls observed

- AbstractAPI signup can fill successfully but fail to progress in headless browsers due to reCAPTCHA/bot checks.
- AbuseIPDB may present an anti-scraping page immediately from automation.
- OTX signup may accept filled fields but fail to submit/progress in headless automation.
- If signup stalls, save a `pending signup` vault entry with the generated password and required SpiderFoot setting, then ask Semyon to complete CAPTCHA/email verification manually.
