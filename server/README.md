# Server profile

Ubuntu/headless overlay for the always-on server.

Deploy with:

```bash
stow --no-folding home claude server
```

This package owns:

- `~/.config/dotfiles/machine-profile`
- `~/.config/dotfiles/host.bash`
- `~/.config/dotfiles/host.zsh`
- `~/.config/systemd/user/t3-code-headless.service`
- `~/bin/t3-headless-preflight`
- `~/bin/t3-headless-run`

After first deploy, enable the T3 user service manually:

```bash
systemctl --user daemon-reload
systemctl --user enable --now t3-code-headless.service
```

The server NAS backup timer runs `server-nas-restic`. If restic creates a partial
snapshot because it cannot read some source files, the job exits with status 3
and skips retention for that run. The partial snapshot remains available for
inspection; a complete run resumes normal retention.
