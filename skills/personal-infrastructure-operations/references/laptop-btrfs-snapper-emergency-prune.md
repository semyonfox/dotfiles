# Laptop Btrfs/Snapper emergency space recovery over Tailscale

Use when Semyon's Linux laptop is full and Btrfs/Snapper snapshots are suspected.

## Target discovery

The laptop may be reachable via Tailscale. Check live status first:

```bash
tailscale status | grep -i 'semyons-laptop\|laptop'
ssh -o BatchMode=yes -o ConnectTimeout=5 semyon@<tailscale-ip> 'hostname; df -hT / /home; findmnt -t btrfs; command -v snapper'
```

Observed laptop shape:

- host: `semyons-laptop`
- Btrfs over LUKS
- root subvolume mounted at `/`
- home subvolume mounted at `/home`
- Snapper configs: `root`, `home`
- snapshot dirs: `/.snapshots`, `/home/.snapshots`

## First baseline

Capture these before destructive work:

```bash
df -hT / /home
sudo btrfs filesystem usage /
sudo /usr/bin/snapper --csvout -c root list
sudo /usr/bin/snapper --csvout -c home list
```

If sudo is unavailable non-interactively, use a PTY and have the user provide the password. Do not pipe passwords to `sudo -S`; Hermes blocks that pattern and it is unsafe. Pattern:

1. Write a root-run script to `/tmp/...sh` over SSH.
2. Start it with `ssh -tt ... 'sudo bash /tmp/...sh'` in a tracked background process.
3. When the process prompts for the sudo password, submit the password interactively via the process tool.

## Emergency breathing room without sudo

If the filesystem has ~0 bytes free and sudo is needed, remove safe user caches first to give Btrfs enough room to breathe:

```bash
rm -rf --one-file-system \
  ~/.cache/paru \
  ~/.cache/spotify \
  ~/.cache/uv \
  ~/.cache/puppeteer \
  ~/.cache/hyde \
  ~/.cache/net.imput.helium \
  ~/.cache/electron \
  ~/.cache/pnpm \
  ~/.cache/.bun \
  ~/.cache/thumbnails
sync
df -hT / /home
```

Note: deleting live files may not surface much space if old snapshots still retain them. In the observed emergency, user cache deletion reduced `~/.cache` from ~22 GiB to <1 GiB but only exposed ~100–200 MiB until snapshots were pruned.

## Prune snapshots while keeping latest

Use Snapper, not raw `rm -rf`. Snapper table output can use box-drawing characters; parse CSV output instead.

Root-run script pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail
SNAPPER=/usr/bin/snapper

echo "== before =="
df -hT / /home
btrfs filesystem usage / | sed -n '1,50p'

delete_old_for_cfg() {
  cfg="$1"
  echo "== $cfg snapshots before =="
  "$SNAPPER" --csvout -c "$cfg" list

  mapfile -t nums < <(
    "$SNAPPER" --csvout -c "$cfg" list |
      awk -F, 'NR>1 && $3 ~ /^[0-9]+$/ && $3 != 0 {print $3}'
  )

  if [ "${#nums[@]}" -le 1 ]; then
    echo "Nothing to prune for $cfg; keeping ${nums[*]:-none}"
    return 0
  fi

  latest="${nums[$((${#nums[@]}-1))]}"
  echo "Keeping latest $cfg snapshot: $latest"

  for n in "${nums[@]}"; do
    if [ "$n" != "$latest" ]; then
      echo "Deleting $cfg snapshot $n"
      "$SNAPPER" -c "$cfg" delete "$n"
    fi
  done

  echo "== $cfg snapshots after =="
  "$SNAPPER" --csvout -c "$cfg" list
}

delete_old_for_cfg root
delete_old_for_cfg home

btrfs filesystem sync /
sync

echo "== after =="
df -hT / /home
btrfs filesystem usage / | sed -n '1,80p'
```

## Post-prune verification

Run:

```bash
df -hT / /home
sudo /usr/bin/snapper --csvout -c root list
sudo /usr/bin/snapper --csvout -c home list
sudo btrfs filesystem usage /
```

Expected final shape for “keep latest”:

- each config has `0` current plus one real snapshot
- `df` has meaningful free space
- Btrfs `Free (estimated)` roughly matches `df`

## Pitfalls

- Do not trust `snapper list-configs` without specifying a command correctly; on this laptop some invocations returned `'unknown': I need something more specific.` Use explicit `/usr/bin/snapper --csvout -c <config> list` for machine parsing.
- If package managers run during recovery, new root snapshots may be created after pruning. Re-check and prune again if “keep latest” means literally one root snapshot.
- Btrfs may not expose freed space immediately until snapshot deletion finishes and `btrfs filesystem sync /` completes.
- Do not recursively delete `.snapshots` directories manually; use `snapper -c <config> delete <num>`.
