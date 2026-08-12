#!/usr/bin/env bash
set -uo pipefail

remote_target="${1:-}"

audit_body='
printf "# T3 audit\n"
date -Is
printf "\n## Host\n"
hostname
printf "\n## Binaries\n"
printf "t3="
command -v t3 || echo unavailable
printf "node="
command -v node >/dev/null 2>&1 && node --version || echo unavailable
printf "npx="
command -v npx >/dev/null 2>&1 && npx --version || echo unavailable
if command -v t3 >/dev/null 2>&1; then
  printf "t3_version="
  t3 --version 2>/dev/null || true
fi
printf "\n## Global packages\n"
npm list -g --depth=0 2>/dev/null | grep -E "t3@|@openai/codex|claude-code|gemini-cli" || true
printf "\n## User linger\n"
loginctl show-user "$(id -un)" -p Linger -p State -p RuntimePath -p Service 2>/dev/null || true
printf "\n## User units\n"
systemctl --user list-unit-files --no-pager --plain 2>/dev/null | grep -Ei "t3|code|codex|agent" || true
printf "\n## T3 unit state\n"
systemctl --user show t3-code-headless.service --no-pager -p Id -p LoadState -p ActiveState -p SubState -p UnitFileState -p FragmentPath -p ExecStart -p WorkingDirectory -p MainPID -p Restart -p RestartUSec 2>/dev/null || true
printf "\n## T3 unit file\n"
systemctl --user cat t3-code-headless.service --no-pager 2>/dev/null || true
printf "\n## Related T3 units\n"
systemctl --user show t3-code-headless-update.path t3-code-headless-restart.service t3code-hyperion.service --no-pager -p Id -p LoadState -p ActiveState -p SubState -p UnitFileState -p FragmentPath -p ExecStart -p Unit 2>/dev/null || true
printf "\n## T3 files\n"
find ~/.config/systemd/user ~/bin ~/.local/bin -maxdepth 3 \( -name "*t3*" -o -name "*T3*" \) -print 2>/dev/null || true
printf "\n## T3 listeners\n"
ss -ltnp 2>/dev/null | grep -E ":3773|:14773|:6733" || true
'

if [[ -n "$remote_target" ]]; then
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$remote_target" "bash -lc $(printf '%q' "$audit_body")"
else
  bash -lc "$audit_body"
fi
