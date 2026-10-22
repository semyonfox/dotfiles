#!/usr/bin/env bash
# Mock all updaters: this test must never install packages or contact providers.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export HOME="$fixture/home"
mkdir -p "$HOME/.local/bin" "$HOME/.local/lib/node_modules/t3/bin"
export PATH="$HOME/.local/bin:$PATH"
cat > "$HOME/.local/lib/node_modules/t3/bin/t3.js" <<'EOF'
#!/bin/sh
if [ "$1" = --version ]; then
  printf 't3 v%s\n' "${T3_TEST_VERSION:-0.0.46-nightly.20261015.3176}"
else
  printf 'MOCK t3 %s\n' "$*"
  [ "$1" = update ] && [ "$#" -eq 1 ]
fi
EOF
chmod +x "$HOME/.local/lib/node_modules/t3/bin/t3.js"
ln -s ../lib/node_modules/t3/bin/t3.js "$HOME/.local/bin/t3"
readlink() {
  case "${@: -1}" in
    codex) printf '/test/node/lib/node_modules/@openai/codex/bin/codex.js\n' ;;
    gemini) printf '/test/node/lib/node_modules/@google/gemini-cli/dist/index.js\n' ;;
    claude) printf '%s/.local/share/claude/versions/test\n' "$HOME" ;;
    opencode) printf '%s/.opencode/bin/opencode\n' "$HOME" ;;
    *) command readlink "$@" ;;
  esac
}
pacman() { return 1; }
npm() {
  printf 'MOCK npm %s\n' "$*"
  [[ ${T3_TEST_FAIL:-0} != 1 || $* != *'t3@'* ]]
}
codex() { :; }
gemini() { :; }
claude() { printf 'MOCK claude %s\n' "$*"; }
opencode() { printf 'MOCK opencode %s\n' "$*"; }
cursor-agent() { echo 'MOCK cursor update'; return "${CURSOR_FAILURE:-0}"; }
hermes() { printf 'MOCK hermes %s\n' "$*"; }
grok() {
  [[ "$SHELL" == /bin/false && "$PATH" == *":$HOME/.grok/bin" ]]
  printf 'MOCK grok %s\n' "$*"
}
export -f readlink pacman npm codex gemini claude opencode cursor-agent hermes grok
output="$(bash "$repo/home/.local/bin/update-ai-clis")"
[[ "$output" == *'--prefix /test/node --allow-scripts=@openai/codex @openai/codex@latest'* ]]
[[ "$output" == *'--allow-scripts=@google/gemini-cli,@github/keytar,node-pty'* ]]
[[ "$output" == *'MOCK claude update'* && "$output" == *'MOCK opencode upgrade --method curl'* ]]
[[ "$output" == *'MOCK hermes --profile default update --branch main'* ]]
[[ "$output" != *'npm uninstall'* && "$output" != *'@anthropic-ai/claude-code@latest'* ]]
if output="$(CURSOR_FAILURE=1 bash "$repo/home/.local/bin/update-ai-clis" 2>&1)"; then
  echo 'Expected failed Cursor update to return nonzero.' >&2
  exit 1
fi
[[ "$output" == *'MOCK grok update'* ]]
echo 'PASS: package ownership, native routing, Gemini builds, Grok isolation, failure propagation.'

[[ "$output" == *"--prefix $HOME/.local --allow-scripts=t3 t3@nightly"* ]]
echo 'PASS: npm T3 uses original prefix and nightly channel'
output=$(T3_TEST_VERSION=0.1.0 bash "$repo/home/.local/bin/update-ai-clis")
[[ "$output" == *'--allow-scripts=t3 t3@latest'* && "$output" != *'MOCK t3 update'* ]]
echo 'PASS: stable npm T3 stays stable and does not call native updater'
if output=$(T3_TEST_FAIL=1 bash "$repo/home/.local/bin/update-ai-clis" 2>&1); then exit 1; fi
[[ "$output" == *'T3 update incomplete'* && "$output" == *'MOCK hermes'* ]]
echo 'PASS: T3 failure propagates without stopping other updaters'
output=$(bash "$repo/home/.local/bin/update-ai-clis" --t3-dry-run)
[[ "$output" == *'t3@nightly'* && "$output" != *'MOCK '* ]]
echo 'PASS: dry-run invokes no mutating updater'
if output=$(T3_TEST_VERSION=0.1.1-preview.123 bash "$repo/home/.local/bin/update-ai-clis" --t3-dry-run 2>&1); then exit 1; fi
[[ "$output" == *'Unrecognised/prerelease'* ]]
echo 'PASS: preview installs are not silently moved to another train'
mkdir -p "$HOME/.config/systemd/user"
printf '# custom fixture\n' > "$HOME/.config/systemd/user/t3-code-headless.service"
if output=$(bash "$repo/home/.local/bin/update-ai-clis" 2>&1); then exit 1; fi
[[ "$output" == *'pinned runtime is NOT updated here'* && "$output" == *'MOCK hermes'* ]]
echo 'PASS: custom service cannot be reported as successfully updated'
rm "$HOME/.config/systemd/user/t3-code-headless.service"
mkdir -p "$HOME/.t3/runtime/versions/test"
cp "$HOME/.local/lib/node_modules/t3/bin/t3.js" "$HOME/.t3/runtime/versions/test/t3"
rm "$HOME/.local/bin/t3"
ln -s "$HOME/.t3/runtime/versions/test/t3" "$HOME/.local/bin/t3"
output=$(bash "$repo/home/.local/bin/update-ai-clis")
[[ "$output" == *'MOCK t3 update'* && "$output" != *'--allow-scripts=t3'* ]]
echo 'PASS: runtime-owned launcher uses native updater with no --yes'
rm "$HOME/.local/bin/t3"
cp "$HOME/.t3/runtime/versions/test/t3" "$HOME/.local/bin/t3"
if output=$(bash "$repo/home/.local/bin/update-ai-clis" --t3-dry-run 2>&1); then exit 1; fi
[[ "$output" == *'Unknown T3 installation owner'* ]]
echo 'PASS: unknown installation owner is left unchanged'
