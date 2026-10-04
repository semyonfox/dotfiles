#!/usr/bin/env bash
# Exercise a healthy and a corrupt pipx environment without contacting PyPI.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/pipx/venvs/aaa-null" "$tmp/pipx/venvs/gns3-gui" "$tmp/pipx/venvs/platformio"

cat > "$tmp/bin/pipx" <<'EOF'
#!/usr/bin/env bash
printf 'MOCK pipx %s\n' "$*"
EOF
chmod +x "$tmp/bin/pipx"
cat > "$tmp/pipx/venvs/gns3-gui/pipx_metadata.json" <<'EOF'
{"main_package":{"package_or_url":"gns3-gui==3.0.6"}}
EOF
cat > "$tmp/pipx/venvs/aaa-null/pipx_metadata.json" <<'EOF'
{"main_package":null}
EOF
: > "$tmp/pipx/venvs/platformio/pipx_metadata.json"

output="$(HOME="$tmp/home" PATH="$tmp/bin:$PATH" PIPX_HOME="$tmp/pipx" bash "$repo/home/.local/bin/update-pipx-venvs" 2>&1)"
[[ "$output" == *'skipped corrupt environment: aaa-null'* ]]
[[ "$output" == *'MOCK pipx upgrade gns3-gui'* ]]
[[ "$output" == *'skipped corrupt environment: platformio'* ]]
[[ "$output" == *'pipx install platformio'* ]]
[[ "$output" != *'MOCK pipx upgrade platformio'* ]]

cat > "$tmp/bin/pipx" <<'EOF'
#!/usr/bin/env bash
printf 'MOCK pipx %s\n' "$*"
exit 1
EOF
if HOME="$tmp/home" PATH="$tmp/bin:$PATH" PIPX_HOME="$tmp/pipx" bash "$repo/home/.local/bin/update-pipx-venvs" > "$tmp/failed-output" 2>&1; then
    echo 'FAIL: a failed pipx upgrade must fail the helper' >&2
    exit 1
fi
output="$(cat "$tmp/failed-output")"
[[ "$output" == *'pipx failed to upgrade gns3-gui'* ]]

cat > "$tmp/bin/python3" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$tmp/bin/python3"
if HOME="$tmp/home" PATH="$tmp/bin:$PATH" PIPX_HOME="$tmp/pipx" bash "$repo/home/.local/bin/update-pipx-venvs" > "$tmp/scanner-output" 2>&1; then
    echo 'FAIL: a failed metadata scan must fail the helper' >&2
    exit 1
fi
echo 'PASS: healthy pipx environments upgrade while corrupt metadata is isolated.'
