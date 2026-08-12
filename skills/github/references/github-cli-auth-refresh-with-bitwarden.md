# GitHub CLI Auth Refresh with Bitwarden CLI

Use this when `gh auth refresh` needs extra OAuth scopes (for example `project` / `read:project`) and the browser/session needs GitHub credentials stored in Bitwarden.

## Pattern

1. Start with the real GitHub need, usually:

```bash
gh auth refresh -h github.com -s project -s read:project
```

2. If the device browser requires GitHub login, use Bitwarden CLI as the credential source, not guessed passwords.

3. For Semyon's Bitwarden account, the vault may be on the EU server. Configure before login when needed:

```bash
npx --yes @bitwarden/cli config server https://vault.bitwarden.eu
```

4. Prefer `--passwordfile` or `--passwordenv` over interactive shell typing so special characters such as `^` survive intact. Do not print the password. Write temporary password/session material under `/tmp`, then remove it after use.

5. **New-device OTP pitfall:** every fresh `bw login` attempt can invalidate the previous email OTP. Do not loop by restarting `bw login` for each code. Start one PTY/background login process, leave it waiting at `New device verification required`, then submit the user's latest OTP into that same process.

6. Capture the raw Bitwarden session from successful login and use it explicitly:

```bash
BW_SESSION=$(sed -n '1p' /tmp/bw_session_login.out)
npx --yes @bitwarden/cli sync --session "$BW_SESSION"
npx --yes @bitwarden/cli list items --search github --session "$BW_SESSION"
npx --yes @bitwarden/cli get item <item-id> --session "$BW_SESSION"
npx --yes @bitwarden/cli get password <item-id> --session "$BW_SESSION"
npx --yes @bitwarden/cli get totp <item-id> --session "$BW_SESSION"
```

7. In GitHub's device-code web flow, if already signed in, continue as the correct account, enter the current device code, authorize the CLI, then wait for the original `gh auth refresh` process to print `Authentication complete`.

8. Verify scopes after completion:

```bash
gh auth status
```

For GitHub Projects v2, `gh auth status` may show `project` rather than a separate `read:project`; the practical requirement is that Projects access is present and repo-agent Project sync no longer fails for missing scope.

9. Cleanup:

```bash
npx --yes @bitwarden/cli lock --session "$BW_SESSION"
rm -f /tmp/bw_session_login.out /tmp/gh_pw.txt /tmp/gh_totp.txt /tmp/bw_*.err /tmp/bw_*.out
```

Kill any temporary local credential-helper process if one was started.

## Safety notes

- Do not paste or report secrets, TOTP values, raw session keys, or passwords.
- Avoid repeated invalid login attempts; after one wrong password/server attempt, verify server URL and exact account before trying variants.
- Use the persisted Bitwarden item for GitHub (`semyonfox`) rather than deriving a GitHub password from hints or memory.
- Lock Bitwarden when finished unless the user explicitly wants the CLI left unlocked.
