#!/usr/bin/env bash
set -eu
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
real_stow="$(command -v stow)"
bash_bin="$(command -v bash)"
work="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup-test.XXXXXX")"
trap 'rm -rf -- "$work"' EXIT
setup_case() {
    local name=$1
    mkdir -p "$work/$name/repo/pkg" "$work/$name/repo/lib" "$work/$name/home" "$work/$name/bin"
    cp "$repo/setup.sh" "$work/$name/repo/setup.sh"
    cp "$repo/lib/common.sh" "$work/$name/repo/lib/common.sh"
    printf 'source\n' > "$work/$name/repo/pkg/already"
    printf 'source\n' > "$work/$name/repo/pkg/new"
    printf 'source\n' > "$work/$name/repo/pkg/existing"
}
setup_case rollback
case_dir="$work/rollback"
ln -s ../repo/pkg/already "$case_dir/home/already"
printf 'old\n' > "$case_dir/home/existing"
collision="$case_dir/home/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir "$collision"
printf 'keep\n' > "$collision/existing"
cat > "$case_dir/bin/stow" <<'STOW'
#!/usr/bin/env bash
if [[ " $* " == *' -n '* ]]; then exec "$REAL_STOW" "$@"; fi
ln -s ../repo/pkg/new "$HOME/new"
exit 42
STOW
chmod +x "$case_dir/bin/stow"
if printf 'y' | env REAL_STOW="$real_stow" HOME="$case_dir/home" PATH="$case_dir/bin:$PATH" "$bash_bin" "$case_dir/repo/setup.sh" --packages pkg > "$case_dir/log" 2>&1; then exit 10; fi
test -L "$case_dir/home/already"
test ! -e "$case_dir/home/new"
test "$(cat "$case_dir/home/existing")" = old
test "$(cat "$collision/existing")" = keep
printf 'rollback passed\n'
setup_case no_backup
case_dir="$work/no_backup"
cat > "$case_dir/bin/stow" <<'STOW'
#!/usr/bin/env bash
if [[ " $* " == *' -n '* ]]; then exec "$REAL_STOW" "$@"; fi
ln -s ../repo/pkg/new "$HOME/new"
exit 42
STOW
chmod +x "$case_dir/bin/stow"
if env REAL_STOW="$real_stow" HOME="$case_dir/home" PATH="$case_dir/bin:$PATH" "$bash_bin" "$case_dir/repo/setup.sh" --packages pkg > "$case_dir/log" 2>&1; then exit 12; fi
test ! -e "$case_dir/home/new"
printf 'rollback without backup passed\n'
setup_case foreign
case_dir="$work/foreign"
printf 'foreign\n' > "$case_dir/home/other"
cat > "$case_dir/bin/stow" <<'STOW'
#!/usr/bin/env bash
if [[ " $* " == *' -n '* ]]; then exec "$REAL_STOW" "$@"; fi
ln -s other "$HOME/new"
exit 42
STOW
chmod +x "$case_dir/bin/stow"
if env REAL_STOW="$real_stow" HOME="$case_dir/home" PATH="$case_dir/bin:$PATH" "$bash_bin" "$case_dir/repo/setup.sh" --packages pkg > "$case_dir/log" 2>&1; then exit 13; fi
test -L "$case_dir/home/new"
test "$(cat "$case_dir/home/new")" = foreign
printf 'foreign symlink preserved\n'
setup_case dry
case_dir="$work/dry"
printf 'old\n' > "$case_dir/home/existing"
cat > "$case_dir/bin/stow" <<'STOW'
#!/usr/bin/env bash
printf 'synthetic failure\n' >&2
exit 42
STOW
chmod +x "$case_dir/bin/stow"
if env REAL_STOW="$real_stow" HOME="$case_dir/home" PATH="$case_dir/bin:$PATH" "$bash_bin" "$case_dir/repo/setup.sh" --dry-run --packages pkg > "$case_dir/log" 2>&1; then exit 11; fi
test "$(cat "$case_dir/home/existing")" = old
test "$(find "$case_dir/home" -maxdepth 1 -name 'dotfiles_backup_*' | wc -l)" = 0
printf 'dry-run failure passed\n'
setup_case target
case_dir="$work/target"
cat > "$case_dir/bin/stow" <<'STOW'
#!/usr/bin/env bash
exec "$REAL_STOW" "$@"
STOW
chmod +x "$case_dir/bin/stow"
env REAL_STOW="$real_stow" HOME="$case_dir/home" PATH="$case_dir/bin:$PATH" "$bash_bin" "$case_dir/repo/setup.sh" --packages pkg > "$case_dir/log" 2>&1
test -L "$case_dir/home/new"
test ! -e "$case_dir/new"
printf 'explicit target passed\n'
setup_case parent
case_dir="$work/parent"
mkdir "$case_dir/external" "$case_dir/repo/pkg/.config"
ln -s ../external "$case_dir/home/.config"
printf 'source\n' > "$case_dir/repo/pkg/.config/foo"
printf 'external original\n' > "$case_dir/external/foo"
cat > "$case_dir/bin/stow" <<'STOW'
#!/usr/bin/env bash
exec "$REAL_STOW" "$@"
STOW
chmod +x "$case_dir/bin/stow"
if printf 'y' | env REAL_STOW="$real_stow" HOME="$case_dir/home" PATH="$case_dir/bin:$PATH" "$bash_bin" "$case_dir/repo/setup.sh" --packages pkg > "$case_dir/log" 2>&1; then exit 14; fi
test "$(cat "$case_dir/external/foo")" = 'external original'
test "$(find "$case_dir/home" -maxdepth 1 -name 'dotfiles_backup_*' | wc -l)" = 0
printf 'symlinked parent refused before backup\n'
setup_case modes
case_dir="$work/modes"
mkdir "$case_dir/home/.config" "$case_dir/repo/pkg/.config"
printf 'old\n' > "$case_dir/home/existing"
printf 'old nested\n' > "$case_dir/home/.config/foo"
printf 'new nested\n' > "$case_dir/repo/pkg/.config/foo"
chmod 755 "$case_dir/home"
chmod 700 "$case_dir/home/.config"
cat > "$case_dir/bin/stow" <<'STOW'
#!/usr/bin/env bash
if [[ " $* " == *' -n '* ]]; then exec "$REAL_STOW" "$@"; fi
exit 42
STOW
chmod +x "$case_dir/bin/stow"
if printf 'y' | env REAL_STOW="$real_stow" HOME="$case_dir/home" PATH="$case_dir/bin:$PATH" "$bash_bin" "$case_dir/repo/setup.sh" --packages pkg > "$case_dir/log" 2>&1; then exit 15; fi
test "$(cat "$case_dir/home/existing")" = old
test "$(cat "$case_dir/home/.config/foo")" = 'old nested'
test "$(ls -ld "$case_dir/home" | cut -c1-10)" = 'drwxr-xr-x'
test "$(ls -ld "$case_dir/home/.config" | cut -c1-10)" = 'drwx------'
printf 'directory modes preserved\n'
