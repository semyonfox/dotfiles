# GAM Workspace profiles and Gmail access

Use this when the user wants Hermes/CLI access to Google Workspace mail/admin data and mentions GAM, Google Workspace, Gmail, or AWS-CLI-style profiles.

## Key distinction

- GAM profiles are `gam.cfg` sections, selected with `gam select <section> ...`.
- GAM is for Google Workspace / Cloud Identity tenants, not ordinary consumer `@gmail.com` accounts.
- Consumer Gmail such as `semyon.fox@gmail.com` needs Gmail app-password IMAP/SMTP or Gmail API OAuth, not a fake GAM profile.
- Workspace mailboxes such as `semyon@oghmanotes.ie` can be accessed through GAM only after service account + domain-wide delegation are valid.

## Profile workflow

Inspect current sections:

```bash
gam showsections
gam select <section> verify variables '^(section|config_dir|customer_id|domain|admin_email|oauth2_txt|oauth2service_json|client_secrets_json)$'
```

Create/rename sections in `~/.gam/gam.cfg`:

```ini
[oghmanotes]
admin_email = semyon@oghmanotes.ie
domain = oghmanotes.ie
customer_id = my_customer
client_secrets_json = client_secrets.json
oauth2_txt = oauth2.txt
oauth2service_json = oauth2service.json
```

Persist a default section:

```bash
gam select oghmanotes save
```

Use explicitly in scripts:

```bash
gam select oghmanotes info domain
gam select oghmanotes print users
gam select oghmanotes info user semyon@oghmanotes.ie
```

## Workspace mailbox/user-data access

Admin directory commands working does not prove Gmail/Calendar/Drive user-data commands work. For Gmail labels/messages, GAM needs a valid service account key and domain-wide delegation.

Common symptoms:

- `oauth2service.json` exists but has empty/invalid `private_key`
- `show labels` or message commands fail with service-account PEM/key errors

Setup/repair path:

```bash
gam select oghmanotes upload sakey admin semyon@oghmanotes.ie
# Complete browser auth, paste code/redirect URL back into GAM if on headless server.

gam select oghmanotes user semyon@oghmanotes.ie update serviceaccount
# Complete the Admin Console / domain-wide delegation authorization step if prompted.
```

Verify:

```bash
gam select oghmanotes user semyon@oghmanotes.ie show labels
gam select oghmanotes user semyon@oghmanotes.ie print messages max 10
```

## Interaction pattern

When the user asks to make GAM work, do not detour into custom OAuth helper scripts unless they explicitly ask for non-Workspace consumer Gmail automation. First make `gam select <profile>` and the on-device GAM configuration work, then handle consumer Gmail as a separate access model.
