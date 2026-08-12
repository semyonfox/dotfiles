---
name: linux-desktop-authentication
description: "Use when configure and verify Linux desktop login, fingerprint, PAM, sudo, and authentication-agent workflows safely."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Linux desktop authentication

Use for Linux desktop authentication changes: fingerprint readers, `fprintd`, PAM, GDM/SDDM login, screen unlock, sudo, polkit, and local account-access recovery.

## Principles

1. Treat authentication changes as potentially lockout-inducing. Inventory the active PAM graph and back up each edited file before mutation.
2. Preserve a password fallback. Fingerprint is a convenience factor, not the only recovery route.
3. Modify the narrowest PAM service that satisfies the request. Do not add modules to shared `system-auth`/`common-auth` merely because a single service such as sudo needs them.
4. A remote operator cannot supply a user password or physically touch a reader. Make the final authentication test local to the device owner and verify configuration read-back remotely afterward.
5. Never disclose passwords, biometric templates, auth tokens, or private key material in chat or logs.

## Fingerprint discovery and enrollment

1. Identify the desktop OS, user, graphical session, reader (`lsusb`/platform inventory), installed `fprintd` and `libfprint` packages, and recent `fprintd` journal entries.
2. Check current enrollment with the appropriate local authority. A direct SSH `fprintd-list` may be denied by the fprintd D-Bus policy even when enrollment exists; use logs and a local verification flow rather than treating that denial as evidence of no print.
3. On systemd systems, `fprintd.service` may be `static` and inactive between requests because D-Bus activation starts it on demand. Do not enable the unit solely to alter that expected status.
4. Enroll or re-enroll only with the account owner physically present at the reader. Confirm the hardware/driver and firmware path before blaming PAM.
5. Do **not** use `ssh -tt host 'sudo -v'` as the final fingerprint verdict. An SSH session is not the active local graphical seat, and fprintd/Polkit can legitimately deny biometric verification or make PAM fall through to its password prompt. This proves neither enrollment nor the local sudo path is broken; perform `sudo -k; sudo -v` at the laptop itself and inspect the scoped PAM file remotely.

## Arch/CachyOS: GDM unlock and sudo

### GDM

- Inspect `/etc/pam.d/gdm-fingerprint`, `/etc/pam.d/gdm-password`, `system-local-login`, `system-login`, and `system-auth` as an include graph.
- If the distribution already provides `gdm-fingerprint` using `pam_fprintd.so`, retain it. Validate screen/login behavior locally instead of duplicating fingerprint lines into the ordinary GDM password stack.

### Sudo with fingerprint or password

For Arch/CachyOS-style `/etc/pam.d/sudo` files containing:

```pam
auth    include    system-auth
```

place this immediately before it:

```pam
auth    sufficient    pam_fprintd.so
```

This produces the intended OR behavior:

- successful fingerprint: PAM accepts authentication;
- unavailable reader, missed print, or failure: PAM continues to `system-auth` for normal password and `pam_faillock` handling.

Do not add `pam_fprintd.so` to `system-auth` globally: it would affect every consumer, including graphical and non-interactive paths that did not request fingerprint authentication.

### Safe change sequence

1. Confirm the exact expected `sudo` include line before editing; refuse an unknown PAM layout.
2. Copy `/etc/pam.d/sudo` to a timestamped, permissions-preserving backup.
3. Insert only the scoped `pam_fprintd` line. Preserve all existing account and session includes.
4. Have the local owner open a fresh terminal and run:

   ```sh
   sudo -k
   sudo -v
   ```

   They should touch the reader when prompted. Then also test password fallback deliberately.
5. Keep the backup path available for rollback until both paths pass. Read the final PAM file back remotely if remote access is available.

## Local elevation blockers

If a remote session has no non-interactive `sudo` access, do not ask for or transmit a password. Instead, stage a small, syntax-checked, owner-readable helper with strict preconditions and a clear rollback path, then have the device owner run it locally under their own interactive sudo session. Verify its checksum and syntax before handing it over.

## Reporting

Report separately:

- reader/driver/firmware detection;
- enrollment evidence;
- PAM configuration state;
- local biometric test result;
- password-fallback result;
- backup/rollback location.

Do not call the setup working merely because packages are installed or a PAM line was written.
