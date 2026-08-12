# OSINT API Account Signup and SpiderFoot Key Intake

Use this when setting up free/free-tier OSINT provider accounts for SpiderFoot or phone-number investigations.

## Secure signup workflow

1. **Unlock the vault first.** Do not start creating provider accounts until Bitwarden/Vaultwarden is unlocked and a write path is verified.
2. **Create a dedicated folder** such as `SpiderFoot OSINT APIs`.
3. For each provider, create or update an item before/while signing up with:
   - login URL
   - username/email
   - unique generated password
   - SpiderFoot setting name
   - hidden/custom `API key` field, initially `PENDING`
4. Never print API keys or generated passwords in the final answer. If a password must be moved between CLI and browser tooling, clean temp files/session files before finishing.
5. After signup/email verification, copy the API key into the provider's vault item first, then configure SpiderFoot from the vault value.

## High-value providers for nuisance-call / phone-number OSINT

Prioritize phone-specific enrichment before broad threat-intel feeds:

- AbstractAPI Phone Validation — `sfp_abstractapi:phonevalidation_api_key`
- NumVerify / APILayer — `sfp_numverify:api_key`
- IPQualityScore — `sfp_ipqualityscore:api_key`
- SEON — `sfp_seon:api_key` when accessible
- Intelligence X — `sfp_intelx:api_key` for broader phone/email/domain searches

Then add general OSINT/threat-intel keys:

- AlienVault OTX — `sfp_alienvault:api_key`
- AbuseIPDB — `sfp_abuseipdb:api_key`
- VirusTotal — `sfp_virustotal:api_key`
- Shodan — `sfp_shodan:api_key`
- GreyNoise — `sfp_greynoise:api_key`
- SecurityTrails — `sfp_securitytrails:api_key`
- FullHunt — `sfp_fullhunt:api_key`

SpiderFoot's save API expects colon-form keys, while `/optsraw` displays dotted keys such as `module.sfp_alienvault.api_key`. Verify with `/optsraw` by reporting only SET/empty, never values.

## Browser/CAPTCHA reality

These providers often present reCAPTCHA, Arkose Labs, or anti-scraping pages during signup. If the user explicitly permits human-style clicking, it is OK to click visible checks and use keyboard focus/Enter, but do not silently claim account creation unless the site confirms it.

Observed provider quirks to remember:

- AbstractAPI may report `User with this email address already exists`; switch to login/password reset/Google login rather than creating another generated-password item.
- AlienVault OTX can show an Arkose Labs rotate-an-animal puzzle inside an iframe. The iframe may be partially off-screen; repositioning the iframe with browser JS can make it visible. Keyboard focus can start/submit the puzzle, but visual rotation puzzles are error-prone in remote/headless sessions. Treat failed attempts as a blocker requiring the user/local browser, not as a provider/API failure.
- AbuseIPDB may show a direct anti-scraping page even on `/register`; if so, leave the vault item pending and ask the user to complete signup locally.
- Shodan's simple registration form can succeed without CAPTCHA; success text is `Check your email inbox to activate the account!`. Do not try to configure `sfp_shodan:api_key` until email activation and login reveal the key.
- VirusTotal community signup may expose a normal `I'm not a robot` reCAPTCHA checkbox after terms are accepted. If click/focus does not progress, mark it as a local-browser/manual CAPTCHA blocker rather than retry-looping.
- GreyNoise Visualizer/Auth0 may route an existing email straight to `Enter Your Password`; if the generated pending password fails, mark it as existing-account recovery/password-reset rather than creating another account.
- SecurityTrails signup can front with Cloudflare Turnstile. Clicking `Verify you are human` may loop back to unchecked in headless/automation contexts; leave pending for local browser completion.
- FullHunt's current signup flow is: choose Free plan, account details, confirm, visible reCAPTCHA. It may open image-selection challenges (e.g. `select all images with a bus`) that browser snapshots expose but ref-clicking cannot target tile coordinates reliably; treat this as a manual/local-browser CAPTCHA blocker.
- NumVerify/APILayer asks for general details plus billing address fields even on the free plan, then Cloudflare Turnstile. Fill only reasonable non-sensitive billing locality details; if the Turnstile token remains empty, stop and report local-browser requirement.

## Reporting shape

Be blunt and operational:

- `Vault items created: N`
- `Accounts confirmed: provider list`
- `Blocked by email/CAPTCHA/local-browser requirement: provider list`
- `SpiderFoot settings configured: provider list`
- `SpiderFoot settings still empty: provider list`

This avoids implying that a pending vault item equals a working API key.
