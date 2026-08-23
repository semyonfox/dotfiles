# Public Safety

This dotfiles repo is public. Before committing, assume every tracked byte will be visible on GitHub.

Do not track:

- SSH private keys, known private certs, recovery codes, or password manager data
- API tokens, OAuth refresh tokens, service tokens, cookies, or browser profiles
- Real `.env` files, systemd units with inline secrets, or Cloudflare tunnel credentials
- Local caches, histories, generated auth state, or downloaded binary installs
- Machine-private files from `~/.ssh`, `~/.gnupg`, browser config dirs, or password stores
- Codex auth/session/task state, plugin caches, sqlite databases, memories, generated images, and private `device-fleet` references
- Raw OBS Studio scene/profile/plugin state unless deliberately scrubbed; it can contain stream settings, overlay URLs, device IDs, browser-source state, and personal scene names

Safe to track:

- Source-like shell scripts
- Public config files without credentials
- Example env files with obvious placeholder values
- Systemd unit templates that call local scripts and contain no secrets
- Host-specific display, Waybar, Hyprland, and public helper config
- Claude/Codex agent or skill markdown when it contains reusable instructions only

Useful checks:

```bash
rg -n -i "(password|secret|token|private[_-]?key|BEGIN .*PRIVATE|credential|apikey|api_key|bearer)" .
git diff --check
```
