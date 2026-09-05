#!/usr/bin/env bash
# Mock all updaters: this test must never install packages or contact providers.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
readlink() {
  case "${@: -1}" in
    codex) printf '/test/node/lib/node_modules/@openai/codex/bin/codex.js\n' ;;
    gemini) printf '/test/node/lib/node_modules/@google/gemini-cli/dist/index.js\n' ;;
    claude) printf '%s/.local/share/claude/versions/test\n' "$HOME" ;;
    opencode) printf '%s/.opencode/bin/opencode\n' "$HOME" ;;
    *) return 1 ;;
  esac
}
pacman() { return 1; }
npm() { printf 'MOCK npm %s\n' "$*"; }
codex() { :; }
gemini() { :; }
claude() { printf 'MOCK claude %s\n' "$*"; }
opencode() { printf 'MOCK opencode %s\n' "$*"; }
cursor-agent() { echo 'MOCK cursor update'; return "${CURSOR_FAILURE:-0}"; }
grok() {
  [[ "$SHELL" == /bin/false && "$PATH" == *":$HOME/.grok/bin" ]]
  printf 'MOCK grok %s\n' "$*"
}
export -f readlink pacman npm codex gemini claude opencode cursor-agent grok
output="$(bash "$repo/home/.local/bin/update-ai-clis")"
[[ "$output" == *'--prefix /test/node --allow-scripts=@openai/codex @openai/codex@latest'* ]]
[[ "$output" == *'--allow-scripts=@google/gemini-cli,@github/keytar,node-pty'* ]]
[[ "$output" == *'MOCK claude update'* && "$output" == *'MOCK opencode upgrade --method curl'* ]]
[[ "$output" != *'npm uninstall'* && "$output" != *'@anthropic-ai/claude-code@latest'* ]]
if output="$(CURSOR_FAILURE=1 bash "$repo/home/.local/bin/update-ai-clis" 2>&1)"; then
  echo 'Expected failed Cursor update to return nonzero.' >&2
  exit 1
fi
[[ "$output" == *'MOCK grok update'* ]]
echo 'PASS: package ownership, native routing, Gemini builds, Grok isolation, failure propagation.'
