# GAM profiles for Google Workspace email/admin work

Use this when a user asks for AWS-CLI-style profiles for GAM, or wants Hermes to manage multiple Google Workspace tenants/mailboxes through GAM.

## Key model

GAM profiles are `gam.cfg` sections. Select them per command:

```bash
gam select work info domain
gam select work print users
gam select work info user user@example.com
```

Persist a default profile:

```bash
gam select work save
```

Inspect profile state:

```bash
gam showsections
gam select work verify variables '^(section|config_dir|customer_id|domain|admin_email|oauth2_txt|oauth2service_json|client_secrets_json)$'
```

Example section:

```ini
[work]
admin_email = admin@example.com
domain = example.com
customer_id = my_customer
client_secrets_json = client_secrets.json
oauth2_txt = oauth2.txt
oauth2service_json = oauth2service.json
```

For fully separate Workspace tenants, prefer account-specific credential/cache files:

```ini
[personal]
admin_email = admin@personal-domain.example
domain = personal-domain.example
customer_id = my_customer
client_secrets_json = personal/client_secrets.json
oauth2_txt = personal/oauth2.txt
oauth2service_json = personal/oauth2service.json
cache_dir = /home/user/.gam/personal/gamcache
```

## Critical distinction

GAM manages Google Workspace / Cloud Identity tenants. It is not the right abstraction for a normal consumer `@gmail.com` account as a second admin profile. If the user says “personal Gmail”, clarify whether they mean:

- a consumer Gmail account like `name@gmail.com` → use Gmail API OAuth or IMAP/App Password depending on the task;
- a personal Google Workspace tenant/domain → use another GAM section/profile.

Do not build custom OAuth scaffolding when the user explicitly asked for GAM profile-style workflow. First answer the GAM-native model, then mention the consumer-Gmail limitation.

## User-data commands need DWD

Directory/admin metadata may work with `oauth2.txt`, while Gmail/Calendar/Drive user-data commands usually require a valid service account key plus domain-wide delegation.

Symptoms:

```text
Service Account OAuth2 File ... Does not exist or has invalid format
Unable to load PEM file ... MalformedFraming
```

Check whether `oauth2service.json` has a real `private_key`; an empty key means the file is invalid, not merely missing scopes.

Common finish path:

```bash
gam select work create project admin@example.com
gam select work user admin@example.com update serviceaccount
```

If using an existing valid service-account key:

```bash
gam select work upload sakey admin admin@example.com
gam select work user admin@example.com update serviceaccount
```

Verify with low-risk calls:

```bash
gam select work info domain
gam select work info user admin@example.com
gam select work user admin@example.com show labels
```

## Style/workflow lesson

When the user asks for a tool-native configuration pattern (“like AWS CLI profiles”), do not detour into bespoke scripts. Check the tool’s native profile/config mechanism first and keep the answer centered on that. If another approach is needed for a boundary case, explain it as a limitation/fallback, not as the primary plan.
