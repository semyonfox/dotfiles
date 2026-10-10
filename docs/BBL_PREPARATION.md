# bbl preparation snapshot

This branch preserves the nonsecret bbl preparation captured on 2026-10-10
(task `t_70e99e4c`, origin Discord thread `1558440360273780737`). It does not
convert disks, install packages, deploy configs or enroll any service.

## Why a separate package

bbl's `~/dotfiles` was clean at upstream commit
`57c4903208cf84e6ac3df4c52a8d76504b31c152`, but the actual active Stow package
was `~/.local/share/bbl-stow-t_0e922822/home`. Its host adaptations and operator
installer were not in Git. The new `bbl/` package mirrors `$HOME` and records
that selected configuration verbatim, rather than copying unrelated dirty
server changes or deploying the much broader `home/` package.

The 14 text configuration/documentation files and the standalone installer
match their captured bbl bytes. `docs/bbl-capture-manifest.json` records their
original paths, SHA-256 hashes and lengths. Bash/Zsh functions and aliases,
Starship and chadmux configuration are the pinned upstream versions. The
Bash startup guard, Bash tmux shell/no TPM invocation, minimal Git identity,
matching Bash/Zsh host overrides, scoped Ubuntu updater, access notes and
Jenkins preparation are retained. No `.zshrc` was deployed on bbl; Zsh files
are staged only, not proof of a working Zsh login or a shell switch.

This snapshot deliberately does not repair existing startup ordering: the
Bash host override is sourced before later gaming environment assignments
and the `zed` alias, so those later assignments override its intended
unsets/alias suppression. Restoring this snapshot preserves that observed
behavior; it must not be described as a completely GUI-free shell. `update`
uses the bbl wrapper; unsafe aliases named in the host override are suppressed
apart from the later reintroduced `zed`. Shell repairs belong in a separately
reviewed change, not an undocumented alteration of recovery evidence.

## Restore boundaries

Only after reviewing current state and backing up conflicting files, use
this exact branch/commit as the source. Never blindly replace existing links.
An isolated new target can be previewed with:

    stow --simulate --no-folding --dir=/path/to/dotfiles --target=/new/target bbl

For a reviewed deployment to bbl, select only `bbl`, never `home` as well.
Current bbl links still point to the old selected package; this commit does
not retarget them. `.stow-local-ignore` explicitly keeps the nested Jenkins
README deployable (Stow's default README filter would otherwise omit it).
No setup profile or auto-detection has been changed.

The captured installer expects the repository at `$HOME/dotfiles` and reads
its canonical `lib/common.sh` and `lib/package-lists.sh`. Its default mode is
APT simulation; `--install` requires a human terminal and explicit package
installation approval. No sudo prompt or package installation was attempted
by the preservation task. The updater defaults to cached-index APT simulation;
`--apply` remains an explicitly chosen interactive maintenance action.

The original user-local `gh` and `stow` executables are not committed. Obtain
Ubuntu-packaged GNU Stow and GitHub CLI through the operator package step
before deployment; do not substitute copied server binaries or credentials.
Nonsecret GitHub CLI preferences (`.config/gh/config.yml`) are also captured;
they are not login evidence. No `hosts.yml` or token store is included.
The Jenkins README records an empty workspace; no agent/service registration
or secret exists in this package. Create any future workspace under a separately
approved service provisioning step.

## Not a recovery backup

This is public dotfiles preservation only. No SSH files/private keys, known
hosts, GitHub/provider tokens, Jenkins secrets, histories, OS/boot/disk state,
ignored/untracked work, application data, local binaries or private recovery
images are included. Access notes describe provisional LAN addresses, not
permission to change networking. Conversion continuation `t_c3d92ffa` remains
blocked on independent live-USB rescue and subsequent private recovery gates.
The pushed Git SHA is not a substitute for that backup/restore evidence.
