# Guarded AMP updates

Both Bash and Zsh `update()` call the same Stow-managed `~/.local/bin/update-amp` when AMP is installed on Linux. The existing `update` command applies updates; it is not a preview. Other hosts skip AMP.

The helper currently supports the existing APT-owned `ampinstmgr` installation and the `amp` service account. Other package owners fail explicitly rather than installing a competing copy. It checks noninteractive administrator and service-account access before changing anything. For interactive use, authenticate in your own terminal with `sudo -v`; do not provide a password in chat.

Before allowing a restart, confirm a completed consistent backup of AMP configuration and all affected worlds. Stop/quiesce affected instances for the snapshot using the panel/native procedures, retain an inventory of originally running instances and their versions/channels, verify the backup, and restore the original running state. A tar archive of live worlds is not sufficient. The helper asks for confirmation on a terminal; unattended use fails unless `AMP_UPDATE_BACKUP_CONFIRMED=1` is explicitly set after backup verification. The environment flag is an operator attestation, not backup automation.

Then, in the authenticated terminal:

    AMP_UPDATE_BACKUP_CONFIRMED=1 ~/.local/bin/update-amp

This refreshes APT metadata and upgrades only the already-installed `ampinstmgr` package, then calls as `amp`:

    ampinstmgr --nocache --UpgradeAll true true

The flags mean restart already-running instances and update Mainline instances only. Stopped instances remain stopped; beta/nightly instances are not converted. No game application update, nightly Pumpkin update, cron job, network change or `getamp` installer unit installation is added. Package metadata refresh does not mean all system packages are upgraded.

Afterward verify panel HTTP/login, running ADS version, each original instance's version/state, game protocol/status and world availability. Command completion alone is not an application-health check. If verification fails, stop the affected instance and use the retained same-version installation/configuration/world snapshot as the rollback source; do not overwrite a live world.

Primary procedure: https://discourse.cubecoders.com/t/how-to-update-amp-to-the-latest-version/2297
Mainline manifest: https://downloads.cubecoders.com/AMP/manifest.json

Tests (no actual upgrades):

    bash tests/update-shell-functions.sh
    python3 tests/update-amp.py
