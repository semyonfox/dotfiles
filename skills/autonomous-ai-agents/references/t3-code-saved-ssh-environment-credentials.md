# T3 Code saved SSH environment credential failures

Use this reference when debugging T3 Code (`pingdotgg/t3code`, the coding-agent control plane), especially errors like:

```text
Unable to persist saved environment credentials.
(local http://127.0.0.1:<local-port>/, remote port <port>, remote server external)
```

## What the error means

This is usually not proof that the remote host or LAN path is unreachable. T3 Code has already reached the point where it knows the local forwarded URL and remote port. The failure occurs when it tries to persist the saved environment credential/bearer token.

In T3 Code source, this message is thrown after `writeSavedEnvironmentBearerToken(environmentId, bearerSession.access_token)` returns false. For desktop builds, that path uses Electron `safeStorage` via the desktop saved-environments persistence layer.

## High-probability causes

1. **OS credential storage unavailable to Electron**
   - On Linux, Electron `safeStorage.isEncryptionAvailable()` can fail/return false if Secret Service/keyring is missing, locked, or unavailable in the launch session.
   - AppImage/minimal WM/KDE/GNOME keyring/DBus session issues are common suspects.
   - Avoid launching T3 Code from SSH, sudo, systemd service contexts, or odd terminal sessions that lack DBus/keyring access.

2. **Stale saved SSH environment state**
   - Relevant upstream issue: `pingdotgg/t3code#2914` — saved SSH environments can reappear or lose rollback state during removal.
   - Relevant PR found during research: `#2917` — atomic saved-environment removal. Verify current release/merge status before relying on it.
   - Symptom pattern: delete/re-add same SSH target, then credential persistence fails or stale state reappears.

3. **Writable state file or registry mismatch**
   - T3 Code stores saved environments under `~/.t3/userdata/saved-environments.json` by default.
   - A missing/unwritable/corrupt registry can prevent the secret from being attached to the saved environment record.

## Debugging checklist

1. Confirm it is actually T3 Code, not a generic T3/Next.js app.
2. Search upstream first with exact strings:
   - `"T3 Code" "Unable to persist saved environment credentials"`
   - `site:github.com/pingdotgg/t3code/issues "saved environment" credentials`
3. Check/update T3 Code version from GitHub releases/package manager.
4. On Linux, test Secret Service/keyring availability from the same desktop session:

```bash
echo "test-secret" | secret-tool store --label="t3-test" app t3-test key test
secret-tool lookup app t3-test key test
secret-tool clear app t3-test key test
```

Install helpers if missing, for example:

```bash
sudo apt install gnome-keyring libsecret-tools
# or
sudo pacman -S gnome-keyring libsecret
```

Then log out/in or restart the desktop session.

5. Back up and inspect T3 saved environment state:

```bash
cp ~/.t3/userdata/saved-environments.json ~/.t3/userdata/saved-environments.json.bak.$(date +%s)
jq . ~/.t3/userdata/saved-environments.json
```

Look for stale entries referencing the SSH target, `desktopSsh`, the remote host, or the relevant port.

6. If stale state is likely and the user accepts losing saved T3 environments, move the registry aside and re-pair:

```bash
mv ~/.t3/userdata/saved-environments.json ~/.t3/userdata/saved-environments.json.disabled.$(date +%s)
```

Restart T3 Code fully, then add the SSH environment again.

## Reporting style

Separate three layers clearly:

- **Network reachability**: laptop can reach remote host/SSH/port.
- **T3 bootstrap/forwarding**: local forwarded URL and remote server diagnostics exist.
- **Credential persistence**: Electron safeStorage/keyring or stale saved-environment registry failed.

Do not keep chasing LAN DNS/routing once the error points at saved environment credential persistence unless a fresh probe shows the remote is unreachable.
