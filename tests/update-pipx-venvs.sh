#!/usr/bin/env bash
# Exercise a healthy and a corrupt pipx environment without contacting PyPI.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/pipx/venvs/gns3-gui" "$tmp/pipx/venvs/platformio"

cat > "$tmp/bin/pipx" <<'EOF'
#!/usr/bin/env bash
printf 'MOCK pipx %s\n' "$*"
EOF
chmod +x "$tmp/bin/pipx"
cat > "$tmp/pipx/venvs/gns3-gui/pipx_metadata.json" <<'EOF'
{"main_package":{"package_or_url":"gns3-gui==3.0.6"}}
EOF
: > "$tmp/pipx/venvs/platformio/pipx_metadata.json"

output="$(PATH="$tmp/bin:$PATH" PIPX_HOME="$tmp/pipx" bash "$repo/home/.local/bin/update-pipx-venvs" 2>&1)"
[[ "$output" == *'MOCK pipx upgrade gns3-gui'* ]]
[[ "$output" == *'skipped corrupt environment: platformio'* ]]
[[ "$output" == *'pipx install platformio'* ]]
[[ "$output" != *'MOCK pipx upgrade platformio'* ]]
echo 'PASS: healthy pipx environments upgrade while corrupt metadata is isolated.'