# Google Workspace email/admin via GAM profiles

Use this when the user asks about Google Workspace, GAM, or an AWS-CLI-like profile setup for multiple Google domains/accounts.

## Key model

GAM supports profile-like switching through `gam.cfg` sections:

```ini
[DEFAULT]
section = oghmanotes

[oghmanotes]
admin_email = admin@example.com
domain = example.com
customer_id = my_customer
client_secrets_json = client_secrets.json
oauth2_txt = oauth2.txt
oauth2service_json = oauth2service.json
```

Commands:

```bash
gam showsections
gam select oghmanotes verify variables '^(section|config_dir|customer_id|domain|admin_email|oauth2_txt|oauth2service_json|client_secrets_json)$'
gam select oghmanotes info domain
gam select oghmanotes print users
gam select oghmanotes info user user@example.com
gam select oghmanotes save   # persist as default section
```

This is the GAM-native equivalent of AWS CLI profiles. Prefer this before inventing wrapper scripts or separate custom API bridges.

## Important boundary

GAM profiles are for Google Workspace / Cloud Identity tenants. A consumer Gmail account such as `name@gmail.com` is not a Workspace tenant and cannot be administered as a normal GAM customer/profile. If the user says “personal Gmail” and means a consumer `@gmail.com`, do not create a fake GAM section for it. Use OAuth/Gmail API only if they explicitly accept a non-GAM path.

If the personal domain is itself a Workspace tenant, e.g. `personal-domain.com`, then create a second GAM section with its own credentials and service account files.

## User-data access versus admin metadata

Directory/admin commands can work with admin OAuth alone. Gmail/Calendar/Drive user-data commands usually require a valid service account key plus domain-wide delegation.

Typical failure for an incomplete service-account setup:

```text
Service Account OAuth2 File ... oauth2service.json ... invalid format ... MalformedFraming
```

Check whether `oauth2service.json` has a real `private_key`; an empty private key means the service account file is invalid, not merely unauthorized. Move the bad file aside before `gam use project` / `gam create project`, because GAM refuses to overwrite existing credential files.

Finish/repair Workspace DWD flow:

```bash
gam select <profile> create project <admin@example.com>
# or, if using an existing valid service account key:
gam select <profile> upload sakey admin <admin@example.com>

gam select <profile> user <user@example.com> update serviceaccount
```

Verify user-data access:

```bash
gam select <profile> user <user@example.com> show labels
gam select <profile> user <user@example.com> print messages max 10
```

## Workflow preference learned

When the user asks for “GAM to work here” or asks whether there is an option like AWS CLI profiles, answer and configure the GAM profile mechanism directly. Do not pivot to a custom Gmail OAuth helper unless GAM cannot cover the account class and the user agrees to that alternative.
