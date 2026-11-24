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

T3 Code is not part of this package. It installs and updates itself and runs
under its own `t3code.service`.

The server NAS backup timer runs `server-nas-restic`. If restic creates a partial
snapshot because it cannot read some source files, the job exits with status 3
and skips retention for that run. The partial snapshot remains available for
inspection; a complete run resumes normal retention.
