# NAS CLI Config Recovery Pattern

This captures a reusable pattern from a session where Semyon wanted the Hermes/default server to be ready for AWS, Wrangler, Google, and other dashboard/devops CLIs without losing old auth/config state.

## Discovery pattern

When a config is missing from the live home directory, search the NAS user backup tree first:

```bash
root=/mnt/media/users/semyon
fdfind -H -t d '^(\.aws|\.config|\.wrangler|\.cloudflared|\.docker|\.kube|\.fly|\.netlify|\.railway|\.vercel|\.firebase|\.terraform\.d|\.1password)$' "$root"
```

Likely useful locations from the observed NAS layout:

```text
/mnt/media/users/semyon/device_dumps/linux-laptop/full-home-current
/mnt/media/users/semyon/device_dumps/linux-laptop/snapshots/<timestamp>/full-dot-home
/mnt/media/users/semyon/device_dumps/linux-laptop/snapshots/<timestamp>/home-dotfiles
/mnt/media/users/semyon/.recycle/semyon/device_dumps/linux-laptop/home-dotfiles-current
```

For AWS specifically, a live `.aws` was recovered from:

```text
/mnt/media/users/semyon/.recycle/semyon/device_dumps/linux-laptop/home-dotfiles-current/.aws
```

It contained profiles for `default`, `oghma`, `old-oghma`, and `personal`.

## Restore pattern

Back up any current config before replacing it:

```bash
stamp=$(date +%Y%m%d-%H%M%S)
for rel in .wrangler .cloudflared .docker .config/gh .config/rclone .config/configstore; do
  src="/mnt/media/users/semyon/device_dumps/linux-laptop/full-home-current/$rel"
  dest="$HOME/$rel"
  [ -e "$src" ] || continue
  [ -e "$dest" ] && cp -a "$dest" "$dest.backup.$stamp"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  cp -a "$src" "$dest" 2>/dev/null || cp -r "$src" "$dest"
done
```

For `.aws`, copy files plainly if preserving permissions across filesystems fails:

```bash
install -d -m 700 ~/.aws
cp "$src/config" ~/.aws/config
cp "$src/credentials" ~/.aws/credentials
chmod 600 ~/.aws/config ~/.aws/credentials
```

## Verification pattern

Keep auth and inventory checks redacted:

```bash
aws --version
aws configure list-profiles
for p in $(aws configure list-profiles); do
  aws sts get-caller-identity --profile "$p" --output text \
    | awk '{print "account=" $1 " user=" $2}'
done

gh auth status
rclone listremotes
wrangler whoami
gcloud auth list --format='value(account,status)'
```

Expected outcomes can be mixed:

- AWS profiles may work after restoring `~/.aws`.
- GitHub may work after restoring `~/.config/gh`.
- Rclone may show remotes after restoring `~/.config/rclone`.
- Wrangler config/token may restore but still be expired; next step is `wrangler login` or setting `CLOUDFLARE_API_TOKEN`.
- Google Cloud SDK may install cleanly but have no account configured; next steps are `gcloud auth login` and, for SDK ADC, `gcloud auth application-default login`.

## Final summary style

For Semyon, keep it blunt and action-oriented:

```text
Installed: <CLI list>
Restored configs: <dirs>
Working auth: AWS profiles, GitHub, rclone
Needs browser/login: Wrangler, gcloud/ADC
Inventory: ~/devops-cli-inventory-<timestamp>.txt
```

Do not dump token-bearing files or secret values into chat.
