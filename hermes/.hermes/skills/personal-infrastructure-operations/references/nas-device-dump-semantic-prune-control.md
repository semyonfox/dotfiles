# NAS device-dump semantic consolidation and controlled pruning

Use after a user has explicitly approved replacing a collection of dated device/home dumps with one newest canonical full-home copy.

## Canonical choice

1. Inventory candidate roots NAS-locally: modification time, regular-file count, apparent bytes, and shallow layout. Do not infer completeness from a snapshot name alone.
2. Pick the newest/most complete full-home root as canonical; do not overwrite it from older sources.
3. If T3 Code is now the user's active harness, explicitly check that `canonical/.t3` exists before classifying old agent/config trees as disposable. A remote Git origin protects tracked dotfiles, not necessarily `.t3` sessions/history or credentials.

## Preserve useful non-dotfile payloads

1. Make a dry-run manifest from each legacy full-home source to canonical with `rsync -ani --ignore-existing`.
2. When the user says dotfiles are not needed, exclude hidden entries and dedicated dotfiles directories. Treat that as a scoped user choice, not evidence that every hidden directory is Git-backed.
3. Promote only paths missing from canonical using `rsync -ai --ignore-existing`; canonical wins on collisions because it is the chosen newer copy.
4. Hash every promoted regular source/destination pair with SHA-256 and require zero mismatches. Save the manifests and verification report inside a non-pruned audit directory under the canonical root.

## Prune safely

- Capture a pre-mutation Btrfs allocation baseline before dedupe/prune when physical-reclaim reporting matters.
- Verify the canonical root and its required `.t3` state immediately before every destructive stage.
- Write a receipt *before* removal, recording canonical path, SHA-256 verification result, and exact target.
- Remove **one legacy root per tracked NAS-resident job**, not a single `rm -rf` invocation with several huge roots. Checkpoint after each root: process exit, target absence, canonical existence, and receipt update.
- For Btrfs subvolumes, use `btrfs subvolume delete`; do not use `rm -rf`.
- Remote SSH/control-process interruption can leave an `rm` worker continuing independently or leave an ambiguous partially deleted tree. Query the NAS process table and exact target paths before starting a replacement job. Never report pruning complete based only on loss of the local SSH session.

## Report

State separately:

- canonical path and required-agent-state check;
- promoted non-dotfile entries and SHA-256 mismatch count;
- each deleted root (only after absence check);
- any partially processed root that needs a restarted, one-root cleanup job.
