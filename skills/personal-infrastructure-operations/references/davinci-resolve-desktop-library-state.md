# DaVinci Resolve desktop project-library state and safe cleanup

Use after registering/removing a PostgreSQL Network Project Library, or when Resolve unexpectedly reopens a local `New Project` after launch.

## Diagnose from the workstation log

- The useful internal log is `~/.local/share/DaVinciResolve/logs/ResolveDebug.txt`.
- Distinguish **registered libraries** from the **active project**. Startup may successfully connect to several PostgreSQL libraries, then select a local Disk Database project. Look for both `Connect to postgres project library ...` and `Current project pointer changed to ... from project library ...`.
- Normal codec, DeckLink, ProRes RAW, CUDA/NVENC, or unavailable hardware-plugin warnings are not evidence of a Project Library fault.
- Do not invoke `/opt/resolve/bin/resolve --help`: Resolve may interpret arbitrary arguments as a configuration filename rather than providing CLI help, and can abort. Launch it with no arguments.

## Persistent client state

- Resolve registers libraries in `~/.local/share/DaVinciResolve/configs/.dblist`. This file is colon-delimited and can contain database credentials in plaintext. **Never print, paste, commit, or broadly inspect its raw contents.** Redact the full credential segment or report only library names/hosts.
- The remembered project is in `~/.local/share/DaVinciResolve/configs/config.user.xml`, commonly as `<LastWorkingProject>...</LastWorkingProject>`.
- The local Disk Database should normally remain registered and preserved as a recovery source. Removing a temporary network-library entry must not delete a legacy local Disk Database.

## Remove a mistaken temporary network library

A Network Project Library has two separate pieces of state:

1. The PostgreSQL database on the server.
2. Its saved connection in the workstation `.dblist`.

When the user explicitly asks to remove it:

1. Verify the exact database name, target server/container, and library that must remain. Do not infer from similar names.
2. Take one final logical `pg_dump -Fc` to the NAS backup destination, verify it is non-empty, then terminate only that database's sessions and issue `DROP DATABASE` for the exact quoted name.
3. Verify the intended library remains and the deleted name no longer appears in `pg_database`.
4. Do not edit `.dblist` or `config.user.xml` while Resolve is running: a later normal exit can overwrite the repair. Ask the user to quit normally, or prepare a tightly scoped one-shot cleanup that waits for the Resolve process to exit. In a shell watcher, use an exact process-name test such as `pgrep -x resolve`; do not use `pgrep -f` with the same command-string pattern embedded in the watcher, because the watcher can match itself forever.
5. Before changing either client file, make timestamped same-directory backups. Remove only the exact unwanted `.dblist` line. Clear the stale `LastWorkingProject` only after confirming its exact expected old value. Leave all other settings untouched.
6. Relaunch Resolve with no arguments and verify in `ResolveDebug.txt` that only the intended network library is connected and that Project Manager opens without restoring the unwanted local project.

## Explicit source-retirement exception

The default is to preserve local Disk Databases. If Semyon explicitly requests a single retained migration archive and deletion of the old copies, do not delete an active local library while Resolve is open. First verify the PC archive and the NAS recovery archive against their manifest/checksum, wait for Resolve to exit, then remove only the enumerated source directories and write a receipt. Leave the parent Resolve configuration directory in place so the application can recreate an empty local library if needed.

For a migration, keep original Disk Databases and archives intact. Register/connect the intended existing Network Project Library first, then use Resolve-supported export/import/restore operations; never transplant raw Disk Database internals into PostgreSQL.
