# Google Workspace / Domain Email Audit

Use this when Semyon asks whether a domain/email is configured in Google Workspace, GAM, Gmail, or DNS.

## Fast path

1. Locate GAM without assuming it is on PATH:
   - `command -v gam || true`
   - check known local installs such as `~/bin/gam7/gam`
   - inspect `~/.gam/gam.cfg` for config location, customer ID, default domain, and cache dir.
2. Confirm Workspace identity:
   - `gam version`
   - `gam info domain`
   - `gam print domains`
3. Inventory mail-bearing objects:
   - `gam print users fields primaryemail,fullname,isadmin,isdelegatedadmin,suspended,aliases,noneditablealiases,orgunitpath,lastlogintime,ismailboxsetup,recoveryemail`
   - `gam print groups`
   - `gam print aliases`
   - `gam print licenses`
4. Compare with public DNS for each relevant domain:
   - `dig +short MX <domain>`
   - `dig +short TXT <domain>` for SPF and verification records
   - `dig +short TXT _dmarc.<domain>`
   - `dig +short TXT google._domainkey.<domain>` for Google DKIM
   - `dig +short NS <domain>` if registrar/DNS host matters
5. State the distinction clearly:
   - domain is in this Google Workspace vs routed elsewhere
   - Gmail/recovery/admin secondary email vs actual Workspace mailbox
   - user mailbox vs group vs alias
   - Workspace domain vs Cloudflare/email-hosted personal domain

## GAM syntax notes

- GAM field names are picky. Use `fullname`, not `name.fullName`, in `gam print users fields ...`.
- `gam print aliases` can return no aliases even when users have non-editable alias domains; check `noneditablealiases` on users too.
- Local GAM may be installed under `~/bin/gam7/gam` even if `gam` is not on PATH.

## DNS interpretation notes

- Google Workspace MX may appear as `smtp.google.com` on newer setups.
- Google SPF should usually be present as `v=spf1 include:_spf.google.com ~all` unless another deliberate sender policy exists.
- DKIM check for Google defaults to `google._domainkey.<domain>` unless a custom selector was chosen.
- If a personal domain has MX pointing to a provider-specific host and SPF including a non-Google provider, do not infer it is on Google Workspace just because the same person owns both domains.

## Safety

DNS and Workspace changes are external and mail-affecting. Audit freely, but ask before changing MX/SPF/DKIM/DMARC, adding domains, migrating mailboxes, or deleting/renaming groups/users.